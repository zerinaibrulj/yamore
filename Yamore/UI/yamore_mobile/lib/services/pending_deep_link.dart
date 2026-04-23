/// Yacht detail to open after a successful mobile-user login (from `yamore://yacht/<id>` while logged out).
class PendingDeepLink {
  static int? _yachtId;

  static int? get yachtId => _yachtId;

  static void setYachtId(int id) {
    _yachtId = id;
  }

  static int? takeYachtId() {
    final v = _yachtId;
    _yachtId = null;
    return v;
  }

  static void clear() {
    _yachtId = null;
  }
}
