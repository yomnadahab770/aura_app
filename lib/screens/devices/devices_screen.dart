import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white.withValues(
            alpha: 0.95,
          ); // [FIX] withOpacity -> withValues

    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('aura/users/${UserSession.uid}/rooms')
            .onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return _hardcodedFallback(
              isDark,
              textColor,
              subTextColor,
              cardColor,
            );
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
              return _deviceCard(
                name: name,
                location: devices,
                status: 'Online',
                color: Colors.green,
                icon: icon,
                isDark: isDark,
                textColor: textColor,
                subTextColor: subTextColor,
                cardColor: cardColor,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _hardcodedFallback(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color cardColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _deviceCard(
          name: 'Fire Detector',
          location: 'Kitchen',
          status: 'Online',
          color: Colors.green,
          icon: Icons.local_fire_department,
          isDark: isDark,
          textColor: textColor,
          subTextColor: subTextColor,
          cardColor: cardColor,
        ),
        _deviceCard(
          name: 'Gas Sensor',
          location: 'Living Room',
          status: 'Online',
          color: Colors.green,
          icon: Icons.gas_meter_outlined,
          isDark: isDark,
          textColor: textColor,
          subTextColor: subTextColor,
          cardColor: cardColor,
        ),
        _deviceCard(
          name: 'Temperature Sensor',
          location: 'Bedroom',
          status: 'Online',
          color: Colors.green,
          icon: Icons.thermostat,
          isDark: isDark,
          textColor: textColor,
          subTextColor: subTextColor,
          cardColor: cardColor,
        ),
        _deviceCard(
          name: 'Motion Sensor',
          location: 'Entrance',
          status: 'Online',
          color: Colors.green,
          icon: Icons.directions_walk,
          isDark: isDark,
          textColor: textColor,
          subTextColor: subTextColor,
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _deviceCard({
    required String name,
    required String location,
    required String status,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)), // [FIX]
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), // [FIX]
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), // [FIX]
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
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(color: subTextColor, fontSize: 13),
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
