import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login/login_screen.dart';

void main() {
  runApp(const YamoreApp());
}

class YamoreApp extends StatelessWidget {
  const YamoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yamore',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
