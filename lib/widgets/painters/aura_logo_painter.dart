import 'package:flutter/material.dart';

class AuraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = const Color(0xFF3B5BDB).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final h = size.height;

    // المثلث الخارجي
    final triangle = Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(triangle, fill);
    canvas.drawPath(triangle, stroke);

    // الـ chevron الداخلي (شكل V)
    final chevron = Path()
      ..moveTo(cx * 0.42, h * 0.64)
      ..lineTo(cx, h * 0.38)
      ..lineTo(cx * 1.58, h * 0.64);

    canvas.drawPath(chevron, stroke);

    // نقطة في القمة
    canvas.drawCircle(
      Offset(cx, h * 0.38),
      3,
      Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
