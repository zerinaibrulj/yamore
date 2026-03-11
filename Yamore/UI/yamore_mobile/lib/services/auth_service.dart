import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const _keyRememberUsername = 'yamore_remember_username';
  static const _keyRememberMe = 'yamore_remember_me';

  final String baseUrl;
  AppUser? _currentUser;
  String? _username;
  String? _password;

  AuthService({this.baseUrl = 'http://localhost:5096'});

  AppUser? get currentUser => _currentUser;
  String? get username => _username;
  String? get password => _password;
  bool get isLoggedIn => _currentUser != null;

  /// Returns Basic Auth header value for API calls, or null if not logged in.
  String? get basicAuthHeader {
    if (_username == null || _password == null) return null;
    return 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
  }

  Future<void> loadRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyRememberMe) == true) {
      _username = prefs.getString(_keyRememberUsername);
    }
  }

  Future<String?> getRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyRememberMe) == true) {
      return prefs.getString(_keyRememberUsername);
    }
    return null;
  }

  Future<void> setRememberMe(bool remember, {String? username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, remember);
    if (remember && username != null && username.isNotEmpty) {
      await prefs.setString(_keyRememberUsername, username);
    } else if (!remember) {
      await prefs.remove(_keyRememberUsername);
    }
  }

  /// Logs in with username and password. Returns [AppUser] on success.
  /// Throws [AuthException] on failure.
  Future<AppUser> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/Users/login').replace(
      queryParameters: {
        'username': username,
        'password': password,
      },
    );
    final response = await http.post(uri).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw AuthException(
        'The server is taking too long to respond. Check that the API is running at $baseUrl.',
      ),
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw AuthException('Invalid username or password.');
      }
      throw AuthException('Login failed: ${response.statusCode}');
    }
    final body = response.body.trim();
    if (body.isEmpty || body == 'null') {
      throw AuthException('Invalid username or password.');
    }
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final user = AppUser.fromJson(json);
      if (user.userId == 0) {
        throw AuthException('Invalid username or password.');
      }
      _currentUser = user;
      _username = username;
      _password = password;
      return user;
    } on FormatException catch (_) {
      throw AuthException('Server returned an unexpected response. Please try again.');
    }
  }

  void updateCurrentUser(AppUser user) {
    _currentUser = user;
  }

  void updatePassword(String newPassword) {
    _password = newPassword;
  }

  void logout() {
    _currentUser = null;
    _username = null;
    _password = null;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
