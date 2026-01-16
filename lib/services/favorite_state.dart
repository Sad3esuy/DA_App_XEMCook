import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

import '../model/recipe.dart';
import 'recipe_api_service.dart';

/// Singleton to keep recipe favorite states in sync across screens.
class FavoriteState extends ChangeNotifier {
  FavoriteState() {
    _loadFromStorage();
  }

  final Set<String> _favoriteIds = <String>{};
  static const String _storageKey = 'favorite_recipe_ids';

  UnmodifiableSetView<String> get ids => UnmodifiableSetView(_favoriteIds);

  bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? stored = prefs.getStringList(_storageKey);
      if (stored != null) {
        _favoriteIds.addAll(stored);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteIds.toList());
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  /// Sync favorite IDs from the server to ensure local state is accurate.
  Future<void> syncWithServer() async {
    try {
      final favorites = await RecipeApiService.getFavorites(limit: 1000);
      final favoriteIds = favorites.map((r) => r.id).toSet();
      _favoriteIds.clear();
      _favoriteIds.addAll(favoriteIds);
      _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing favorites: $e');
    }
  }

  /// Apply favorite hints from API recipe payloads without removing existing
  /// states, because some endpoints might omit the favorite flag.
  void absorbRecipes(Iterable<Recipe> recipes) {
    bool changed = false;
    for (final recipe in recipes) {
      if (recipe.isFavorite && _favoriteIds.add(recipe.id)) {
        changed = true;
      }
    }
    if (changed) {
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Replace the internal favorites set with a new source of truth.
  void replaceAll(Iterable<String> recipeIds) {
    final newSet = recipeIds.toSet();
    if (!setEquals(newSet, _favoriteIds)) {
      _favoriteIds
        ..clear()
        ..addAll(newSet);
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Toggle favorite state via the API and update local cache.
  Future<bool> toggleFavorite(String recipeId) async {
    final isFavorite = await RecipeApiService.toggleFavorite(recipeId);
    final changed = isFavorite
        ? _favoriteIds.add(recipeId)
        : _favoriteIds.remove(recipeId);
    if (changed) {
      _saveToStorage();
      notifyListeners();
    }
    return isFavorite;
  }

  /// Force a favorite status without hitting the API (e.g. optimistic updates).
  void setFavorite(String recipeId, bool isFavorite) {
    final changed = isFavorite
        ? _favoriteIds.add(recipeId)
        : _favoriteIds.remove(recipeId);
    if (changed) {
      _saveToStorage();
      notifyListeners();
    }
  }
}
