import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchHelper {
  static const _key = 'recent_searches';
  static const _maxEntries = 10;

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> current = prefs.getStringList(_key) ?? [];

    // remove duplicate if it already exists, so it moves to the top instead of repeating
    current.removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase());

    current.insert(0, trimmed);

    if (current.length > _maxEntries) {
      current = current.sublist(0, _maxEntries);
    }

    await prefs.setStringList(_key, current);
  }

  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(query);
    await prefs.setStringList(_key, current);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}