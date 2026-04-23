import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart' as window_size;

import 'screens/login/login_screen.dart';
import 'services/app_navigator.dart';
import 'services/deep_link_coordinator.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Center the window and give it a reasonable default size on desktop.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.setWindowTitle('Yamore Admin');
    window_size.setWindowMinSize(const Size(1100, 750));
    window_size.setWindowMaxSize(const Size(1930, 1080));
    window_size.getScreenList().then((screens) {
      if (screens.isNotEmpty) {
        final screen = screens.first;
        const width = 1420.0;
        const height = 900.0;
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

class YamoreApp extends StatefulWidget {
  const YamoreApp({super.key});

  @override
  State<YamoreApp> createState() => _YamoreAppState();
}

class _YamoreAppState extends State<YamoreApp> with WidgetsBindingObserver {
  final DeepLinkCoordinator _deepLinks = DeepLinkCoordinator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinks.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinks.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _deepLinks.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yamore',
      navigatorKey: appNavigatorKey,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
