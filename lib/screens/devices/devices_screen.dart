import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Devices & Sensors')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('aura/users/${UserSession.uid}/rooms')
            .onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return _hardcodedFallback(isDark);
          }
          final roomsRaw = Map<String, dynamic>.from(
            snap.data!.snapshot.value as Map,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: roomsRaw.entries.map((entry) {
              final room = Map<String, dynamic>.from(entry.value as Map);
              final name = room['name']?.toString() ?? 'Room';
              final type = room['type']?.toString() ?? '';
              final devices = room['devices']?.toString() ?? '';
              final icon = type == 'Kitchen'
                  ? Icons.kitchen
                  : type == 'Bedroom'
                  ? Icons.bed
                  : type == 'Living Room'
                  ? Icons.weekend
                  : Icons.roofing;
              return _device(
                name,
                devices,
                'Online',
                Colors.green,
                icon,
                isDark,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _hardcodedFallback(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _device(
          'Fire Detector',
          'Kitchen',
          'Online',
          Colors.green,
          Icons.local_fire_department,
          isDark,
        ),
        _device(
          'Gas Sensor',
          'Living Room',
          'Online',
          Colors.green,
          Icons.gas_meter_outlined,
          isDark,
        ),
        _device(
          'Temperature Sensor',
          'Bedroom',
          'Online',
          Colors.green,
          Icons.thermostat,
          isDark,
        ),
        _device(
          'Motion Sensor',
          'Entrance',
          'Online',
          Colors.green,
          Icons.directions_walk,
          isDark,
        ),
      ],
    );
  }

  Widget _device(
    String name,
    String loc,
    String status,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  loc,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.circle, color: color, size: 10),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
