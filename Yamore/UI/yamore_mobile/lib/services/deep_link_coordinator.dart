import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/yacht_overview.dart';
import '../screens/login/login_screen.dart';
import '../screens/mobile/mobile_yacht_detail_screen.dart';
import 'api_service.dart';
import 'app_navigator.dart';
import 'auth_service.dart';
import 'pending_deep_link.dart';
import 'session_controller.dart';

/// Handles cold-start and in-session URIs (`yamore://…`, `https://…/yacht/…`).
class DeepLinkCoordinator {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start() async {
    try {
      final initial = await _appLinks.getInitialLink();
      await _handleUri(initial);
    } catch (e, st) {
      debugPrint('DeepLinkCoordinator initial link: $e\n$st');
    }
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (Object e, StackTrace st) => debugPrint('DeepLinkCoordinator stream: $e\n$st'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Some platforms deliver the link on resume via [AppLinks.getLatestLink] rather than the stream alone.
  Future<void> onAppResumed() async {
    try {
      await _handleUri(await _appLinks.getLatestLink());
    } catch (e, st) {
      debugPrint('DeepLinkCoordinator getLatestLink: $e\n$st');
    }
  }

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null || !nav.mounted) return;

    if (_isLoginDeepLink(uri)) {
      PendingDeepLink.clear();
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    final yachtId = _parseYachtId(uri);
    if (yachtId == null || yachtId <= 0) return;

    final auth = SessionController.instance.auth;
    final user = auth?.currentUser;
    if (auth == null || user == null || !auth.isLoggedIn) {
      PendingDeepLink.setYachtId(yachtId);
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    if (user.isAdmin) {
      return;
    }

    await _pushYachtDetail(nav, auth, user, yachtId);
  }

  bool _isLoginDeepLink(Uri uri) {
    if (uri.scheme != 'yamore') return false;
    final h = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    if (h == 'login') return true;
    if (path == '/login' || path.endsWith('/login')) return true;
    for (final s in uri.pathSegments) {
      if (s.toLowerCase() == 'login') return true;
    }
    return false;
  }

  int? _parseYachtId(Uri uri) {
    if (uri.scheme == 'yamore') {
      if (uri.host.toLowerCase() == 'yacht') {
        if (uri.pathSegments.isNotEmpty) {
          return int.tryParse(uri.pathSegments.first);
        }
        final p = uri.path.replaceFirst(RegExp(r'^/+'), '');
        if (p.isNotEmpty) return int.tryParse(p);
      }
      final idx = uri.pathSegments.indexWhere((s) => s.toLowerCase() == 'yacht');
      if (idx >= 0 && idx + 1 < uri.pathSegments.length) {
        return int.tryParse(uri.pathSegments[idx + 1]);
      }
      final q =
          uri.queryParameters['yachtId'] ?? uri.queryParameters['id'] ?? uri.queryParameters['yacht'];
      if (q != null) return int.tryParse(q);
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final idx = uri.pathSegments.indexWhere((s) => s.toLowerCase() == 'yacht');
      if (idx >= 0 && idx + 1 < uri.pathSegments.length) {
        return int.tryParse(uri.pathSegments[idx + 1]);
      }
      final q = uri.queryParameters['yachtId'] ?? uri.queryParameters['id'];
      if (q != null) return int.tryParse(q);
    }
    return null;
  }

  Future<void> _pushYachtDetail(
    NavigatorState nav,
    AuthService auth,
    AppUser user,
    int yachtId,
  ) async {
    try {
      final api = ApiService(
        baseUrl: auth.baseUrl,
        auth: auth,
      );
      final detail = await api.getYachtById(yachtId);
      final overview = YachtOverview.fromYachtDetail(detail);
      if (!nav.mounted) return;
      await nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MobileYachtDetailScreen(
            api: api,
            user: user,
            authService: auth,
            overview: overview,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Deep link yacht navigation failed: $e\n$st');
    }
  }
}
