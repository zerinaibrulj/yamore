import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const _keyRememberUsername = 'yamore_remember_username';
  static const _keyRememberMe = 'yamore_remember_me';
  static const _keyAccess = 'yamore_access_token';
  static const _keyRefresh = 'yamore_refresh_token';
  static const _keyAccessExpMs = 'yamore_access_exp_utc_ms';
  static const _keyUser = 'yamore_user_json';

  final String baseUrl;
  AppUser? _currentUser;
  String? _username;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenValidUntil;
  Future<void>? _refreshInFlight;

  AuthService({required this.baseUrl});

  AppUser? get currentUser => _currentUser;
  String? get username => _username ?? _currentUser?.username;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _currentUser != null;

  static dynamic _jsonKey(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  /// Authorization header for [Image.network] and other sync callers. Prefer calling
  /// [ensureValidAccess] before a batch of work so the access token is still valid.
  Map<String, String> get authHeaders {
    final t = _accessToken;
    if (t == null || t.isEmpty) return const {};
    return {'Authorization': 'Bearer $t'};
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

  void _setExpiryFromResponse(Map<String, dynamic> json) {
    final expIn = _jsonKey(json, 'accessTokenExpiresIn', 'AccessTokenExpiresIn');
    if (expIn is! num) {
      _accessTokenValidUntil = null;
      return;
    }
    final bufferSec = 60;
    _accessTokenValidUntil = DateTime.now()
        .toUtc()
        .add(Duration(seconds: expIn.toInt() - bufferSec));
  }

  void _applyLoginResponse(Map<String, dynamic> json) {
    _currentUser = AppUser.fromJson(json);
    _username = _currentUser?.username;
    final at = _jsonKey(json, 'accessToken', 'AccessToken') as String?;
    final rt = _jsonKey(json, 'refreshToken', 'RefreshToken') as String?;
    _accessToken = (at == null || at.isEmpty) ? null : at;
    _refreshToken = (rt == null || rt.isEmpty) ? null : rt;
    _setExpiryFromResponse(json);
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_keyAccess, _accessToken!);
    } else {
      await prefs.remove(_keyAccess);
    }
    if (_refreshToken != null) {
      await prefs.setString(_keyRefresh, _refreshToken!);
    } else {
      await prefs.remove(_keyRefresh);
    }
    if (_accessTokenValidUntil != null) {
      await prefs.setInt(_keyAccessExpMs, _accessTokenValidUntil!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyAccessExpMs);
    }
    if (_currentUser != null) {
      await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));
    } else {
      await prefs.remove(_keyUser);
    }
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyAccessExpMs);
    await prefs.remove(_keyUser);
  }

  void _clearLocalSession() {
    _currentUser = null;
    _username = null;
    _accessToken = null;
    _refreshToken = null;
    _accessTokenValidUntil = null;
  }

  /// Refreshes the access token when it is expiring, or the session was restored with a refresh token only.
  Future<void> ensureValidAccess() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return;
    }
    if (_accessToken != null &&
        _accessTokenValidUntil != null &&
        DateTime.now().toUtc().isBefore(_accessTokenValidUntil!)) {
      return;
    }
    if (_refreshInFlight != null) {
      await _refreshInFlight;
      return;
    }
    _refreshInFlight = _doRefresh();
    try {
      await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _doRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return;
    final uri = Uri.parse('$baseUrl/Users/refresh');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'RefreshToken': _refreshToken,
      }),
    );
    if (response.statusCode != 200) {
      _clearLocalSession();
      await _clearPersisted();
      return;
    }
    final body = response.body.trim();
    if (body.isEmpty || body == 'null') {
      _clearLocalSession();
      await _clearPersisted();
      return;
    }
    _applyLoginResponse(jsonDecode(body) as Map<String, dynamic>);
    if (_currentUser == null || _currentUser!.userId == 0) {
      _clearLocalSession();
      await _clearPersisted();
      return;
    }
    await _persistSession();
  }

  /// Restore tokens from [SharedPreferences] and refresh the access token if needed.
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = prefs.getString(_keyRefresh);
    _accessToken = prefs.getString(_keyAccess);
    final expMs = prefs.getInt(_keyAccessExpMs);
    if (expMs != null) {
      _accessTokenValidUntil = DateTime.fromMillisecondsSinceEpoch(expMs, isUtc: true);
    }
    final u = prefs.getString(_keyUser);
    if (u != null) {
      try {
        _currentUser = AppUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
        _username = _currentUser?.username;
      } catch (_) {
        _currentUser = null;
      }
    }
    if ((_refreshToken == null || _refreshToken!.isEmpty) &&
        (_accessToken == null || _accessToken!.isEmpty)) {
      return false;
    }
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await ensureValidAccess();
    }
    if (_currentUser == null || _currentUser!.userId == 0) {
      return false;
    }
    if (_accessToken == null || _accessToken!.isEmpty) {
      return false;
    }
    return true;
  }

  /// Logs in with JSON body. Returns [AppUser] on success.
  Future<AppUser> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/Users/login');
    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'Username': username,
        'Password': password,
      }),
    )
        .timeout(
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
      _applyLoginResponse(jsonDecode(body) as Map<String, dynamic>);
    } on FormatException catch (_) {
      throw AuthException('Server returned an unexpected response. Please try again.');
    }
    if (_currentUser == null || _currentUser!.userId == 0) {
      _clearLocalSession();
      throw AuthException('Invalid username or password.');
    }
    await _persistSession();
    return _currentUser!;
  }

  /// Registers; server controls roles and must not be escalated from the client.
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    final uri = Uri.parse('$baseUrl/Users/register');
    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'FirstName': firstName,
        'LastName': lastName,
        'Email': email,
        'Phone': phone,
        'Username': username,
        'Password': password,
        'PasswordConfirmation': passwordConfirmation,
      }),
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw AuthException(
        'The server is taking too long to respond. Check that the API is running at $baseUrl.',
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = response.body.trim();
      if (body.contains('Username') && body.contains('already')) {
        throw AuthException('This username is already taken. Please choose another.');
      }
      throw AuthException('Registration failed: ${response.statusCode} $body');
    }
    final body = response.body.trim();
    if (body.isEmpty || body == 'null') {
      throw AuthException('Registration response was empty.');
    }
    _applyLoginResponse(jsonDecode(body) as Map<String, dynamic>);
    if (_currentUser == null || _currentUser!.userId == 0) {
      _clearLocalSession();
      throw AuthException('Registration could not be completed.');
    }
    await _persistSession();
    return _currentUser!;
  }

  void updateCurrentUser(AppUser user) {
    _currentUser = user;
  }

  void updatePassword(String newPassword) {
    // With JWT, password changes are handled only on the server via the users API.
  }

  /// Revokes access (JTI blacklist) and refresh on the server, then clears local state.
  Future<void> logout() async {
    final at = _accessToken;
    final rt = _refreshToken;
    _clearLocalSession();
    await _clearPersisted();
    if (at != null && at.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/Users/revoke');
        await http
            .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $at',
          },
          body: jsonEncode({
            'RefreshToken': rt,
          }),
        )
            .timeout(const Duration(seconds: 12));
      } catch (_) {
        // Ignore — client session is already cleared.
      }
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
