class AppUser {
  final int userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String username;
  final bool? status;
  final List<String> roles;

  AppUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    required this.username,
    this.status,
    required this.roles,
  });

  String get displayName => '$firstName $lastName'.trim();

  bool get isAdmin => roles.any((r) => r.toLowerCase() == 'admin');
  bool get isYachtOwner => roles.any((r) => r.toLowerCase() == 'yachtowner');
  bool get isUser => roles.any((r) => r.toLowerCase() == 'user' || r.toLowerCase() == 'enduser');

  /// Try both camelCase and PascalCase (API may serialize either way).
  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roles = <String>[];
    final rolesRaw = _key(json, 'roles', 'Roles');
    if (rolesRaw is List<dynamic>) {
      for (final r in rolesRaw) {
        if (r is String && r.isNotEmpty) roles.add(r);
      }
    }
    if (roles.isEmpty) {
      final userRolesRaw = _key(json, 'userRoles', 'UserRoles');
      final userRoles = userRolesRaw is List<dynamic> ? userRolesRaw : <dynamic>[];
      for (final ur in userRoles) {
        final roleMap = ur is Map<String, dynamic> ? ur : null;
        if (roleMap == null) continue;
        final roleObj = _key(roleMap, 'role', 'Role');
        final name = roleObj is Map<String, dynamic>
            ? (roleObj['name'] ?? roleObj['Name']) as String?
            : null;
        if (name != null && name.isNotEmpty) roles.add(name);
      }
    }
    return AppUser(
      userId: (_key(json, 'userId', 'UserId') as num?)?.toInt() ?? 0,
      firstName: (_key(json, 'firstName', 'FirstName') as String?) ?? '',
      lastName: (_key(json, 'lastName', 'LastName') as String?) ?? '',
      email: _key(json, 'email', 'Email') as String?,
      phone: _key(json, 'phone', 'Phone') as String?,
      username: (_key(json, 'username', 'Username') as String?) ?? '',
      status: _key(json, 'status', 'Status') as bool?,
      roles: roles,
    );
  }
}
