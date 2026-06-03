import 'package:flutter/material.dart';
import '../../core/user_session.dart';
import '../../widgets/painters/starfield_painter.dart';
import 'home_dashboard.dart';
import '../alerts/alerts_screen.dart';
import '../devices/devices_screen.dart';
import '../digital_twin/digital_twin_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(ThemeMode, Color) onThemeChanged;
  const MainScreen({super.key, required this.onThemeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeDashboard(onThemeChanged: widget.onThemeChanged),
      const AlertsScreen(),
      const DevicesScreen(),
      if (UserSession.role == "Admin") const DigitalTwinScreen(),
      const SettingsScreen(),
    ];
    _navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.notifications),
        label: 'Alerts',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.devices),
        label: 'Devices',
      ),
      if (UserSession.role == "Admin")
        const BottomNavigationBarItem(
          icon: Icon(Icons.view_in_ar),
          label: 'Twin',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _index.clamp(0, _screens.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // النجوم في الخلفية (فقط في الدارك مود)
        if (isDark)
          Positioned.fill(child: CustomPaint(painter: StarfieldPainter())),
        // الـ Scaffold شفاف حتى تظهر النجوم من خلفه
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _screens[safeIndex],
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              // [FIX] withOpacity -> withValues لتجنب الـ Warning
              unselectedItemColor: Colors.grey.withValues(alpha: 0.7),
              type: BottomNavigationBarType.fixed,
              items: _navItems,
            ),
          ),
        ),
      ],
    );
  }
}
