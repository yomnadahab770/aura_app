import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../core/user_session.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});
  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _scanCtrl;
  late Animation<double> _scan;

  _Room3D? _selectedRoom;
  Map<String, dynamic> _sensors = {};

  // القائمة المحدثة بالملفات الـ 3D الجديدة
  // القائمة المحدثة بالروابط المضغوطة الجديدة
  static const List<_Room3D> _rooms = [
    _Room3D(
      id: 'bedroom1',
      name: 'Primary Bedroom',
      icon: Icons.bed,
      x: -1.5,
      z: -1.5,
      w: 2.8,
      d: 3.2,
      h: 2.5,
      col: Colors.indigo,
      // الرابط الجديد للملف المضغوط (6.6MB)
      modelPath:
          'https://raw.githubusercontent.com/yomnadahab770/aura_3d_assets/main/badroom.glb',
    ),
    _Room3D(
      id: 'bedroom2',
      name: 'Guest Bedroom',
      icon: Icons.bed_outlined,
      x: 1.5,
      z: -1.5,
      w: 2.8,
      d: 3.2,
      h: 2.5,
      col: Colors.teal,
      // تأكدي أن بسنت ضغطت هذا الملف أيضاً وارفعيه بنفس الطريقة
      modelPath:
          'https://raw.githubusercontent.com/yomnadahab770/aura_3d_assets/main/badroom1.glb',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _scan = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('aura/sensors').onValue,
        builder: (context, snap) {
          if (snap.hasData && snap.data!.snapshot.value != null) {
            _sensors = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map,
            );
          }

          return Stack(
            children: [
              // عرض الغرفة الـ 3D عند اختيارها
              if (_selectedRoom != null)
                _build3DViewer(_selectedRoom!, isDark)
              else
                _buildPlaceholder(isDark),

              // لوحة التحكم العلوية
              _buildTopBar(primary, isDark),

              // قائمة الغرف الجانبية
              _buildRoomSelector(primary, isDark),

              // ملخص الحساسات السفلي
              if (_selectedRoom != null)
                _buildSensorOverlay(_selectedRoom!, primary, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _build3DViewer(_Room3D room, bool isDark) {
    return ModelViewer(
      key: ValueKey(room.id),
      src: room.modelPath,
      alt: "A 3D model of ${room.name}",
      autoRotate: true,
      cameraControls: true,
      backgroundColor: isDark ? const Color(0xFF050505) : Colors.grey[100]!,
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_in_ar,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            "Select a room to view Digital Twin",
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color primary, bool isDark) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // يوزع العناصر للأطراف
        children: [
          // الـ Expanded هيضمن إن النص "يصغر" غصب عنه لو مفيش مساحة
          Expanded(
            child: Text(
              "AURA TWIN",
              style: TextStyle(
                fontSize: 16, // قللي الحجم لـ 16 للتأمين
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1, // يمنع النزول لسطر جديد
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // لو مفيش غرفة مختارة، الـ Spacer والزرار مش هيضيقوا النص
          if (_selectedRoom != null) ...[
            const SizedBox(width: 10), // مسافة بسيطة بين النص والزرار
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedRoom = null),
              color: isDark ? Colors.white : Colors.black,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomSelector(Color primary, bool isDark) {
    return Positioned(
      left: 20,
      top: 100,
      bottom: 100,
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(35),
        ),
        child: ListView.builder(
          itemCount: _rooms.length,
          itemBuilder: (context, i) {
            final room = _rooms[i];
            final sel = _selectedRoom?.id == room.id;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: IconButton(
                icon: Icon(room.icon),
                color: sel ? primary : Colors.grey,
                onPressed: () => setState(() => _selectedRoom = room),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSensorOverlay(_Room3D room, Color primary, bool isDark) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1A1A1A) : Colors.white).withValues(
            alpha: 0.9,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _sensorInfo(
              "Temp",
              "${_sensors['temperature']?['value'] ?? '--'}°C",
              Icons.thermostat,
            ),
            _sensorInfo(
              "Motion",
              _sensors['motion']?['detected'] == true ? "Yes" : "No",
              Icons.directions_walk,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorInfo(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Room3D {
  final String id, name;
  final IconData icon;
  final double x, z, w, d, h;
  final Color col;
  final String modelPath;
  const _Room3D({
    required this.id,
    required this.name,
    required this.icon,
    required this.x,
    required this.z,
    required this.w,
    required this.d,
    required this.h,
    required this.col,
    required this.modelPath,
  });
}
