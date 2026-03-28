import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static String _keyForUser(int userId) => 'yamore_favorites_user_$userId';

  static Future<Set<int>> loadFavorites(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyForUser(userId)) ?? const <String>[];
    final out = <int>{};
    for (final s in raw) {
      final v = int.tryParse(s);
      if (v != null) out.add(v);
    }
    return out;
  }

  static Future<void> saveFavorites(int userId, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ids.map((e) => e.toString()).toList();
    await prefs.setStringList(_keyForUser(userId), list);
  }
}

