import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<Map<String, dynamic>> alerts = [];
  late DatabaseReference _alertsRef;
  final int _appStartTime = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _alertsRef = FirebaseDatabase.instance.ref('aura/alerts');
    _alertsRef.onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final type = data['type'] ?? 'Unknown';
      final time = data['timestamp'] ?? '--:--';
      final details = data['details'] != null
          ? Map<String, dynamic>.from(data['details'] as Map)
          : <String, dynamic>{};

      // بعرض بس الـ alerts اللي جت بعد ما الـ app اتفتح
      final serverTime = event.snapshot.key ?? '';
      final pushTime = _getPushTimestamp(serverTime);
      if (pushTime != null && pushTime < _appStartTime) return;

      final alertInfo = _buildAlertInfo(type, details);

      if (mounted) {
        setState(() {
          alerts.insert(0, {
            'type': alertInfo['title'],
            'location': alertInfo['subtitle'],
            'severity': alertInfo['severity'],
            'time': time,
            'icon': alertInfo['icon'],
            'color': alertInfo['color'],
          });
        });
      }
    });
  }

  // Firebase push keys فيها timestamp مضمّن
  int? _getPushTimestamp(String pushKey) {
    try {
      const chars =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_';
      int timestamp = 0;
      for (int i = 0; i < 8; i++) {
        timestamp = timestamp * 64 + chars.indexOf(pushKey[i]);
      }
      return timestamp;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _buildAlertInfo(
    String type,
    Map<String, dynamic> details,
  ) {
    switch (type) {
      // --- Fire Feature Alerts ---
      case 'CLOSE_GAS':
        return {
          'title': 'Child Near Stove',
          'subtitle': 'Kitchen • ${details['dist'] ?? 'N/A'}m away',
          'severity': 'Critical',
          'icon': Icons.gas_meter_outlined,
          'color': Colors.orangeAccent,
        };
      case 'DISTRACT_CHILD':
        return {
          'title': 'Child Near Fire',
          'subtitle': 'Kitchen • ${details['dist'] ?? 'N/A'}m away',
          'severity': 'High',
          'icon': Icons.local_fire_department,
          'color': Colors.redAccent,
        };

      // --- Full Detection Alerts ---
      case 'FALL_DETECTED':
        final prob = details['probability'] ?? 0.0;
        final pid = details['person_id'] ?? '';
        return {
          'title': 'Fall Detected',
          'subtitle':
              'Person $pid • Confidence ${(prob * 100).toStringAsFixed(0)}%',
          'severity': 'Critical',
          'icon': Icons.accessibility_new,
          'color': Colors.redAccent,
        };
      case 'CHEST_CLUTCH':
        final duration = details['duration_sec'] ?? 0;
        final pid = details['person_id'] ?? '';
        return {
          'title': 'Hand on Chest',
          'subtitle': 'Person $pid • ${duration}s detected',
          'severity': 'High',
          'icon': Icons.favorite_outlined,
          'color': Colors.pinkAccent,
        };
      case 'PAIN_DETECTED':
        final score = details['pain_score'] ?? 0.0;
        final pid = details['person_id'] ?? '';
        return {
          'title': 'Pain Detected',
          'subtitle': 'Person $pid • Score $score',
          'severity': 'Medium',
          'icon': Icons.sentiment_very_dissatisfied,
          'color': Colors.deepOrangeAccent,
        };

      default:
        return {
          'title': 'Unknown Alert',
          'subtitle': type,
          'severity': 'Info',
          'icon': Icons.warning_amber_outlined,
          'color': Colors.grey,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () => setState(() => alerts.clear()),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Alerts',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final color = alert['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          alert['icon'] as IconData,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['type'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    alert['location'] as String,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alert['time'] as String,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alert['severity'] as String,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
