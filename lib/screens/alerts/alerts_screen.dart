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
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _alertsRef = FirebaseDatabase.instance.ref('aura/alerts');
    _alertsRef.onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final type = data['type']?.toString() ?? 'Unknown';
      final time = data['timestamp']?.toString() ?? '--:--';
      final details = data['details'] != null
          ? Map<String, dynamic>.from(data['details'] as Map)
          : <String, dynamic>{};

      final pushKey = event.snapshot.key ?? '';
      final pushTime = _getPushTimestamp(pushKey);
      if (pushTime != null && pushTime < _appStartTime) return;

      final alertInfo = _buildAlertInfo(type, details);

      if (mounted) {
        setState(() {
          alerts.insert(0, {
            'title': alertInfo['title'],
            'subtitle': alertInfo['subtitle'],
            'severity': alertInfo['severity'],
            'time': time,
            'icon': alertInfo['icon'],
            'color': alertInfo['color'],
            'badge': alertInfo['badge'],
          });
        });
      }
    });
  }

  int? _getPushTimestamp(String pushKey) {
    if (pushKey.length < 8) return null;
    try {
      const chars =
          '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
      int timestamp = 0;
      for (int i = 0; i < 8; i++) {
        final charIndex = chars.indexOf(pushKey[i]);
        if (charIndex == -1) return null;
        timestamp = timestamp * 64 + charIndex;
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
      case 'DISTRACT_CHILD':
        return {
          'title': 'Child Near Flame',
          'subtitle':
              'Kitchen • ${details['dist']?.toString() ?? 'N/A'}m from stove',
          'severity': 'Critical',
          'icon': Icons.local_fire_department,
          'color': Colors.redAccent,
          'badge': 'LIVE',
        };
      case 'CLOSE_GAS':
        return {
          'title': 'Child Near Gas',
          'subtitle': 'Kitchen • ${details['dist']?.toString() ?? 'N/A'}m away',
          'severity': 'Critical',
          'icon': Icons.gas_meter_outlined,
          'color': Colors.orangeAccent,
          'badge': 'LIVE',
        };
      case 'PAIN_DETECTED':
        return {
          'title': 'Pain Detected',
          'subtitle':
              'Person ${details['person_id'] ?? '?'} • Pain score: ${details['pain_score'] ?? '0'}/10',
          'severity': 'High',
          'icon': Icons.sentiment_very_dissatisfied,
          'color': Colors.deepOrangeAccent,
          'badge': 'VIEW',
        };
      case 'CHEST_CLUTCH':
        return {
          'title': 'Hand on Chest',
          'subtitle':
              'Person ${details['person_id'] ?? '?'} • ${details['duration_sec'] ?? '0'}s detected',
          'severity': 'High',
          'icon': Icons.favorite_outlined,
          'color': Colors.pinkAccent,
          'badge': 'VIEW',
        };
      case 'CHEST_PAIN':
        return {
          'title': 'Chest Pain Alert',
          'subtitle':
              'Person ${details['pid'] ?? '?'} • Immediate attention needed',
          'severity': 'Critical',
          'icon': Icons.monitor_heart_outlined,
          'color': Colors.redAccent,
          'badge': 'LIVE',
        };
      case 'FALL_DETECTED':
        final prob = details['probability'] ?? 0.0;
        final pct = ((prob is num ? prob.toDouble() : 0.0) * 100)
            .toStringAsFixed(0);
        return {
          'title': 'Fall Detected',
          'subtitle':
              'Person ${details['person_id'] ?? '?'} • Confidence $pct%',
          'severity': 'Critical',
          'icon': Icons.accessibility_new,
          'color': Colors.redAccent,
          'badge': 'LIVE',
        };
      default:
        return {
          'title': 'Unknown Alert',
          'subtitle': 'Type: $type',
          'severity': 'Info',
          'icon': Icons.warning_amber_outlined,
          'color': Colors.grey,
          'badge': 'VIEW',
        };
    }
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    if (_filter == 'All') return alerts;
    if (_filter == 'Critical') {
      return alerts.where((a) => a['severity'] == 'Critical').toList();
    }
    if (_filter == 'Warnings') {
      return alerts.where((a) => a['severity'] != 'Critical').toList();
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white.withValues(alpha: 0.95); // [FIX]

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                if (alerts.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: subTextColor),
                    onPressed: () async {
                      // 1. مسح التنبيهات من الفايربيز من جذورها
                      await FirebaseDatabase.instance
                          .ref('aura/alerts')
                          .remove();

                      // 2. مسح التنبيهات من واجهة الشاشة محلياً في نفس اللحظة
                      setState(() => alerts.clear());

                      // 3. إظهار رسالة تأكيد خضراء بنجاح العملية
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'All alerts have been successfully cleared!',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Clear all',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip(
                  'All',
                  _filter == 'All',
                  primaryColor,
                  () => setState(() => _filter = 'All'),
                  isDark,
                ),
                const SizedBox(width: 12),
                _filterChip(
                  'Critical',
                  _filter == 'Critical',
                  Colors.redAccent,
                  () => setState(() => _filter = 'Critical'),
                  isDark,
                ),
                const SizedBox(width: 12),
                _filterChip(
                  'Warnings',
                  _filter == 'Warnings',
                  Colors.orangeAccent,
                  () => setState(() => _filter = 'Warnings'),
                  isDark,
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredAlerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          // [FIX] added const
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Alerts',
                          style: TextStyle(color: subTextColor, fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'All systems running normally',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _filteredAlerts[index];
                      final color = alert['color'] as Color;
                      final badge = alert['badge'] ?? 'VIEW';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4), // [FIX]
                            width: 1.5,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.05,
                                    ), // [FIX]
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(
                                      alpha: 0.15,
                                    ), // [FIX]
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert['title'] as String,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        alert['subtitle'] as String,
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badge == 'LIVE'
                                        ? Colors.redAccent.withValues(
                                            alpha: 0.2,
                                          ) // [FIX]
                                        : primaryColor.withValues(
                                            alpha: 0.2,
                                          ), // [FIX]
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      color: badge == 'LIVE'
                                          ? Colors.redAccent
                                          : primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: subTextColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      alert['time'] as String,
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (badge == 'LIVE')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.15,
                                      ), // [FIX]
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    Color accentColor,
    VoidCallback onTap,
    bool isDark,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: accentColor.withValues(alpha: 0.2), // [FIX]
      checkmarkColor: accentColor,
      labelStyle: TextStyle(
        color: selected
            ? accentColor
            : (isDark ? Colors.white70 : Colors.black54),
      ),
      side: BorderSide(
        color: selected
            ? accentColor
            : (isDark ? Colors.white30 : Colors.black26),
      ),
    );
  }
}
