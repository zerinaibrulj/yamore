import 'dart:io' show Platform;

/// API base URL for the Yamore backend.
///
/// **Override (staging/production):** pass at build/run time so nothing is fixed to one deployment:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
/// ```
///
/// **Local dev:** if you omit that flag, a sensible default is used:
/// - **Android emulator** → `http://10.0.2.2:5096` (host machine’s Docker/API)
/// - **Other platforms** (Windows, iOS simulator, web, etc.) → `http://localhost:5096`
///
/// See repository root `README.md` for Docker (API mapped to port 5096).
class AppConfig {
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final raw = fromEnv.isNotEmpty
        ? fromEnv
        : (Platform.isAndroid
            ? 'http://10.0.2.2:5096'
            : 'http://localhost:5096');
    return raw.endsWith('/')
        ? raw.substring(0, raw.length - 1)
        : raw;
  }
}
