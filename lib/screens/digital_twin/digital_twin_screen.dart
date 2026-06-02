import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';

// ═══════════════════════════════════════════════════════════════
//  DigitalTwinScreen — 2D Floor Plan + Live Sensor Overlay
//  Admin only — يتحكم فيها من MainScreen
// ═══════════════════════════════════════════════════════════════

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with TickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  late AnimationController _scanCtrl;
  late Animation<double> _scan;

  // ── State ─────────────────────────────────────────────────
  Map<String, dynamic> _sensors = {};
  String? _selectedRoom;

  // ── Room Definitions (normalized 0.0–1.0 fractions) ───────
  static const List<_RoomDef> _rooms = [
    _RoomDef(
      id: 'kitchen',
      name: 'Kitchen',
      icon: Icons.kitchen,
      l: 0.04,
      t: 0.04,
      w: 0.44,
      h: 0.36,
    ),
    _RoomDef(
      id: 'living',
      name: 'Living Room',
      icon: Icons.weekend,
      l: 0.52,
      t: 0.04,
      w: 0.44,
      h: 0.36,
    ),
    _RoomDef(
      id: 'bedroom1',
      name: 'Bedroom 1',
      icon: Icons.bed,
      l: 0.04,
      t: 0.48,
      w: 0.28,
      h: 0.34,
    ),
    _RoomDef(
      id: 'bedroom2',
      name: 'Bedroom 2',
      icon: Icons.bed,
      l: 0.36,
      t: 0.48,
      w: 0.28,
      h: 0.34,
    ),
    _RoomDef(
      id: 'bathroom',
      name: 'Bathroom',
      icon: Icons.bathtub_outlined,
      l: 0.68,
      t: 0.48,
      w: 0.28,
      h: 0.16,
    ),
    _RoomDef(
      id: 'entrance',
      name: 'Entrance',
      icon: Icons.door_front_door_outlined,
      l: 0.68,
      t: 0.68,
      w: 0.28,
      h: 0.14,
    ),
  ];

  // ── Sensor info per room ───────────────────────────────────
  static const Map<String, String> _roomSensors = {
    'kitchen': 'Fire Detector · Gas Sensor · Camera',
    'living': 'Motion Sensor · Camera · AC Control',
    'bedroom1': 'Temp Sensor · Eye-Tracking · Camera',
    'bedroom2': 'Temp Sensor · AC Control',
    'bathroom': 'Humidity Sensor · Motion Sensor',
    'entrance': 'Motion Sensor · Door Camera',
  };

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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

  // ── Build sensor status map from Firebase data ─────────────
  Map<String, _RoomStatus> _buildRoomStatus(
    bool fireAlert,
    bool gasAlert,
    double tempVal,
    bool motionActive,
    bool fallDetected,
    Color primary,
  ) {
    return {
      'kitchen': _RoomStatus(
        hasAlert: fireAlert || gasAlert,
        color: fireAlert
            ? Colors.red
            : gasAlert
            ? Colors.orange
            : Colors.green,
        label: fireAlert
            ? '🔥 Fire!'
            : gasAlert
            ? '⚠️ Gas Leak'
            : '✅ Safe',
      ),
      'living': _RoomStatus(
        hasAlert: motionActive,
        color: motionActive ? Colors.blue : Colors.green,
        label: motionActive ? '🚶 Motion' : '✅ Clear',
      ),
      'bedroom1': _RoomStatus(
        hasAlert: fallDetected || tempVal > 28,
        color: fallDetected
            ? Colors.red
            : tempVal > 28
            ? Colors.orange
            : primary,
        label: fallDetected ? '🚨 Fall!' : '${tempVal.toStringAsFixed(1)}°C',
      ),
      'bedroom2': _RoomStatus(
        hasAlert: false,
        color: Colors.green,
        label: '✅ Safe',
      ),
      'bathroom': _RoomStatus(
        hasAlert: false,
        color: Colors.green,
        label: '✅ Safe',
      ),
      'entrance': _RoomStatus(
        hasAlert: false,
        color: Colors.green,
        label: '✅ Clear',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.view_in_ar, color: primary, size: 22),
            const SizedBox(width: 8),
            const Text('Digital Twin'),
          ],
        ),
        actions: [
          // Live badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(_pulse.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(_pulse.value * 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Live',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('aura/sensors').onValue,
        builder: (context, snap) {
          // ── Parse Firebase data ──────────────────────────
          if (snap.hasData && snap.data!.snapshot.value != null) {
            _sensors = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map,
            );
          }

          final fire = _sensors['fire'] is Map
              ? Map<String, dynamic>.from(_sensors['fire'] as Map)
              : <String, dynamic>{};
          final gas = _sensors['gas'] is Map
              ? Map<String, dynamic>.from(_sensors['gas'] as Map)
              : <String, dynamic>{};
          final temp = _sensors['temperature'] is Map
              ? Map<String, dynamic>.from(_sensors['temperature'] as Map)
              : <String, dynamic>{};
          final motion = _sensors['motion'] is Map
              ? Map<String, dynamic>.from(_sensors['motion'] as Map)
              : <String, dynamic>{};
          final safety = _sensors['safety'] is Map
              ? Map<String, dynamic>.from(_sensors['safety'] as Map)
              : <String, dynamic>{};

          final fireAlert = fire['status']?.toString() == 'warning';
          final gasAlert = gas['status']?.toString() == 'leak';
          final tempVal = (temp['value'] ?? 24.0).toDouble();
          final motionActive = motion['detected'] == true;
          final fallDetected = safety['fall_detected'] == true;
          final anyAlert = fireAlert || gasAlert || fallDetected;

          final roomStatus = _buildRoomStatus(
            fireAlert,
            gasAlert,
            tempVal,
            motionActive,
            fallDetected,
            primary,
          );

          return Column(
            children: [
              // ── Alert Banner ────────────────────────────
              if (anyAlert)
                _buildAlertBanner(fireAlert, gasAlert, fallDetected),

              // ── Floor Plan ──────────────────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.06),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;

                          return Stack(
                            children: [
                              // Grid background
                              CustomPaint(
                                size: Size(w, h),
                                painter: _FloorPlanPainter(
                                  isDark: isDark,
                                  primaryColor: primary,
                                ),
                              ),

                              // Scan line animation
                              AnimatedBuilder(
                                animation: _scan,
                                builder: (_, __) => Positioned(
                                  top: _scan.value * h,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          primary.withOpacity(0.25),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Rooms
                              ..._rooms.map((room) {
                                final status = roomStatus[room.id]!;
                                final isSelected = _selectedRoom == room.id;

                                return Positioned(
                                  left: room.l * w,
                                  top: room.t * h,
                                  width: room.w * w,
                                  height: room.h * h,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedRoom = isSelected
                                          ? null
                                          : room.id,
                                    ),
                                    child: _RoomTile(
                                      room: room,
                                      status: status,
                                      isSelected: isSelected,
                                      isDark: isDark,
                                      pulse: _pulse,
                                      width: room.w * w,
                                    ),
                                  ),
                                );
                              }),

                              // House name label
                              Positioned(
                                bottom: 8,
                                right: 14,
                                child: Text(
                                  '${UserSession.houseName} — Floor 1',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withOpacity(0.2),
                                  ),
                                ),
                              ),

                              // Compass
                              Positioned(
                                top: 10,
                                right: 14,
                                child: _CompassWidget(isDark: isDark),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom Section ───────────────────────────
              if (_selectedRoom != null)
                _buildRoomDetail(
                  _rooms.firstWhere((r) => r.id == _selectedRoom),
                  roomStatus[_selectedRoom!]!,
                  isDark,
                  primary,
                )
              else
                _buildSensorStrip(
                  isDark,
                  primary,
                  fireAlert,
                  gasAlert,
                  tempVal,
                  motionActive,
                  fallDetected,
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Alert Banner ──────────────────────────────────────────
  Widget _buildAlertBanner(bool fire, bool gas, bool fall) {
    final String msg = fire
        ? '🔥 Fire Warning in Kitchen — Take Action!'
        : gas
        ? '⚠️ Gas Leak Detected in Kitchen!'
        : '🚨 Fall Detected — Checking for response...';

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: double.infinity,
        color: Colors.red.withOpacity(0.12 + _pulse.value * 0.06),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red.withOpacity(0.7 + _pulse.value * 0.3),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sensor Strip ──────────────────────────────────────────
  Widget _buildSensorStrip(
    bool isDark,
    Color primary,
    bool fire,
    bool gas,
    double temp,
    bool motion,
    bool fall,
  ) {
    return SizedBox(
      height: 108,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Row(
          children: [
            _SensorCard(
              label: 'Fire',
              value: fire ? 'Warning!' : 'Safe',
              icon: Icons.local_fire_department,
              color: fire ? Colors.red : Colors.orange,
              isDark: isDark,
              hasAlert: fire,
              pulse: _pulse,
            ),
            const SizedBox(width: 8),
            _SensorCard(
              label: 'Gas',
              value: gas ? 'Leak!' : 'Safe',
              icon: Icons.gas_meter_outlined,
              color: gas ? Colors.red : Colors.blueAccent,
              isDark: isDark,
              hasAlert: gas,
              pulse: _pulse,
            ),
            const SizedBox(width: 8),
            _SensorCard(
              label: 'Temp',
              value: '${temp.toStringAsFixed(1)}°C',
              icon: Icons.thermostat,
              color: temp > 28 ? Colors.orange : primary,
              isDark: isDark,
              hasAlert: temp > 28,
              pulse: _pulse,
            ),
            const SizedBox(width: 8),
            _SensorCard(
              label: 'Safety',
              value: fall
                  ? 'Fall!'
                  : motion
                  ? 'Motion'
                  : 'Clear',
              icon: fall
                  ? Icons.personal_injury_outlined
                  : Icons.directions_walk,
              color: fall
                  ? Colors.red
                  : motion
                  ? Colors.blue
                  : Colors.green,
              isDark: isDark,
              hasAlert: fall,
              pulse: _pulse,
            ),
          ],
        ),
      ),
    );
  }

  // ── Room Detail Panel ─────────────────────────────────────
  Widget _buildRoomDetail(
    _RoomDef room,
    _RoomStatus status,
    bool isDark,
    Color primary,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: status.color.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(room.icon, color: status.color, size: 26),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _roomSensors[room.id] ?? 'Sensors active',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Alert indicator
                    if (status.hasAlert)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(
                              0.08 + _pulse.value * 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(_pulse.value),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Alert Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _selectedRoom = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Room Tile Widget
// ═══════════════════════════════════════════════════════════════
class _RoomTile extends StatelessWidget {
  final _RoomDef room;
  final _RoomStatus status;
  final bool isSelected;
  final bool isDark;
  final Animation<double> pulse;
  final double width;

  const _RoomTile({
    required this.room,
    required this.status,
    required this.isSelected,
    required this.isDark,
    required this.pulse,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = width > 100 ? 22.0 : 16.0;
    final fontSize = width > 100 ? 9.5 : 8.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected
            ? status.color.withOpacity(0.2)
            : status.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? status.color : status.color.withOpacity(0.35),
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: status.color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(room.icon, color: status.color, size: iconSize),
          const SizedBox(height: 3),
          Text(
            room.name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Status dot
          if (status.hasAlert)
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: status.color.withOpacity(pulse.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: status.color.withOpacity(pulse.value * 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Sensor Card Widget
// ═══════════════════════════════════════════════════════════════
class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool hasAlert;
  final Animation<double> pulse;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.hasAlert,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasAlert
                  ? color.withOpacity(0.4 + pulse.value * 0.3)
                  : color.withOpacity(0.25),
              width: hasAlert ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Compass Widget
// ═══════════════════════════════════════════════════════════════
class _CompassWidget extends StatelessWidget {
  final bool isDark;
  const _CompassWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = (isDark ? Colors.white : Colors.black).withOpacity(0.2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'N',
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Icon(Icons.arrow_upward, size: 10, color: color),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Floor Plan Painter — grid + outer walls + corridor dividers
// ═══════════════════════════════════════════════════════════════
class _FloorPlanPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  const _FloorPlanPainter({required this.isDark, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? Colors.white : Colors.black;

    // ── Background ──────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = isDark ? const Color(0xFF111827) : const Color(0xFFF0F4FF),
    );

    // ── Grid ────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = base.withOpacity(0.04)
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Primary color accent glow (corner) ──────────────────
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [primaryColor.withOpacity(0.07), Colors.transparent],
            radius: 0.8,
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.1, size.height * 0.1),
              radius: size.width * 0.6,
            ),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // ── Outer walls ─────────────────────────────────────────
    final wallPaint = Paint()
      ..color = base.withOpacity(0.2)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
        const Radius.circular(14),
      ),
      wallPaint,
    );

    // ── Corridor dividers ────────────────────────────────────
    final divPaint = Paint()
      ..color = base.withOpacity(0.1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Horizontal divider (between top & bottom rooms)
    canvas.drawLine(
      Offset(6, size.height * 0.455),
      Offset(size.width - 6, size.height * 0.455),
      divPaint,
    );

    // Vertical divider (right section — bathroom/entrance split)
    canvas.drawLine(
      Offset(size.width * 0.666, size.height * 0.455),
      Offset(size.width * 0.666, size.height - 6),
      divPaint,
    );

    // Vertical divider (middle of bottom-left rooms)
    canvas.drawLine(
      Offset(size.width * 0.335, size.height * 0.455),
      Offset(size.width * 0.335, size.height - 6),
      divPaint,
    );

    // Horizontal divider (bathroom / entrance)
    canvas.drawLine(
      Offset(size.width * 0.666, size.height * 0.665),
      Offset(size.width - 6, size.height * 0.665),
      divPaint,
    );

    // ── Door indicators (small arcs) ─────────────────────────
    _drawDoor(canvas, size, 0.04, 0.455, 0.08, base.withOpacity(0.18));
    _drawDoor(canvas, size, 0.52, 0.455, 0.08, base.withOpacity(0.18));
  }

  void _drawDoor(
    Canvas canvas,
    Size size,
    double xFrac,
    double yFrac,
    double lengthFrac,
    Color color,
  ) {
    final x = xFrac * size.width;
    final y = yFrac * size.height;
    final len = lengthFrac * size.width;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(x, y - len, len, len);
    canvas.drawArc(rect, 0, 1.5708, false, paint); // quarter circle
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter old) =>
      old.isDark != isDark || old.primaryColor != primaryColor;
}

// ═══════════════════════════════════════════════════════════════
//  Data Classes
// ═══════════════════════════════════════════════════════════════

/// Room definition with normalized position (0.0–1.0)
class _RoomDef {
  final String id;
  final String name;
  final IconData icon;
  final double l; // left
  final double t; // top
  final double w; // width
  final double h; // height

  const _RoomDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.l,
    required this.t,
    required this.w,
    required this.h,
  });
}

/// Runtime status for a room derived from sensor data
class _RoomStatus {
  final bool hasAlert;
  final Color color;
  final String label;

  const _RoomStatus({
    required this.hasAlert,
    required this.color,
    required this.label,
  });
}
