import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _storageKey = 'recipe_search_history';
  static const int _maxEntries = 12;

  const SearchHistoryService._();

  static Future<List<String>> loadHistory({String? query}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? const <String>[];
    if (query == null || query.trim().isEmpty) {
      return List<String>.from(stored);
    }
    final normalized = query.trim().toLowerCase();
    return stored
        .where((item) => item.toLowerCase().contains(normalized))
        .toList();
  }

  static Future<void> addQuery(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_storageKey) ?? <String>[];
    final existingIndex = history.indexWhere(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    );
    if (existingIndex >= 0) {
      history.removeAt(existingIndex);
    }
    history.insert(0, normalized);
    if (history.length > _maxEntries) {
      history.removeRange(_maxEntries, history.length);
    }
    await prefs.setStringList(_storageKey, history);
  }

  static Future<void> removeQuery(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_storageKey)?.toList() ?? <String>[];
    history.removeWhere(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    );
    await prefs.setStringList(_storageKey, history);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
