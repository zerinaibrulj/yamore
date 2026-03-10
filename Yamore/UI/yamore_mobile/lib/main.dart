import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'dart:io' show Platform;
import 'package:window_size/window_size.dart' as window_size;
import 'screens/login/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Center the window and give it a reasonable default size on desktop.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.setWindowTitle('Yamore Admin');
    window_size.setWindowMinSize(const Size(1000, 700));
    window_size.setWindowMaxSize(const Size(1920, 1200));
    window_size.getScreenList().then((screens) {
      if (screens.isNotEmpty) {
        final screen = screens.first;
        final width = 1200.0;
        final height = 800.0;
        final left = screen.frame.left + (screen.frame.width - width) / 2;
        final top = screen.frame.top + (screen.frame.height - height) / 2;
        window_size.setWindowFrame(
          Rect.fromLTWH(left, top, width, height),
        );
      }
    });
  }

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
