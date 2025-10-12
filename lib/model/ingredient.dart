/// Model Ingredient - Nguyên liệu
class Ingredient {
  final String id;
  final String name;
  final String quantity;
  final String unit;
  final String recipeId;

  Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.recipeId,
  });

  /// Chuyển từ JSON sang object Ingredient
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
      recipeId: json['recipeId'],
    );
  }

  /// Chuyển từ object Ingredient sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'recipeId': recipeId,
    };
  }
}