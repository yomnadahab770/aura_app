import 'package:flutter/material.dart';

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.25),
        radius: 1.1,
        colors: [const Color(0xFF0D1B3E), const Color(0xFF050D1F)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Blue glow behind the logo area
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF3B5BDB).withOpacity(0.18),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height * 0.35),
              width: size.width * 0.9,
              height: size.height * 0.55,
            ),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow);

    // Stars (x%, y%, radius)
    final stars = [
      [0.08, 0.04, 1.3],
      [0.82, 0.07, 1.0],
      [0.44, 0.02, 0.8],
      [0.18, 0.16, 1.5],
      [0.68, 0.11, 1.0],
      [0.91, 0.23, 0.7],
      [0.04, 0.33, 1.2],
      [0.54, 0.07, 0.9],
      [0.29, 0.27, 0.7],
      [0.78, 0.38, 1.4],
      [0.14, 0.53, 0.8],
      [0.63, 0.31, 1.0],
      [0.94, 0.52, 0.8],
      [0.38, 0.58, 0.9],
      [0.23, 0.70, 0.6],
      [0.73, 0.63, 1.2],
      [0.09, 0.79, 0.9],
      [0.87, 0.76, 1.0],
      [0.49, 0.86, 0.7],
      [0.33, 0.91, 0.8],
      [0.60, 0.18, 0.6],
      [0.96, 0.40, 0.9],
      [0.02, 0.60, 0.7],
      [0.76, 0.90, 0.8],
    ];

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      starPaint.color = Colors.white.withOpacity(0.2 + s[2] * 0.18);
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
