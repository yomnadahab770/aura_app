import cv2
import math
import time
import os
import threading
import queue
import logging
from datetime import datetime
from ultralytics import YOLO
import firebase_admin
from firebase_admin import credentials, db

CONFIG = {
    "fire_model": "best_fire.pt",
    "person_model": "best_person.pt",
    "fire_conf": 0.45,
    "person_conf": 0.60,
    "pixels_per_meter": 50,
    "danger_distance_m": 10.0,
    "warning_distance_m": 15.0,
    "alert_cooldown_s": 5,
    "frame_skip": 2,
    "device": "cpu",
    "firebase_cred": "aura-smart-home-1216d-firebase-adminsdk-fbsvc-ddf6393d47.json",
    "firebase_db_url": "https://aura-smart-home-1216d-default-rtdb.firebaseio.com",
    "max_alert_images": 30,
    "person_cache_timeout": 8,
}

DANGER_PX = int(CONFIG["danger_distance_m"] * CONFIG["pixels_per_meter"])
WARNING_PX = int(CONFIG["warning_distance_m"] * CONFIG["pixels_per_meter"])

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger("AURA")


class FirebaseManager:
    def __init__(self):
        self.connected = False
        self._queue = queue.Queue(maxsize=20)
        self._image_folder = "alerts"
        os.makedirs(self._image_folder, exist_ok=True)

        try:
            cred = credentials.Certificate(CONFIG["firebase_cred"])
            firebase_admin.initialize_app(cred, {
                'databaseURL': CONFIG["firebase_db_url"]
            })
            self.connected = True
            threading.Thread(target=self._sender_loop, daemon=True).start()
            logger.info("✅ Firebase Connected")
        except Exception as e:
            logger.error(f"⚠️ Firebase Connection Failed: {e}")

    def send(self, alert_type, details, frame=None):
        if not self.connected: return
        try:
            self._queue.put_nowait((alert_type, details, frame))
        except queue.Full:
            pass

    def _sender_loop(self):
        while True:
            alert_type, details, frame = self._queue.get()
            try:
                if frame is not None:
                    img_name = f"alert_{int(time.time())}.jpg"
                    img_path = os.path.join(self._image_folder, img_name)
                    cv2.imwrite(img_path, frame)
                    self._cleanup_old_images()

                payload = {
                    "type": alert_type,
                    "details": details,
                    "timestamp": datetime.now().strftime("%H:%M:%S"),
                }
                db.reference('aura/alerts').push(payload)
                logger.info(f"✅ Alert Sent to Firebase: {alert_type}")
            except Exception as e:
                logger.error(f"Failed to send alert: {e}")

    def _cleanup_old_images(self):
        images = sorted([
            os.path.join(self._image_folder, f)
            for f in os.listdir(self._image_folder)
        ], key=os.path.getctime)
        while len(images) > CONFIG["max_alert_images"]:
            try: os.remove(images.pop(0))
            except: pass


class AURAPipeline:
    def __init__(self):
        logger.info("⏳ Loading YOLO Models...")
        self.fire_model = YOLO(CONFIG["fire_model"])
        self.person_model = YOLO(CONFIG["person_model"])
        logger.info("✅ Models Loaded")

        self.mqtt = FirebaseManager()
        self.last_alert = 0
        self.frame_count = 0
        self._cached_fires = []
        self._cached_persons = []
        self._cached_oven = None
        self._no_person_frames = 0
        self._stove_defined = False

    def setup_stove_zone(self, frame, window_name="Setup: Draw Stove Zone"):
        roi = cv2.selectROI(window_name, frame, fromCenter=False, showCrosshair=True)
        cv2.destroyWindow(window_name)

        if roi[2] > 20 and roi[3] > 20:
            x1, y1, w, h = map(int, roi)
            self._cached_oven = (x1, y1, x1 + w, y1 + h)
            self._stove_defined = True
            logger.info("✅ Stove zone saved")
            return True
        return False

    def _is_child(self, box_width, box_height, adult_min_height=180):
        aspect_ratio = box_width / box_height if box_height > 0 else 0
        return box_height < adult_min_height or aspect_ratio > 0.45

    def _detect(self, frame):
        start_time = time.time()

        fire_res = self.fire_model.predict(
            frame, conf=CONFIG["fire_conf"], verbose=False, device=CONFIG["device"])
        fires = []
        for box in fire_res[0].boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            fires.append({"center": ((x1+x2)//2, (y1+y2)//2),
                          "bbox": (x1, y1, x2, y2), "conf": float(box.conf[0])})
        self._cached_fires = fires

        if fires:
            person_res = self.person_model.predict(
                frame, conf=CONFIG["person_conf"], verbose=False, device=CONFIG["device"])
            persons = []
            for box in person_res[0].boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                w, h = x2-x1, y2-y1
                persons.append({"center": ((x1+x2)//2, (y1+y2)//2),
                                 "bbox": (x1, y1, x2, y2),
                                 "is_child": self._is_child(w, h),
                                 "conf": float(box.conf[0])})
            self._cached_persons = persons
            self._no_person_frames = 0
        else:
            self._no_person_frames += 1
            if self._no_person_frames > CONFIG["person_cache_timeout"]:
                self._cached_persons = []

        print(f"Inference Time: {(time.time() - start_time) * 1000:.2f} ms")

    def _draw_and_decide(self, frame):
        if self._cached_oven:
            cv2.rectangle(frame, (self._cached_oven[0], self._cached_oven[1]),
                         (self._cached_oven[2], self._cached_oven[3]), (255, 100, 0), 2)

        for fire in self._cached_fires:
            x1, y1, x2, y2 = fire["bbox"]
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 2)

        for person in self._cached_persons:
            if not person["is_child"]:
                x1, y1, x2, y2 = person["bbox"]
                cv2.rectangle(frame, (x1, y1), (x2, y2), (180, 180, 180), 2)
                cv2.putText(frame, "Adult", (x1, y1-8), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (180, 180, 180), 1)
                continue

            px1, py1, px2, py2 = person["bbox"]
            p_center = person["center"]

            min_dist = float("inf")
            nearest_fire = None
            for fire in self._cached_fires:
                d = math.hypot(fire["center"][0] - p_center[0], fire["center"][1] - p_center[1])
                if d < min_dist:
                    min_dist = d
                    nearest_fire = fire

            if not nearest_fire: continue

            dist_m = round(min_dist / CONFIG["pixels_per_meter"], 2)

            color = (0, 0, 255)
            cv2.rectangle(frame, (px1, py1), (px2, py2), color, 3)
            cv2.line(frame, p_center, nearest_fire["center"], color, 2)
            cv2.putText(frame, f"CHILD - {dist_m}m", (px1, py1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)

            if (time.time() - self.last_alert) > CONFIG["alert_cooldown_s"]:
                fire_in_stove = False
                if self._cached_oven:
                    fx, fy = nearest_fire["center"]
                    ox1, oy1, ox2, oy2 = self._cached_oven
                    fire_in_stove = ox1 <= fx <= ox2 and oy1 <= fy <= oy2

                alert_type = "CLOSE_GAS" if fire_in_stove else "DISTRACT_CHILD"
                self.mqtt.send(alert_type, {"dist": dist_m}, frame.copy())
                self.last_alert = time.time()
                logger.info(f"🚨 Alert: {alert_type} | Distance: {dist_m}m")

    def run(self, video_source):
        cap = cv2.VideoCapture(video_source, cv2.CAP_DSHOW if video_source == 0 else 0)
        if not cap.isOpened():
            logger.error("❌ Failed to open video source!")
            return

        ret, first_frame = cap.read()
        if ret and not self._stove_defined:
            self.setup_stove_zone(first_frame)

        logger.info("🚀 AURA System Started | Press Q to quit | R to redefine stove zone")

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret: break

            self.frame_count += 1
            if self.frame_count % CONFIG["frame_skip"] == 0:
                self._detect(frame)

            self._draw_and_decide(frame)

            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'): break
            elif key == ord('r') or key == ord('R'):
                self.setup_stove_zone(frame, "Redefine Stove Zone")

            cv2.imshow("AURA Safety System V2", frame)

        cap.release()
        cv2.destroyAllWindows()
        logger.info("✅ AURA System Stopped.")


if __name__ == "__main__":
    print("=== AURA Safety System ===")
    choice = input("1: Live Camera | 2: Video File → ").strip()
    src = 0 if choice == "1" else input("Enter video path: ").strip("\"' ")
    pipeline = AURAPipeline()
    pipeline.run(src)