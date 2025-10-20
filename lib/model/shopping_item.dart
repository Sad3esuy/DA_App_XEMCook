import 'ingredient.dart';

/// Đại diện cho một mục trong danh sách mua sắm.
class ShoppingItem {
  final String id;
  final String name;
  final String? quantity;
  final String? unit;
  final bool checked;
  final String? note;
  final String? recipeId;
  final String? recipeTitle;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.checked = false,
    this.note,
    this.recipeId,
    this.recipeTitle,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id']?.toString() ?? _createId(),
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      checked: json['checked'] == true,
      note: json['note']?.toString(),
      recipeId: json['recipeId']?.toString(),
      recipeTitle: json['recipeTitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      'checked': checked,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (recipeId != null) 'recipeId': recipeId,
      if (recipeTitle != null && recipeTitle!.isNotEmpty)
        'recipeTitle': recipeTitle,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    bool? checked,
    String? note,
    String? recipeId,
    String? recipeTitle,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      checked: checked ?? this.checked,
      note: note ?? this.note,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
    );
  }

  static ShoppingItem fromIngredient(
    Ingredient ingredient, {
    String? recipeTitle,
    String? overrideName,
  }) {
    return ShoppingItem(
      id: _createId(),
      name: overrideName?.trim().isNotEmpty == true
          ? overrideName!.trim()
          : ingredient.name,
      quantity: ingredient.quantity.trim().isEmpty
          ? null
          : ingredient.quantity.trim(),
      unit: ingredient.unit.trim().isEmpty ? null : ingredient.unit.trim(),
      recipeId: ingredient.recipeId.isEmpty ? null : ingredient.recipeId,
      recipeTitle: recipeTitle,
    );
  }
}

int _idSeed = 0;
String _createId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _idSeed = (_idSeed + 1) % 1000;
  return '$now$_idSeed';
}
