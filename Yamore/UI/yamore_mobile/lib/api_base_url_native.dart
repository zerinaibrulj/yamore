import 'dart:io' show Platform;

/// Resolves the default dev API base using [Platform] from [dart:io] (not available on web).
///
/// - **Android (emulator):** `http://10.0.2.2:<port>`
/// - **Windows:** `http://localhost:<port>`
/// - **Other (iOS sim, macOS, Linux):** `http://localhost:<port>`
String defaultApiBaseUrlForPlatform(int port) {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:$port';
  }
  if (Platform.isWindows) {
    return 'http://localhost:$port';
  }
  return 'http://localhost:$port';
}
