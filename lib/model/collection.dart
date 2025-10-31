import 'recipe.dart';

class Collection {
  final String id;
  final String userId;
  final String name;
  final String description;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? recipeIds; // IDs của recipes trong collection
  final List<Recipe>? recipes; // Full recipe objects (if included)
  final int recipeCount; // Số lượng recipes

  const Collection({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.recipeIds,
    this.recipes,
    this.recipeCount = 0,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    // Parse recipes list if present
    final recipesData = json['recipes'];
    List<String>? recipeIds;
    List<Recipe>? recipes;
    
    if (recipesData is List) {
      // Try to parse full recipe objects if available
      try {
        recipes = recipesData
            .whereType<Map<String, dynamic>>()
            .map((r) => Recipe.fromJson(r))
            .toList();
        recipeIds = recipes.map((r) => r.id).toList();
      } catch (e) {
        // Fallback to just IDs if parsing fails
        recipeIds = recipesData
            .map((r) => (r is Map<String, dynamic>) ? (r['id']?.toString() ?? '') : '')
            .where((id) => id.isNotEmpty)
            .toList();
      }
    }

    // Use recipeCount from JSON if available, otherwise fallback to recipes array length
    int count = 0;
    if (json['recipeCount'] != null) {
      count = int.tryParse(json['recipeCount'].toString()) ?? 0;
    } else if (recipes != null) {
      count = recipes.length;
    } else if (recipeIds != null) {
      count = recipeIds.length;
    }

    return Collection(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isPublic: json['isPublic'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      recipeIds: recipeIds,
      recipes: recipes,
      recipeCount: count,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'isPublic': isPublic,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (recipeIds != null) 'recipeIds': recipeIds,
        if (recipes != null) 'recipes': recipes!.map((r) => r.toJson()).toList(),
        'recipeCount': recipeCount,
      };

  Collection copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? recipeIds,
    List<Recipe>? recipes,
    int? recipeCount,
  }) {
    return Collection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recipeIds: recipeIds ?? this.recipeIds,
      recipes: recipes ?? this.recipes,
      recipeCount: recipeCount ?? this.recipeCount,
    );
  }
}
