import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/shopping_item.dart';

/// Quản lý danh sách mua sắm được lưu trữ nội bộ bằng SharedPreferences.
class ShoppingListService {
  ShoppingListService._();

  static final ShoppingListService instance = ShoppingListService._();
  static const String _storageKey = 'shopping_list_items';

  final ValueNotifier<List<ShoppingItem>> itemsNotifier =
      ValueNotifier<List<ShoppingItem>>(<ShoppingItem>[]);
  bool _loaded = false;

  List<ShoppingItem> get items => itemsNotifier.value;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    final items = <ShoppingItem>[];
    for (final entry in raw) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        items.add(ShoppingItem.fromJson(map));
      } catch (_) {
        // Bỏ qua item lỗi
      }
    }
    _loaded = true;
    itemsNotifier.value = List.unmodifiable(items);
  }

  Future<void> _persist(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, payload);
    itemsNotifier.value = List.unmodifiable(items);
  }

  Future<void> addItems(List<ShoppingItem> newItems) async {
    if (newItems.isEmpty) return;
    await ensureLoaded();
    final List<ShoppingItem> updated = List<ShoppingItem>.from(items);

    for (final item in newItems) {
      final key = _normalizeKey(item);
      final index =
          updated.indexWhere((existing) => _normalizeKey(existing) == key);
      if (index >= 0) {
        final existing = updated[index];
        updated[index] = existing.copyWith(
          quantity: _mergeQuantities(existing.quantity, item.quantity),
          unit: existing.unit ?? item.unit,
          note: (existing.note?.isNotEmpty == true) ? existing.note : item.note,
          recipeId: existing.recipeId ?? item.recipeId,
          recipeTitle: existing.recipeTitle ?? item.recipeTitle,
          checked: false,
        );
      } else {
        updated.add(item);
      }
    }

    await _persist(updated);
  }

  Future<void> toggleChecked(String id) async {
    await ensureLoaded();
    final updated = items.map((item) {
      if (item.id == id) {
        return item.copyWith(checked: !item.checked);
      }
      return item;
    }).toList();
    await _persist(updated);
  }

  Future<void> updateNote(String id, String note) async {
    await ensureLoaded();
    final updated = items.map((item) {
      if (item.id == id) {
        return item.copyWith(note: note.trim().isEmpty ? null : note.trim());
      }
      return item;
    }).toList();
    await _persist(updated);
  }

  Future<void> removeItem(String id) async {
    await ensureLoaded();
    final updated = items.where((item) => item.id != id).toList();
    await _persist(updated);
  }

  Future<void> clearChecked() async {
    await ensureLoaded();
    final updated = items.where((item) => !item.checked).toList();
    await _persist(updated);
  }

  Future<void> clearAll() async {
    _loaded = true;
    await _persist(<ShoppingItem>[]);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await ensureLoaded();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<ShoppingItem> updated = List<ShoppingItem>.from(items);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await _persist(updated);
  }

  String _normalizeKey(ShoppingItem item) {
    final buffer = StringBuffer(item.name.trim().toLowerCase());
    if (item.unit != null && item.unit!.trim().isNotEmpty) {
      buffer.write('::${item.unit!.trim().toLowerCase()}');
    }
    return buffer.toString();
  }

  String? _mergeQuantities(String? a, String? b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;
    if (a.trim() == b.trim()) return a.trim();
    return '$a + $b';
  }
}
