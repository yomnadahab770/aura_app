import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  Entry Point
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AuraApp());
}

// ═══════════════════════════════════════════════════════════════
//  Root Widget — manages global theme + primary color
// ═══════════════════════════════════════════════════════════════
class AuraApp extends StatefulWidget {
  const AuraApp({super.key});

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = const Color(0xFF00D4FF);

  // Called by SplashScreen → LoginScreen → ThemeSelectionScreen
  void _updateTheme(ThemeMode mode, Color color) {
    setState(() {
      _themeMode = mode;
      _primaryColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA',
      debugShowCheckedModeBanner: false,

      // ── Light Theme ────────────────────────────────────────
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FA),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ── Dark Theme ─────────────────────────────────────────
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      themeMode: _themeMode,

      // ── Entry screen ───────────────────────────────────────
      home: SplashScreen(onThemeChanged: _updateTheme),

      // ── Max-width constraint (looks good on tablets/desktop) ──
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return MediaQuery(
          // Prevent font scaling from breaking layouts
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.55 : 0.08),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
