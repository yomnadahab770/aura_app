# ------------------- NumPy 2.0 compatibility -------------------
import numpy as np
if not hasattr(np, 'complex_'):
    np.complex_ = np.complex128
if not hasattr(np, 'complex'):
    np.complex = np.complex128

# ------------------- Imports -------------------
import cv2
import time
import winsound
import threading
import os
from collections import deque
from datetime import datetime
from tensorflow.keras.models import load_model, model_from_json
import tensorflow as tf
import firebase_admin
from firebase_admin import credentials, db

# ------------------- MediaPipe (compatible with 0.10.30) -------------------
from mediapipe.python.solutions import face_mesh as _mp_face_mesh
from mediapipe.python.solutions import pose as _mp_pose
from mediapipe.python.solutions import hands as _mp_hands

# ------------------- Firebase Setup -------------------
FIREBASE_CRED_PATH = "aura-smart-home-1216d-firebase-adminsdk-fbsvc-ddf6393d47.json"
FIREBASE_DB_URL = "https://aura-smart-home-1216d-default-rtdb.firebaseio.com"

try:
    cred = credentials.Certificate(FIREBASE_CRED_PATH)
    firebase_admin.initialize_app(cred, {'databaseURL': FIREBASE_DB_URL})
    print("[INFO] Firebase connected.")
except Exception as e:
    print(f"[ERROR] Firebase init failed: {e}")

# ------------------- Firebase Alert Function -------------------
def send_firebase_alert(alert_type, details):
    try:
        ref = db.reference('aura/alerts')
        ref.push({
            'type': alert_type,
            'details': details,
            'timestamp': datetime.now().strftime('%H:%M:%S')
        })
        print(f"[FIREBASE] Alert sent: {alert_type}")
    except Exception as e:
        print(f"[FIREBASE ERROR] {e}")

# ------------------- تحميل نموذج كشف السقوط (TFLite) -------------------
FALL_TFLITE_PATH = "fall_detection_transformer.tflite"
TIMESTEPS = 60
FEATURES = 51   # 17 keypoints * (x, y, confidence)

fall_interpreter = None
try:
    if os.path.exists(FALL_TFLITE_PATH):
        fall_interpreter = tf.lite.Interpreter(model_path=FALL_TFLITE_PATH)
        fall_interpreter.allocate_tensors()
        print("[INFO] Fall detection TFLite model loaded.")
    else:
        print(f"[WARNING] {FALL_TFLITE_PATH} not found. Fall detection disabled.")
except Exception as e:
    print(f"[ERROR] Failed to load fall model: {e}")

# ------------------- MediaPipe models -------------------
mp_face_mesh = _mp_face_mesh.FaceMesh(
    static_image_mode=False, max_num_faces=3, refine_landmarks=True,
    min_detection_confidence=0.5, min_tracking_confidence=0.5
)
mp_pose = _mp_pose.Pose(
    static_image_mode=False,
    min_detection_confidence=0.5, min_tracking_confidence=0.5
)
mp_hands = _mp_hands.Hands(
    static_image_mode=False, max_num_hands=4,
    min_detection_confidence=0.5, min_tracking_confidence=0.5
)

# For landmark enums
PoseLandmark = _mp_pose.PoseLandmark
HandLandmark = _mp_hands.HandLandmark

# ------------------- Emotion model -------------------
try:
    with open('fer.json', 'r') as json_file:
        loaded_model_json = json_file.read()
    emotion_model = model_from_json(loaded_model_json)
    emotion_model.load_weights("fer.h5")
    print("[INFO] Loaded emotion model from fer.json/fer.h5")
except Exception as e:
    print(f"[ERROR] Could not load emotion model: {e}")
    print("Trying fallback fer2013_mini_XCEPTION.119-0.65.hdf5")
    emotion_model = load_model("fer2013_mini_XCEPTION.119-0.65.hdf5", compile=False)

emotion_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']
face_detector = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

# ------------------- Pain Detection Cooldown -------------------
pain_last_sent = {}  # person_id -> timestamp
PAIN_COOLDOWN = 30   # seconds

# ------------------- Keypoint definitions for fall detection -------------------
KEYPOINT_NAMES = [
    'Nose', 'Left Eye', 'Right Eye', 'Left Ear', 'Right Ear',
    'Left Shoulder', 'Right Shoulder', 'Left Elbow', 'Right Elbow',
    'Left Wrist', 'Right Wrist', 'Left Hip', 'Right Hip',
    'Left Knee', 'Right Knee', 'Left Ankle', 'Right Ankle'
]
NUM_KEYPOINTS = len(KEYPOINT_NAMES)

def extract_pose_keypoints(pose_landmarks, img_shape):
    flat = np.zeros(NUM_KEYPOINTS * 3, dtype=np.float32)
    if pose_landmarks is None:
        return flat
    mapping = {
        'Nose': PoseLandmark.NOSE,
        'Left Eye': PoseLandmark.LEFT_EYE,
        'Right Eye': PoseLandmark.RIGHT_EYE,
        'Left Ear': PoseLandmark.LEFT_EAR,
        'Right Ear': PoseLandmark.RIGHT_EAR,
        'Left Shoulder': PoseLandmark.LEFT_SHOULDER,
        'Right Shoulder': PoseLandmark.RIGHT_SHOULDER,
        'Left Elbow': PoseLandmark.LEFT_ELBOW,
        'Right Elbow': PoseLandmark.RIGHT_ELBOW,
        'Left Wrist': PoseLandmark.LEFT_WRIST,
        'Right Wrist': PoseLandmark.RIGHT_WRIST,
        'Left Hip': PoseLandmark.LEFT_HIP,
        'Right Hip': PoseLandmark.RIGHT_HIP,
        'Left Knee': PoseLandmark.LEFT_KNEE,
        'Right Knee': PoseLandmark.RIGHT_KNEE,
        'Left Ankle': PoseLandmark.LEFT_ANKLE,
        'Right Ankle': PoseLandmark.RIGHT_ANKLE,
    }
    for idx, name in enumerate(KEYPOINT_NAMES):
        try:
            lm = pose_landmarks[mapping[name]]
            flat[idx*3] = lm.x
            flat[idx*3+1] = lm.y
            flat[idx*3+2] = lm.visibility
        except:
            continue
    return flat

def normalize_skeleton_frame(frame_data, min_confidence=0.3):
    norm = np.copy(frame_data)
    lh_idx = KEYPOINT_NAMES.index('Left Hip')
    rh_idx = KEYPOINT_NAMES.index('Right Hip')
    ls_idx = KEYPOINT_NAMES.index('Left Shoulder')
    rs_idx = KEYPOINT_NAMES.index('Right Shoulder')

    def get_point(idx):
        return frame_data[idx*3], frame_data[idx*3+1], frame_data[idx*3+2]

    lh_x, lh_y, lh_c = get_point(lh_idx)
    rh_x, rh_y, rh_c = get_point(rh_idx)
    ls_x, ls_y, ls_c = get_point(ls_idx)
    rs_x, rs_y, rs_c = get_point(rs_idx)

    valid_lh = lh_c > min_confidence
    valid_rh = rh_c > min_confidence
    if valid_lh and valid_rh:
        mid_hip_x, mid_hip_y = (lh_x+rh_x)/2, (lh_y+rh_y)/2
    elif valid_lh:
        mid_hip_x, mid_hip_y = lh_x, lh_y
    elif valid_rh:
        mid_hip_x, mid_hip_y = rh_x, rh_y
    else:
        return norm

    valid_ls = ls_c > min_confidence
    valid_rs = rs_c > min_confidence
    if valid_ls and valid_rs:
        mid_shoulder_y = (ls_y+rs_y)/2
    elif valid_ls:
        mid_shoulder_y = ls_y
    elif valid_rs:
        mid_shoulder_y = rs_y
    else:
        mid_shoulder_y = np.nan

    ref_height = np.abs(mid_shoulder_y - mid_hip_y) if not np.isnan(mid_shoulder_y) else np.nan
    scale = not (np.isnan(ref_height) or ref_height < 1e-5)

    for kp in range(NUM_KEYPOINTS):
        x_idx, y_idx = kp*3, kp*3+1
        norm[x_idx] -= mid_hip_x
        norm[y_idx] -= mid_hip_y
        if scale:
            norm[x_idx] /= ref_height
            norm[y_idx] /= ref_height
    return norm

# ------------------- Person Tracker Class -------------------
class PersonTracker:
    def __init__(self, person_id, bbox):
        self.id = person_id
        self.bbox = bbox
        self.emotion_history = deque(maxlen=15)
        self.eye_pain_history = deque(maxlen=15)
        self.keypoints_buffer = deque(maxlen=TIMESTEPS)
        self.fall_alert_sent = False
        self.chest_clutch_start_time = None
        self.chest_alert_sent = False

    def update_bbox(self, bbox):
        self.bbox = bbox

    def get_center(self):
        x, y, w, h = self.bbox
        return (x + w//2, y + h//2)

# ------------------- Main setup -------------------
cap = cv2.VideoCapture(0)
print("[INFO] AURA System Started - Multi-Person Fall + Emotion + Chest monitoring")
print("Press ESC to exit")

active_persons = {}
next_person_id = 0

recording = False
out_video = None
record_start_time = None
RECORD_DURATION = 5

def start_recording(frame, prefix="event"):
    global recording, out_video, record_start_time
    if not recording:
        video_path = f"{prefix}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.avi"
        fourcc = cv2.VideoWriter_fourcc(*'MJPG')
        out_video = cv2.VideoWriter(video_path, fourcc, 20.0, (frame.shape[1], frame.shape[0]))
        recording = True
        record_start_time = time.time()
        print(f"[RECORDING] Started: {video_path}")

def iou(bbox1, bbox2):
    x1, y1, w1, h1 = bbox1
    x2, y2, w2, h2 = bbox2
    xi1 = max(x1, x2)
    yi1 = max(y1, y2)
    xi2 = min(x1+w1, x2+w2)
    yi2 = min(y1+h1, y2+h2)
    inter = max(0, xi2-xi1) * max(0, yi2-yi1)
    area1 = w1*h1
    area2 = w2*h2
    union = area1 + area2 - inter
    return inter / union if union > 0 else 0

# ------------------- Main loop -------------------
while True:
    ret, frame = cap.read()
    if not ret:
        break

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results_mesh = mp_face_mesh.process(rgb)
    results_pose = mp_pose.process(rgb)
    results_hands = mp_hands.process(rgb)

    current_time = time.time()

    # Step 1: Detect faces
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(60,60))

    matched_ids = set()
    for (x, y, w, h) in faces:
        bbox = (x, y, w, h)
        best_iou = 0.3
        best_id = None
        for pid, person in active_persons.items():
            iou_val = iou(person.bbox, bbox)
            if iou_val > best_iou:
                best_iou = iou_val
                best_id = pid
        if best_id is not None:
            active_persons[best_id].update_bbox(bbox)
            matched_ids.add(best_id)
        else:
            active_persons[next_person_id] = PersonTracker(next_person_id, bbox)
            matched_ids.add(next_person_id)
            next_person_id += 1

    for pid in list(active_persons.keys()):
        if pid not in matched_ids:
            del active_persons[pid]

    # Step 2: Emotion & eye pain
    face_landmarks_map = {}
    if results_mesh.multi_face_landmarks:
        for face_lms in results_mesh.multi_face_landmarks:
            nose = face_lms.landmark[1]
            nx, ny = int(nose.x * frame.shape[1]), int(nose.y * frame.shape[0])
            min_dist = float('inf')
            closest_bbox = None
            for (x, y, w, h) in faces:
                cx = x + w//2
                cy = y + h//2
                dist = (cx - nx)**2 + (cy - ny)**2
                if dist < min_dist:
                    min_dist = dist
                    closest_bbox = (x, y, w, h)
            if closest_bbox:
                face_landmarks_map[closest_bbox] = face_lms

    for pid, person in active_persons.items():
        x, y, w, h = person.bbox
        roi_gray = gray[y:y+h, x:x+w]
        if roi_gray.size == 0:
            continue
        roi_gray = cv2.resize(roi_gray, (48,48)).astype("float32") / 255.0
        roi_gray = np.expand_dims(np.expand_dims(roi_gray, axis=0), axis=-1)
        preds = emotion_model.predict(roi_gray, verbose=0)[0]
        emotion_idx = np.argmax(preds)
        conf = preds[emotion_idx]
        if conf < 0.25:
            emotion = "Neutral"
            emotion_idx = emotion_labels.index("Neutral")
        else:
            emotion = emotion_labels[emotion_idx]
        person.emotion_history.append(emotion)
        final_emo = max(set(person.emotion_history), key=person.emotion_history.count) if person.emotion_history else "Neutral"

        eye_pain_score = 0.0
        face_lms = face_landmarks_map.get(person.bbox)
        if face_lms:
            left_h = face_lms.landmark[159].y - face_lms.landmark[145].y
            right_h = face_lms.landmark[386].y - face_lms.landmark[374].y
            avg_h = (left_h+right_h)/2
            if avg_h < 0.012: eye_pain_score = 10.0
            elif avg_h < 0.02: eye_pain_score = 7.0
            elif avg_h < 0.03: eye_pain_score = 4.0
            if final_emo == "Happy" and conf > 0.3:
                eye_pain_score *= 0.1
        person.eye_pain_history.append(eye_pain_score)
        smoothed_eye_pain = np.mean(person.eye_pain_history) if person.eye_pain_history else 0.0

        health_state = "NORMAL"
        color = (0,255,0)
        if smoothed_eye_pain > 6 and conf < 0.3:
            health_state = "POSSIBLE PAIN"
            color = (0,0,255)
            # Send PAIN_DETECTED alert with cooldown
            last_sent = pain_last_sent.get(pid, 0)
            if current_time - last_sent > PAIN_COOLDOWN:
                pain_last_sent[pid] = current_time
                threading.Thread(target=send_firebase_alert, args=(
                    'PAIN_DETECTED',
                    {'person_id': pid, 'pain_score': round(float(smoothed_eye_pain), 2)}
                )).start()

        cv2.rectangle(frame, (x,y), (x+w,y+h), color, 2)
        cv2.putText(frame, f"P{pid} Emo:{final_emo}({conf*100:.0f}%)", (x,y-45), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        cv2.putText(frame, f"State:{health_state}", (x,y-25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        cv2.putText(frame, f"Pain:{smoothed_eye_pain:.1f}", (x,y-5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

    # Step 3: Fall detection
    if fall_interpreter is not None and results_pose.pose_landmarks:
        kps = extract_pose_keypoints(results_pose.pose_landmarks, frame.shape)
        kps_norm = normalize_skeleton_frame(kps)
        lh_idx = KEYPOINT_NAMES.index('Left Hip')
        rh_idx = KEYPOINT_NAMES.index('Right Hip')
        lh_x, lh_y = kps[lh_idx*3], kps[lh_idx*3+1]
        rh_x, rh_y = kps[rh_idx*3], kps[rh_idx*3+1]
        hip_center = None
        if kps[lh_idx*3+2] > 0.3 or kps[rh_idx*3+2] > 0.3:
            hip_center = ((lh_x+rh_x)/2, (lh_y+rh_y)/2)
        if hip_center is not None:
            min_dist = float('inf')
            closest_pid = None
            for pid, person in active_persons.items():
                cx, cy = person.get_center()
                nx, ny = cx / frame.shape[1], cy / frame.shape[0]
                dist = (nx - hip_center[0])**2 + (ny - hip_center[1])**2
                if dist < min_dist:
                    min_dist = dist
                    closest_pid = pid
            if closest_pid is not None:
                person = active_persons[closest_pid]
                person.keypoints_buffer.append(kps_norm)
                if len(person.keypoints_buffer) == TIMESTEPS:
                    window = np.array(person.keypoints_buffer, dtype=np.float32).reshape(1, TIMESTEPS, FEATURES)
                    fall_interpreter.set_tensor(fall_interpreter.get_input_details()[0]['index'], window)
                    fall_interpreter.invoke()
                    prob = fall_interpreter.get_tensor(fall_interpreter.get_output_details()[0]['index'])[0][0]
                    cv2.putText(frame, f"Person {closest_pid} Fall Prob: {prob:.2f}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,255), 2)
                    if prob > 0.5 and not person.fall_alert_sent:
                        person.fall_alert_sent = True
                        threading.Thread(target=send_firebase_alert, args=(
                            'FALL_DETECTED',
                            {'person_id': closest_pid, 'probability': round(float(prob), 2)}
                        )).start()
                        start_recording(frame, f"fall_p{closest_pid}")
                else:
                    cv2.putText(frame, f"Person {closest_pid} fall init: {len(person.keypoints_buffer)}/{TIMESTEPS}", (10, 60),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200,200,200), 1)
    elif fall_interpreter is None:
        cv2.putText(frame, "Fall detection: OFF (model missing)", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,0,255), 2)

    # Step 4: Chest clutch detection
    current_best_person = None
    if results_hands.multi_hand_landmarks:
        for hand_lms in results_hands.multi_hand_landmarks:
            wrist = hand_lms.landmark[HandLandmark.WRIST]
            wx, wy = wrist.x, wrist.y
            best_person = None
            best_dist = float('inf')
            for pid, person in active_persons.items():
                x, y, w, h = person.bbox
                chest_x_center = (x + w//2) / frame.shape[1]
                chest_y_center = (y + h*0.7) / frame.shape[0]
                chest_width = (w / frame.shape[1]) * 0.8
                dx = abs(wx - chest_x_center)
                dy = abs(wy - chest_y_center)
                if dx < chest_width and dy < chest_width:
                    dist = dx*dx + dy*dy
                    if dist < best_dist:
                        best_dist = dist
                        best_person = person
            if best_person is not None:
                current_best_person = best_person
                if best_person.chest_clutch_start_time is None:
                    best_person.chest_clutch_start_time = current_time
                duration = current_time - best_person.chest_clutch_start_time
                cv2.putText(frame, f"P{best_person.id} Hand on chest: {duration:.1f}s", (10,90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,0,139), 2)
                if duration >= 5 and not best_person.chest_alert_sent:
                    best_person.chest_alert_sent = True
                    threading.Thread(target=send_firebase_alert, args=(
                        'CHEST_CLUTCH',
                        {'person_id': best_person.id, 'duration_sec': round(duration, 2)}
                    )).start()
                    start_recording(frame, f"chest_p{best_person.id}")

    # Reset chest timer for persons without hand on chest
    for person in active_persons.values():
        if current_best_person is None or person.id != current_best_person.id:
            if person.chest_clutch_start_time is not None:
                person.chest_clutch_start_time = None
                person.chest_alert_sent = False

    # Step 5: Recording management
    if recording and (current_time - record_start_time > RECORD_DURATION):
        recording = False
        if out_video:
            out_video.release()
            out_video = None
            print("[RECORDING] Stopped")
    if recording and out_video is not None:
        out_video.write(frame)

    cv2.imshow("AURA - Multi-Person Fall+Emotion+Chest Monitor", frame)
    if cv2.waitKey(1) & 0xFF == 27:
        break

# Cleanup
if out_video:
    out_video.release()
cap.release()
cv2.destroyAllWindows()
mp_face_mesh.close()
mp_pose.close()
mp_hands.close()
print("[INFO] System closed.")