import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../model/recipe.dart';
import 'recipe_api_service.dart';

/// Singleton to keep recipe favorite states in sync across screens.
class FavoriteState extends ChangeNotifier {
  FavoriteState._internal();

  static final FavoriteState instance = FavoriteState._internal();

  final Set<String> _favoriteIds = <String>{};

  UnmodifiableSetView<String> get ids => UnmodifiableSetView(_favoriteIds);

  bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);

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
      notifyListeners();
    }
  }
}
