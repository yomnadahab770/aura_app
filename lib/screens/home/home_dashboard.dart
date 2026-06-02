import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('aura/sensors').onValue,
      builder: (context, snap) {
        Map<String, dynamic> sensors = {};
        if (snap.hasData && snap.data!.snapshot.value != null) {
          sensors = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
        }

        final fire = sensors['fire'] is Map
            ? Map<String, dynamic>.from(sensors['fire'] as Map)
            : {};
        final gas = sensors['gas'] is Map
            ? Map<String, dynamic>.from(sensors['gas'] as Map)
            : {};
        final temp = sensors['temperature'] is Map
            ? Map<String, dynamic>.from(sensors['temperature'] as Map)
            : {};
        final motion = sensors['motion'] is Map
            ? Map<String, dynamic>.from(sensors['motion'] as Map)
            : {};

        final fireWarning = fire['status']?.toString() == 'warning';
        final gasLeak = gas['status']?.toString() == 'leak';
        final tempValue = (temp['value'] ?? 24.5).toDouble();
        final motionActive = motion['detected'] == true;
        final anyAlert = fireWarning || gasLeak;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.home_outlined, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'AURA',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: primaryColor,
                    ),
                    onPressed: () {},
                  ),
                  if (anyAlert)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () => _triggerEmergency(context),
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UserSession.role == "Admin"
                            ? 'Good Morning, ${UserSession.name} 👋'
                            : 'Welcome ${UserSession.name} 👋',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        anyAlert
                            ? '⚠️ Warning Detected!'
                            : '✅ All Systems Safe',
                        style: TextStyle(
                          fontSize: 15,
                          color: anyAlert ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: anyAlert
                              ? Colors.red.withOpacity(0.15)
                              : (isDark
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: anyAlert ? Colors.red : Colors.green,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              anyAlert ? Icons.warning : Icons.shield,
                              color: anyAlert ? Colors.red : Colors.green,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              anyAlert ? 'TAKE ACTION NOW' : 'HOME IS SECURE',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: anyAlert ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Monitoring',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Live',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _card(
                            'Fire',
                            fireWarning ? 'Warning!' : 'Normal',
                            Icons.local_fire_department,
                            fireWarning ? Colors.red : Colors.orange,
                            isDark,
                          ),
                          _card(
                            'Gas',
                            gasLeak ? 'LEAK!' : 'Safe',
                            Icons.gas_meter_outlined,
                            gasLeak ? Colors.red : Colors.blueAccent,
                            isDark,
                          ),
                          _card(
                            'Temp',
                            '${tempValue.toStringAsFixed(1)}°C',
                            Icons.thermostat,
                            primaryColor,
                            isDark,
                          ),
                          _card(
                            'Motion',
                            motionActive ? 'Detected!' : 'No Activity',
                            Icons.directions_walk,
                            motionActive ? Colors.red : Colors.purpleAccent,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: color),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
