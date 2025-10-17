import 'recipe.dart';

class HomeFeed {
  HomeFeed({
    required this.topRated,
    required this.mostViewed,
    required this.quickMeals,
    required this.seasonal,
    required this.recipeOfTheDay,
  });

  final List<Recipe> topRated;
  final List<Recipe> mostViewed;
  final List<Recipe> quickMeals;
  final SeasonalSection seasonal;
  final RecipeOfDaySection recipeOfTheDay;

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    // Build sections
    final topRated = _parseRecipeList(json['topRated']);
    final mostViewed = _parseRecipeList(json['mostViewed']);
    final quickMeals = _parseRecipeList(json['quickMeals']);

    // Ensure "Top Rated" is truly based on ratings, not view count
    topRated.sort(_compareByRatingThenRecency);

    // Build seasonal with internal filtering/sorting
    final seasonal = SeasonalSection.fromJson(
      json['seasonal'] as Map<String, dynamic>? ?? const {},
    );

    return HomeFeed(
      topRated: topRated,
      mostViewed: mostViewed,
      quickMeals: quickMeals,
      seasonal: seasonal,
      recipeOfTheDay: RecipeOfDaySection.fromJson(json['recipeOfTheDay'] as Map<String, dynamic>? ?? const {}),
    );
  }

  List<Recipe> collectUniqueRecipes() {
    final combined = [
      ...recipeOfTheDay.recipes,
      ...topRated,
      ...mostViewed,
      ...quickMeals,
      ...seasonal.recipes,
    ];
    final map = <String, Recipe>{};
    for (final recipe in combined) {
      map.putIfAbsent(recipe.id, () => recipe);
    }
    return List<Recipe>.from(map.values);
  }

  static List<Recipe> _parseRecipeList(dynamic value) {
    if (value is List<dynamic>) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(Recipe.fromJson)
          .toList();
    }
    return const <Recipe>[];
  }

  // Sort by avgRating desc, then totalRatings desc, then createdAt desc
  static int _compareByRatingThenRecency(Recipe a, Recipe b) {
    final byAvg = b.avgRating.compareTo(a.avgRating);
    if (byAvg != 0) return byAvg;
    final byCount = b.totalRatings.compareTo(a.totalRatings);
    if (byCount != 0) return byCount;
    final aDate = _safeParseDate(a.createdAt);
    final bDate = _safeParseDate(b.createdAt);
    return bDate.compareTo(aDate);
  }

  static DateTime _safeParseDate(String v) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

class SeasonalSection {
  SeasonalSection({
    required this.key,
    required this.label,
    required this.tags,
    required this.recipes,
  });

  final String key;
  final String label;
  final List<String> tags;
  final List<Recipe> recipes;

  factory SeasonalSection.fromJson(Map<String, dynamic> json) {
    final key = (json['key'] as String?)?.trim().isNotEmpty == true
        ? json['key'] as String
        : 'seasonal';
    final label = (json['label'] as String?)?.trim().isNotEmpty == true
        ? json['label'] as String
        : 'Seasonal picks';
    final tags = (json['tags'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    // Parse recipes then filter/sort by seasonal tags and rating (not view count)
    final rawRecipes = HomeFeed._parseRecipeList(json['recipes']);
    final normalizedTags = tags.map((e) => e.trim().toLowerCase()).toSet();

    List<Recipe> filtered = rawRecipes;
    if (normalizedTags.isNotEmpty) {
      filtered = rawRecipes.where((r) {
        final recipeTags = r.tags.map((t) => t.trim().toLowerCase());
        return recipeTags.any(normalizedTags.contains);
      }).toList();
    }

    filtered.sort(HomeFeed._compareByRatingThenRecency);

    return SeasonalSection(
      key: key,
      label: label,
      tags: tags,
      recipes: filtered,
    );
  }

  bool get hasRecipes => recipes.isNotEmpty;
}

class RecipeOfDaySection {
  RecipeOfDaySection({
    required this.date,
    required this.seed,
    required this.recipes,
  });

  final String date;
  final String seed;
  final List<Recipe> recipes;

  factory RecipeOfDaySection.fromJson(Map<String, dynamic> json) {
    return RecipeOfDaySection(
      date: json['date']?.toString() ?? '',
      seed: json['seed']?.toString() ?? '',
      recipes: HomeFeed._parseRecipeList(json['recipes']),
    );
  }

  bool get hasRecipes => recipes.isNotEmpty;

  DateTime? get parsedDate {
    if (date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }
}
