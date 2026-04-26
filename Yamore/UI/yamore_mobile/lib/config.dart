import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

import 'api_base_url_native.dart' if (dart.library.html) 'api_base_url_stub.dart'
    as platform_api;

/// API base URL for the Yamore backend.
///
/// **Release / production:** pass the full URL at build time (overrides all defaults):
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
/// flutter build apk --dart-define=API_BASE_URL=https://api.example.com
/// flutter build windows --dart-define=API_BASE_URL=https://api.example.com
/// ```
///
/// **Debug / profile (no `API_BASE_URL` set):** uses [defaultDevApiPort] with:
/// - Web (`kIsWeb`) → `http://localhost:<port>`
/// - Android (emulator; `Platform.isAndroid` in `api_base_url_native.dart`) → `http://10.0.2.2:<port>`
/// - Windows (`Platform.isWindows`) → `http://localhost:<port>`
/// - other native → `http://localhost:<port>`
///
/// `AuthService` and `ApiService` take a single `baseUrl` from [apiBaseUrl] (see
/// `login_screen.dart` / `register_screen.dart`); do not duplicate URL rules in services.
class AppConfig {
  /// Dev default port — must match the API (see `Yamore.API/Properties/launchSettings.json`, e.g. `http` profile on **5096**).
  static const int defaultDevApiPort = 5096;

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      final r = fromEnv.trim();
      return r.endsWith('/') ? r.substring(0, r.length - 1) : r;
    }
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is not set. Rebuild with --dart-define=API_BASE_URL=<your API base URL> '
        '(e.g. https://api.example.com, or for local dev: http://10.0.2.2:5096 on Android '
        'emulator, http://localhost:5096 on Windows; port must match your API).',
      );
    }
    final String raw;
    if (kIsWeb) {
      raw = 'http://localhost:$defaultDevApiPort';
    } else {
      raw = platform_api.defaultApiBaseUrlForPlatform(defaultDevApiPort);
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }
}
