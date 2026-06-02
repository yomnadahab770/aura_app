import 'package:flutter/material.dart';
import 'aura_logo_painter.dart';

class GlowLogo extends StatelessWidget {
  const GlowLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.25),
            blurRadius: 50,
            spreadRadius: 15,
          ),
          BoxShadow(
            color: const Color(0xFF3B5BDB).withOpacity(0.35),
            blurRadius: 80,
            spreadRadius: 25,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(60, 60),
          painter: AuraLogoPainter(),
        ),
      ),
    );
  }
}
