import 'package:flutter/material.dart';
import '../home/main_screen.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final Function(ThemeMode, Color) onThemeChanged;
  const ThemeSelectionScreen({super.key, required this.onThemeChanged});
  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String selectedMode = "Dark";
  Color selectedColor = const Color(0xFF00D4FF);

  final List<Color> colors = [
    const Color(0xFF00D4FF),
    const Color(0xFF6E07F0),
    const Color(0xFFFF2D55),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = selectedMode == 'Dark';
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Customize AURA',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'Make it yours',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey : Colors.black45,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Theme Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _modeCard(
                    'Dark',
                    Icons.nightlight_round,
                    selectedMode == 'Dark',
                  ),
                  const SizedBox(width: 12),
                  _modeCard('Light', Icons.wb_sunny, selectedMode == 'Light'),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Accent Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: colors
                    .map(
                      (c) => GestureDetector(
                        onTap: () {
                          setState(() => selectedColor = c);
                          widget.onThemeChanged(
                            isDark ? ThemeMode.dark : ThemeMode.light,
                            c,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.transparent,
                              width: 4,
                            ),
                            boxShadow: selectedColor == c
                                ? [
                                    BoxShadow(
                                      color: c.withOpacity(0.6),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: selectedColor == c
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    widget.onThemeChanged(
                      isDark ? ThemeMode.dark : ThemeMode.light,
                      selectedColor,
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  child: const Text(
                    'Continue to Dashboard',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard(String title, IconData icon, bool selected) {
    final isCardDark = selectedMode == 'Dark';
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedMode = title);
          widget.onThemeChanged(
            title == 'Dark' ? ThemeMode.dark : ThemeMode.light,
            selectedColor,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withOpacity(0.15)
                : (isCardDark ? const Color(0xFF1F1F1F) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : (isCardDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: selected ? selectedColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected ? selectedColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
