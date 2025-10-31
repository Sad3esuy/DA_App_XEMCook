import 'shopping_item.dart';

class ShoppingList {
  final String id;
  final String ownerId;
  final String name;
  final List<ShoppingItem> items;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShoppingList({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.items,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  ShoppingList copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<ShoppingItem>? items,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      items: items ?? this.items,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final updatedAtRaw = json['updatedAt'] ?? json['updated_at'];
    return ShoppingList(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ??
          json['userId']?.toString() ??
          json['owner_id']?.toString() ??
          '',
      name: json['name']?.toString() ?? 'Shopping list',
      items: itemsRaw is List
          ? itemsRaw
              .map((e) => e is ShoppingItem
                  ? e
                  : ShoppingItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const [],
      isCompleted: json['isCompleted'] == true,
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
      'ownerId': ownerId,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'isCompleted': isCompleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ShoppingList withItems(List<ShoppingItem> newItems) => copyWith(
        items: List<ShoppingItem>.unmodifiable(newItems),
      );

  bool get isEmpty => items.isEmpty;
  int get totalCount => items.length;
  int get uncheckedCount =>
      items.where((element) => element.checked == false).length;
}
