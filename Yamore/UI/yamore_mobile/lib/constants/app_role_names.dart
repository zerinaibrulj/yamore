/// API / JWT role claim names, normalized to lowercase for comparisons
/// (see `AppRoles` in the Yamore .NET `Yamore.Model` project).
class AppRoleNames {
  AppRoleNames._();

  static const String admin = 'admin';
  static const String yachtOwner = 'yachtowner';
  static const String user = 'user';
  static const String endUser = 'enduser';
}

/// Role name strings as sent in API requests and filters (Pascal case; matches `AppRoles`).
class ApiRoleNames {
  ApiRoleNames._();

  static const String admin = 'Admin';
  static const String yachtOwner = 'YachtOwner';
  static const String user = 'User';
}
