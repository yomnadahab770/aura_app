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

    // [FIX] هنا صلحنا الـ Deprecated Math للألوان باستخدام الممارسات الحديثة لـ Flutter 3.11+
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

    // [FIX] تعديل قراءة الألوان بطريقة الـ getters الحديثة لتجنب تحذير دقة الألوان
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);

    await prefs.setInt('accentRed', r);
    await prefs.setInt('accentGreen', g);
    await prefs.setInt('accentBlue', b);
  }

  void _updateTheme(ThemeMode mode, Color color) {
    setState(() {
      _themeMode = mode;
      _primaryColor = color;
    });
    _saveThemePreferences(mode, color);
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
        // useMaterial3 مفضلة داخل الـ CopyWith للنسخ الحديثة
      ),

      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: _themeMode,
      // [FIX] تم تمرير الـ Parameter الناقص والـ الـ Error هيختفي تماماً
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
                    // [FIX] استبدال withOpacity بـ Color.withValues لمنعPrecision Loss
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.08),
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
