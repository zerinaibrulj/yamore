import 'dart:io' show Platform;

class AppConfig {
  /// API base URL. Configurable via: flutter run --dart-define=API_BASE_URL=https://your-api.com
  /// If not set, uses platform defaults (e.g. 10.0.2.2:5096 on Android emulator, localhost:5096 elsewhere).
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5096';
    }
    return 'http://localhost:5096';
  }
}
