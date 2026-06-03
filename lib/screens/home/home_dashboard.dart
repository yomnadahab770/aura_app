import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';

class HomeDashboard extends StatefulWidget {
  final Function(ThemeMode, Color) onThemeChanged;
  const HomeDashboard({super.key, required this.onThemeChanged});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  void _triggerEmergency(BuildContext context) async {
    try {
      await FirebaseDatabase.instance.ref('aura/emergency').set({
        'active': true,
        'triggeredBy': UserSession.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Emergency Mode Activated — Help is on the way!'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to trigger emergency. Check connection.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        // ✅ نقرأ القيم الحالية للثيم داخل الـ builder نفسه
        final currentBrightness = Theme.of(bc).brightness;
        final currentColor = Theme.of(bc).colorScheme.primary;
        String tempMode = currentBrightness == Brightness.dark
            ? 'Dark'
            : 'Light';
        Color tempColor = currentColor;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = tempMode == 'Dark';
            final List<Color> colors = [
              const Color(0xFF00D4FF),
              const Color(0xFF6E07F0),
              const Color(0xFFFF2D55),
              const Color(0xFF4CAF50),
              const Color(0xFFFF9800),
              const Color(0xFF9C27B0),
            ];

            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A0A0A)
                    : const Color(0xFFF5F7FA),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Customize AURA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Make it yours',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _modeCard(
                        'Dark',
                        Icons.nightlight_round,
                        tempMode == 'Dark',
                        isDark,
                        tempColor,
                        () => setSheetState(() => tempMode = 'Dark'),
                      ),
                      const SizedBox(width: 12),
                      _modeCard(
                        'Light',
                        Icons.wb_sunny,
                        tempMode == 'Light',
                        isDark,
                        tempColor,
                        () => setSheetState(() => tempMode = 'Light'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Accent Color',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: colors.map((c) {
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tempColor == c
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.transparent,
                              width: 4,
                            ),
                            boxShadow: tempColor == c
                                ? [
                                    BoxShadow(
                                      color: c.withOpacity(0.6),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: tempColor == c
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tempColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        widget.onThemeChanged(
                          tempMode == 'Dark' ? ThemeMode.dark : ThemeMode.light,
                          tempColor,
                        );
                        Navigator.pop(bc);
                      },
                      child: const Text(
                        'Apply Theme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modeCard(
    String title,
    IconData icon,
    bool selected,
    bool isDark,
    Color selectedColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withOpacity(0.15)
                : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: selected ? selectedColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected ? selectedColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white.withOpacity(0.95);

    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('aura/sensors').onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          Map<String, dynamic> sensors = {};
          if (snap.hasData && snap.data!.snapshot.value != null) {
            sensors = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map,
            );
          }
          final fire = sensors['fire'] is Map
              ? Map<String, dynamic>.from(sensors['fire'] as Map)
              : {};
          final gas = sensors['gas'] is Map
              ? Map<String, dynamic>.from(sensors['gas'] as Map)
              : {};
          final motion = sensors['motion'] is Map
              ? Map<String, dynamic>.from(sensors['motion'] as Map)
              : {};
          final fireWarning = fire['status']?.toString() == 'warning';
          final gasLeak = gas['status']?.toString() == 'leak';
          final motionDetected = motion['detected'] == true;
          final anyAlert = fireWarning || gasLeak || motionDetected;
          final alertCount =
              (fireWarning ? 1 : 0) +
              (gasLeak ? 1 : 0) +
              (motionDetected ? 1 : 0);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AURA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: isDark ? Colors.white : Colors.black87,
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: Colors.cyan.withOpacity(0.8),
                                  blurRadius: 15,
                                  offset: const Offset(0, 0),
                                ),
                              ]
                            : [],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.palette_outlined,
                            color: primaryColor,
                          ),
                          onPressed: _showThemeBottomSheet,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: primaryColor,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Overview',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All systems are monitoring',
                        style: TextStyle(fontSize: 14, color: subTextColor),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _statusCard(
                            title: 'Fall Detection',
                            status: motionDetected ? 'Alert' : 'Active',
                            subtitle: motionDetected
                                ? 'Motion detected'
                                : 'No issues',
                            icon: Icons.person,
                            color: motionDetected ? Colors.red : Colors.green,
                          ),
                          _statusCard(
                            title: 'Child Safety',
                            status: 'Monitoring',
                            subtitle: 'No issues',
                            icon: Icons.child_care,
                            color: Colors.blue,
                          ),
                          _statusCard(
                            title: 'Fire Detection',
                            status: fireWarning ? 'Warning' : 'Safe',
                            subtitle: fireWarning
                                ? 'Fire detected!'
                                : 'No fire detected',
                            icon: Icons.local_fire_department,
                            color: fireWarning ? Colors.red : Colors.orange,
                          ),
                          _statusCard(
                            title: 'Live Cameras',
                            status: '3 Cameras Active',
                            subtitle: 'View All',
                            icon: Icons.videocam,
                            color: primaryColor,
                            onTapSubtitle: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System Status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  anyAlert ? 'Issues Detected' : 'All Good',
                                  style: TextStyle(
                                    color: anyAlert ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: anyAlert ? Colors.red : Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                alertCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String status,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTapSubtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white.withOpacity(0.95);
    final titleColor = isDark ? Colors.white70 : Colors.black54;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return GestureDetector(
      onTap: onTapSubtitle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: color),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        status == 'Active' ||
                            status == 'Monitoring' ||
                            status == 'Safe'
                        ? Colors.green
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
          ],
        ),
      ),
    );
  }
}
