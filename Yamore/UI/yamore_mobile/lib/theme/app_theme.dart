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
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navBackground,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: Colors.white.withOpacity(0.18),
        indicatorShape: const StadiumBorder(),
      ),
    );
  }
}
