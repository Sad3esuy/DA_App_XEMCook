import 'collection.dart';
import 'recipe.dart';
import 'user.dart';

class ChefProfile {
  final User user;
  final UserStats stats;
  final List<Recipe> recipes;
  final List<Collection> collections;

  const ChefProfile({
    required this.user,
    required this.stats,
    required this.recipes,
    required this.collections,
  });

  factory ChefProfile.fromJson(Map<String, dynamic> json) {
    final userJson = Map<String, dynamic>.from(json['user'] ?? const {});
    final statsJson = Map<String, dynamic>.from(json['stats'] ?? const {});
    final recipesJson = (json['recipes'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final collectionsJson = (json['collections'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return ChefProfile(
      user: User.fromJson(userJson),
      stats: UserStats.fromJson(statsJson),
      recipes: recipesJson.map(Recipe.fromJson).toList(),
      collections: collectionsJson.map(Collection.fromJson).toList(),
    );
  }
  ChefProfile copyWith({
    User? user,
    UserStats? stats,
    List<Recipe>? recipes,
    List<Collection>? collections,
  }) {
    return ChefProfile(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      recipes: recipes ?? this.recipes,
      collections: collections ?? this.collections,
    );
  }
}
