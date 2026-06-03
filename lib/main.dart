import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AuraApp());
}

class AuraApp extends StatefulWidget {
  const AuraApp({super.key});

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = const Color(0xFF00D4FF);

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    final red = prefs.getInt('accentRed') ?? 0x00;
    final green = prefs.getInt('accentGreen') ?? 0xD4;
    final blue = prefs.getInt('accentBlue') ?? 0xFF;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _primaryColor = Color.fromARGB(255, red, green, blue);
    });
  }

  Future<void> _saveThemePreferences(ThemeMode mode, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', mode == ThemeMode.dark);
    await prefs.setInt('accentRed', color.red);
    await prefs.setInt('accentGreen', color.green);
    await prefs.setInt('accentBlue', color.blue);
  }

  void _updateTheme(ThemeMode mode, Color color) {
    setState(() {
      _themeMode = mode;
      _primaryColor = color;
    });
    _saveThemePreferences(mode, color);
    // طباعة للتأكد إن الدالة اشتغلت (في الـ debug console)
    print('Theme changed to: ${mode == ThemeMode.dark ? "Dark" : "Light"}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA',
      debugShowCheckedModeBanner: false,

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
      home: SplashScreen(onThemeChanged: _updateTheme),

      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return MediaQuery(
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
