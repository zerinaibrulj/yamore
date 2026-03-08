import 'package:flutter/material.dart';

class AppTheme {
  static const Color navBackground = Color(0xFF1a237e);
  static const Color navBackgroundLight = Color(0xFF283593);
  static const Color contentBackground = Colors.white;
  static const Color primaryBlue = Color(0xFF1a237e);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: navBackground,
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
      ),
    );
  }
}
