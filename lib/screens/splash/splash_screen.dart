import 'package:flutter/material.dart';
import '../../widgets/painters/starfield_painter.dart';
import '../../widgets/painters/glow_logo.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(ThemeMode, Color) onThemeChanged;
  const SplashScreen({super.key, required this.onThemeChanged});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(onThemeChanged: widget.onThemeChanged),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1F),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final percent = (_progress.value * 100).toInt();
          return Stack(
            children: [
              // ── خلفية النجوم ──────────────────────────
              Positioned.fill(child: CustomPaint(painter: StarfieldPainter())),

              // ── المحتوى ──────────────────────────────
              FadeTransition(
                opacity: _fade,
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // ── Logo ────────────────────────
                        const GlowLogo(),

                        const SizedBox(height: 36),

                        // ── AURA ────────────────────────
                        const Text(
                          'AURA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 14,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Subtitle ────────────────────
                        Text(
                          'AI SAFETY MONITORING SYSTEM',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10.5,
                            letterSpacing: 3.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Taglines ────────────────────
                        Text(
                          'Smart Monitoring.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 15,
                            height: 1.9,
                          ),
                        ),
                        Text(
                          'Real-time Protection.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 15,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // ── Progress Section ────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 52),
                          child: Column(
                            children: [
                              Text(
                                'Initializing system...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 11.5,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Progress bar
                              Stack(
                                children: [
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: _progress.value,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00D4FF),
                                            Color(0xFF0088FF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00D4FF,
                                            ).withOpacity(0.6),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Text(
                                '$percent%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
