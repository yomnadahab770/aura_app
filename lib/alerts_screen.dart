import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<Map<String, dynamic>> alerts = [
    {
      'type': 'Fire Detection',
      'location': 'Kitchen',
      'severity': 'High',
      'time': '10:32 AM',
      'icon': Icons.local_fire_department,
      'color': Colors.redAccent,
    },
    {
      'type': 'Gas Leakage',
      'location': 'Basement',
      'severity': 'Critical',
      'time': '09:15 AM',
      'icon': Icons.gas_meter_outlined,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _connectMqtt();
  }

  void _connectMqtt() {
    final mqtt = MqttService();
    mqtt.onAlertReceived = (data) {
      final type = data['type'] ?? 'Unknown';
      final time = data['timestamp'] ?? TimeOfDay.now().format(context);
      final dist = data['details']?['dist'] ?? 'N/A';

      setState(() {
        alerts.insert(0, {
          'type': type == 'CLOSE_GAS' ? 'Child Near Stove' : 'Child Near Fire',
          'location': 'Kitchen • ${dist}m away',
          'severity': type == 'CLOSE_GAS' ? 'Critical' : 'High',
          'time': time,
          'icon': type == 'CLOSE_GAS'
              ? Icons.gas_meter_outlined
              : Icons.local_fire_department,
          'color': type == 'CLOSE_GAS' ? Colors.orangeAccent : Colors.redAccent,
        });
      });
    };
    mqtt.connect();
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
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Text(
                '✅ No Alerts',
                style: TextStyle(color: Colors.white54, fontSize: 18),
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
                                  Icons.location_on,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alert['location'] as String,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
