import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

/// API base URL for the Yamore backend.
///
/// **Required in release:** pass the URL at build time (no hardcoded production URL in source):
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
/// flutter build apk --dart-define=API_BASE_URL=https://api.example.com
/// ```
/// The value is read with [String.fromEnvironment] so it is supplied by the build/run, not from JSON-in-app.
class AppConfig {
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      final r = fromEnv.trim();
      return r.endsWith('/') ? r.substring(0, r.length - 1) : r;
    }
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is not set. Rebuild with --dart-define=API_BASE_URL=<your API base URL> '
        '(e.g. http://10.0.2.2:5096 for Android emulator, http://localhost:5096 for desktop, same port as Docker 5096).',
      );
    }
    String raw;
    if (kIsWeb) {
      raw = 'http://localhost:5096';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      raw = 'http://10.0.2.2:5096';
    } else {
      raw = 'http://localhost:5096';
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }
}
