import 'package:flutter/material.dart';

import '../screens/login/login_screen.dart';
import 'app_navigator.dart';
import 'auth_service.dart';

/// Holds the active session for global handling (401, deep links after login).
class SessionController {
  SessionController._();
  static final SessionController instance = SessionController._();

  AuthService? _auth;

  AuthService? get auth => _auth;

  bool get isLoggedIn => _auth?.isLoggedIn == true;

  void bindAuth(AuthService auth) {
    _auth = auth;
  }

  void clearAuthBinding() {
    _auth = null;
  }

  /// Clears credentials and returns the user to the login screen.
  void handleUnauthorized() {
    _auth?.logout();
    _auth = null;
    final nav = appNavigatorKey.currentState;
    if (nav != null && nav.mounted) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}
