import 'ingredient.dart';
import 'instruction.dart';

/// Model Recipe - Công thức nấu ăn
class Recipe {
  final String id;
  final String title;
  final String description;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final String category;
  final String imageUrl;
  final bool isFavorite;
  final double avgRating;
  final int totalRatings;
  final List<String> tags;
  final Map<String, dynamic> nutrition; // dinh dưỡng (có thể rỗng)
  final String createdAt;
  final String updatedAt;
  final List<Ingredient> ingredients;
  final List<Instruction> instructions;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.category,
    required this.imageUrl,
    required this.isFavorite,
    this.avgRating = 0.0,
    this.totalRatings = 0,
    required this.tags,
    required this.nutrition,
    required this.createdAt,
    required this.updatedAt,
    required this.ingredients,
    required this.instructions,
  });

  /// Chuyển từ JSON sang object Recipe
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      prepTime: json['prepTime'],
      cookTime: json['cookTime'],
      servings: json['servings'],
      difficulty: json['difficulty'],
      category: json['category'],
      imageUrl: json['imageUrl'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      avgRating: _parseDouble(json['avgRating']),
      totalRatings: _parseInt(json['totalRatings']),
      tags: List<String>.from(json['tags'] ?? []),
      nutrition: json['nutrition'] ?? {},
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((e) => Ingredient.fromJson(e))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>? ?? const [])
          .map((e) => Instruction.fromJson(e))
          .toList(),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Chuyển từ object Recipe sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'category': category,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'tags': tags,
      'nutrition': nutrition,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'instructions': instructions.map((e) => e.toJson()).toList(),
    };
  }
}
