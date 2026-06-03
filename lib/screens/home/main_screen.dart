import 'package:flutter/material.dart';
import '../../core/user_session.dart';
import 'home_dashboard.dart';
import '../alerts/alerts_screen.dart';
import '../devices/devices_screen.dart';
import '../digital_twin/digital_twin_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(ThemeMode, Color) onThemeChanged; // <- استقبال الدالة
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
      HomeDashboard(onThemeChanged: widget.onThemeChanged), // <- تمرير الدالة
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeIndex = _index.clamp(0, _screens.length - 1);
    return Scaffold(
      body: _screens[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
