import 'dart:io' show Platform;

class AppConfig {
  /// On Android emulator, `localhost` is the emulator itself.
  /// Use `10.0.2.2` to reach the host machine's localhost.
  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5096';
    }
    return 'http://localhost:5096';
  }
}
