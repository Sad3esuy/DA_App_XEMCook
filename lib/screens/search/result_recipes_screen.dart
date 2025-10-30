import 'package:flutter/material.dart';

import '../recipe/recipe_collection_screen.dart';

/// Lightweight wrapper that adapts legacy category entry points to the new
/// recipe collection experience used across the app.
class CategoryRecipesScreen extends StatelessWidget {
  const CategoryRecipesScreen({
    super.key,
    required this.title,
    this.category,
    this.searchKeyword,
    this.tags = const <String>[],
    this.tagHint,
  });

  final String title;
  final String? category;
  final String? searchKeyword;
  final List<String> tags;
  final String? tagHint;

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = _normalize(category);
    final normalizedTags = _buildInitialTags();
    final sort = _resolveSort();
    final timeframe = _resolveTimeframe();
    final searchText = searchKeyword?.trim();
    final hasSearch = searchText != null && searchText.isNotEmpty;

    return RecipeCollectionScreen(
      config: RecipeCollectionConfig(
        title: title,
        initialCategory: normalizedCategory,
        initialDietTags: normalizedTags,
        initialTags: normalizedTags,
        initialTimeframe: timeframe,
        timeframeTarget: _resolveTimeframeTarget(),
        initialSort: sort,
        initialSearch: hasSearch ? searchText : null,
        enableSearch: hasSearch,
        searchHint: 'Bạn muốn nấu món gì hôm nay?',
      ),
    );
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed.toLowerCase();
  }

  List<String> _buildInitialTags() {
    final values = <String>{};
    for (final tag in tags) {
      final normalized = _normalize(tag);
      if (normalized != null) values.add(normalized);
    }
    final hint = _normalize(tagHint);
    if (hint != null && !_isQuickFilterKeyword(hint)) {
      values.add(hint);
    }
    return values.toList();
  }

  RecipeCollectionSort _resolveSort() {
    final hint = _normalize(tagHint);
    switch (hint) {
      case 'new':
        return RecipeCollectionSort.createdAt;
      case 'popular':
        return RecipeCollectionSort.views;
      default:
        return RecipeCollectionSort.defaultSort;
    }
  }

  String _resolveTimeframe() {
    final hint = _normalize(tagHint);
    if (hint == 'popular') {
      return 'week';
    }
    return 'all';
  }

  String? _resolveTimeframeTarget() {
    final hint = _normalize(tagHint);
    if (hint == 'popular') {
      return 'views';
    }
    if (hint == 'new') {
      return 'recipes';
    }
    return null;
  }

  bool _isQuickFilterKeyword(String value) {
    return value == 'new' || value == 'popular';
  }
}
