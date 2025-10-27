import '../utils/id_utils.dart';
import '../utils/quantity_utils.dart';
import 'ingredient.dart';

class ShoppingItem {
  final String id;
  final String shoppingListId;
  final String name;
  final String? quantity;
  final double? quantityValue;
  final String? unit;
  final bool checked;
  final String? note;
  final String? recipeId;
  final String? recipeTitle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShoppingItem({
    required this.id,
    required this.shoppingListId,
    required this.name,
    this.quantity,
    this.quantityValue,
    this.unit,
    this.checked = false,
    this.note,
    this.recipeId,
    this.recipeTitle,
    this.createdAt,
    this.updatedAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    final quantityRaw = json['quantity'];
    final parsedValue = json['quantityValue'];
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final updatedAtRaw = json['updatedAt'] ?? json['updated_at'];
    return ShoppingItem(
      id: json['id']?.toString() ?? generateId(),
      shoppingListId: json['shoppingListId']?.toString() ??
          json['listId']?.toString() ??
          json['shopping_list_id']?.toString() ??
          '',
      name: (json['name'] ?? json['ingredientName'] ?? '').toString(),
      quantity: quantityRaw?.toString(),
      quantityValue: parsedValue is num
          ? parsedValue.toDouble()
          : QuantityUtils.parse(quantityRaw?.toString()),
      unit: json['unit']?.toString(),
      checked: json['checked'] == true || json['isChecked'] == true,
      note: json['note']?.toString(),
      recipeId: json['recipeId']?.toString(),
      recipeTitle: json['recipeTitle']?.toString(),
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)
          : createdAtRaw is DateTime
              ? createdAtRaw
              : null,
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw)
          : updatedAtRaw is DateTime
              ? updatedAtRaw
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shoppingListId': shoppingListId,
      'name': name,
      'quantity': quantity,
      if (quantityValue != null) 'quantityValue': quantityValue,
      'unit': unit,
      'checked': checked,
      'note': note,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toRemotePayload() {
    return {
      'id': id,
      'ingredientName': name,
      'quantity': quantity,
      if (quantityValue != null) 'quantityValue': quantityValue,
      'unit': unit,
      'isChecked': checked,
      if (note != null) 'note': note,
      if (recipeId != null) 'recipeId': recipeId,
      if (recipeTitle != null) 'recipeTitle': recipeTitle,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? shoppingListId,
    String? name,
    String? quantity,
    bool quantityCleared = false,
    double? quantityValue,
    bool quantityValueCleared = false,
    String? unit,
    bool unitCleared = false,
    bool? checked,
    String? note,
    bool noteCleared = false,
    String? recipeId,
    bool recipeIdCleared = false,
    String? recipeTitle,
    bool recipeTitleCleared = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
    quantity: quantityCleared ? null : quantity ?? this.quantity,
      quantityValue: quantityValueCleared
          ? null
          : quantityValue ?? this.quantityValue,
    unit: unitCleared ? null : unit ?? this.unit,
      checked: checked ?? this.checked,
      note: noteCleared ? null : note ?? this.note,
      recipeId: recipeIdCleared ? null : recipeId ?? this.recipeId,
      recipeTitle:
          recipeTitleCleared ? null : recipeTitle ?? this.recipeTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ShoppingItem fromIngredient(
    Ingredient ingredient, {
    required String shoppingListId,
    String? id,
    double ratio = 1,
    int? baseServings,
    String? recipeTitle,
    String? overrideName,
  }) {
    final parsedBase = QuantityUtils.parse(ingredient.quantity);
    final scaledValue = (parsedBase != null) ? parsedBase * ratio : null;
    final scaledDisplay = scaledValue != null
        ? QuantityUtils.format(scaledValue)
        : (ingredient.quantity.trim().isEmpty
            ? null
            : ingredient.quantity.trim());

    return ShoppingItem(
      id: id ?? generateId(),
      shoppingListId: shoppingListId,
      name: overrideName?.trim().isNotEmpty == true
          ? overrideName!.trim()
          : ingredient.name.trim(),
      quantity: scaledDisplay,
      quantityValue: scaledValue,
      unit: ingredient.unit.trim().isEmpty
          ? null
          : ingredient.unit.trim(),
      checked: false,
      note: null,
      recipeId: ingredient.recipeId.isEmpty ? null : ingredient.recipeId,
      recipeTitle: recipeTitle,
    );
  }

  String get normalizedName => name.trim().toLowerCase();

  String get normalizedUnit => (unit ?? '').trim().toLowerCase();

  String get mergeKey => '${normalizedName}::${normalizedUnit}';
}
