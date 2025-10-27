import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/recipe.dart';
import '../model/shopping_item.dart';
import '../model/shopping_list.dart';
import '../utils/id_utils.dart';
import '../utils/quantity_utils.dart';
import 'auth_service.dart';
import 'shopping_list_remote.dart';

const String _stateKeyPrefix = 'shopping_lists_state_v2';
const String _pendingKeyPrefix = 'shopping_pending_ops_v1';
const String _legacyItemsKey = 'shopping_list_items';

class ShoppingListState {
  const ShoppingListState({
    required this.isLoading,
    required this.isSyncing,
    required this.lists,
    required this.selectedListId,
    required this.lastSyncedAt,
    required this.pendingOperationCount,
  });

  final bool isLoading;
  final bool isSyncing;
  final List<ShoppingList> lists;
  final String? selectedListId;
  final DateTime? lastSyncedAt;
  final int pendingOperationCount;

  factory ShoppingListState.initial() => const ShoppingListState(
        isLoading: true,
        isSyncing: false,
        lists: <ShoppingList>[],
        selectedListId: null,
        lastSyncedAt: null,
        pendingOperationCount: 0,
      );

  ShoppingListState copyWith({
    bool? isLoading,
    bool? isSyncing,
    List<ShoppingList>? lists,
    String? selectedListId,
    DateTime? lastSyncedAt,
    int? pendingOperationCount,
  }) {
    return ShoppingListState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      lists: lists ?? this.lists,
      selectedListId: selectedListId ?? this.selectedListId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingOperationCount: pendingOperationCount ?? this.pendingOperationCount,
    );
  }

  ShoppingList? get selectedList {
    if (lists.isEmpty) return null;
    if (selectedListId == null) return lists.first;
    for (final list in lists) {
      if (list.id == selectedListId) return list;
    }
    return lists.first;
  }

  List<ShoppingItem> get selectedItems => selectedList?.items ?? const [];

  bool get hasPendingSync => pendingOperationCount > 0;
}

enum ShoppingOperationType {
  createList,
  renameList,
  deleteList,
  addItems,
  updateItem,
  deleteItem,
  toggleItem,
  clearChecked,
  mergeDuplicates,
}

const Map<ShoppingOperationType, String> _operationTypeToCodeMap = {
  ShoppingOperationType.createList: 'create_list',
  ShoppingOperationType.renameList: 'rename_list',
  ShoppingOperationType.deleteList: 'delete_list',
  ShoppingOperationType.addItems: 'add_items',
  ShoppingOperationType.updateItem: 'update_item',
  ShoppingOperationType.deleteItem: 'delete_item',
  ShoppingOperationType.toggleItem: 'toggle_item',
  ShoppingOperationType.clearChecked: 'clear_checked',
  ShoppingOperationType.mergeDuplicates: 'merge_duplicates',
};

final Map<String, ShoppingOperationType> _operationTypeFromCodeMap =
    _operationTypeToCodeMap.map((key, value) => MapEntry(value, key));

String _operationTypeToCode(ShoppingOperationType type) =>
    _operationTypeToCodeMap[type] ?? 'add_items';

ShoppingOperationType _operationTypeFromCode(String code) =>
    _operationTypeFromCodeMap[code] ?? ShoppingOperationType.addItems;

class PendingShoppingOperation {
  PendingShoppingOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final ShoppingOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': _operationTypeToCode(type),
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingShoppingOperation.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return PendingShoppingOperation(
      id: json['id']?.toString() ?? generateId(),
      type: _operationTypeFromCode(json['type']?.toString() ?? ''),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ShoppingListService {
  ShoppingListService._();

  static final ShoppingListService instance = ShoppingListService._();

  final ValueNotifier<ShoppingListState> stateNotifier =
      ValueNotifier<ShoppingListState>(ShoppingListState.initial());

  ShoppingListState get state => stateNotifier.value;

  final AuthService _authService = AuthService();
  final ShoppingListRemoteDataSource _remote =
      ShoppingListRemoteDataSource();

  final List<PendingShoppingOperation> _pendingOps =
      <PendingShoppingOperation>[];

  String _userKey = 'guest';
  bool _loaded = false;
  Future<void>? _loadFuture;
  bool _syncing = false;

  String get _stateStorageKey => '$_stateKeyPrefix::$_userKey';
  String get _pendingStorageKey => '$_pendingKeyPrefix::$_userKey';

  Future<void> ensureInitialized({bool forceReload = false}) async {
    final userKey = await _fetchUserKey();
    if (_userKey != userKey) {
      _userKey = userKey;
      _loaded = false;
      _loadFuture = null;
    }
    if (_loaded && !forceReload) return;
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> refreshForCurrentUser() => ensureInitialized(forceReload: true);

  Future<void> refreshFromServer() async {
    await ensureInitialized();
    if (!await _isAuthenticated()) return;
    if (_pendingOps.isNotEmpty) {
      await syncPending();
      if (_pendingOps.isNotEmpty) {
        return;
      }
    }

    _emitState(state.copyWith(isLoading: true));
    try {
      final remoteLists = await _remote.fetchLists();
      final sanitized = _sanitizeLists(remoteLists);
      String? selectedId = state.selectedListId;
      if (selectedId == null ||
          !sanitized.any((list) => list.id == selectedId)) {
        selectedId = sanitized.isNotEmpty ? sanitized.first.id : null;
      }
      _emitState(state.copyWith(
        isLoading: false,
        lists: sanitized,
        selectedListId: selectedId,
        lastSyncedAt: DateTime.now(),
      ));
      await _persistState();
    } on ShoppingListRemoteException {
      _emitState(state.copyWith(isLoading: false));
      rethrow;
    } catch (_) {
      _emitState(state.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<String> createList(String name) async {
    await ensureInitialized();
    final normalized = name.trim().isEmpty ? 'Danh sách mới' : name.trim();
    final now = DateTime.now();
    final list = ShoppingList(
      id: generateId(),
      ownerId: _userKey,
      name: normalized,
      items: const [],
      createdAt: now,
      updatedAt: now,
    );
    _applyRemoteList(list, select: true);
    await _persistState();

    final remoteSuccess = await _attemptRemote(() async {
      final remoteList = await _remote.createList(normalized, id: list.id);
      _applyRemoteList(remoteList, select: true);
      await _persistState();
    });

    if (!remoteSuccess) {
      await _enqueueOperation(ShoppingOperationType.createList, {
        'id': list.id,
        'name': normalized,
      });
    }
    return list.id;
  }

  Future<void> renameList(String listId, String name) async {
    await ensureInitialized();
    final trimmed = name.trim();
    final lists = state.lists.toList();
    final index = lists.indexWhere((list) => list.id == listId);
    if (index < 0) return;
    final updated = lists[index]
        .copyWith(name: trimmed.isEmpty ? lists[index].name : trimmed);
    lists[index] = updated;
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final success = await _attemptRemote(() async {
      await _remote.renameList(listId, updated.name);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.renameList, {
        'id': listId,
        'name': updated.name,
      });
    }
  }

  Future<void> deleteList(String listId) async {
    await ensureInitialized();
    final lists = state.lists.toList();
    final index = lists.indexWhere((list) => list.id == listId);
    if (index < 0) return;
    lists.removeAt(index);
    String? selectedId = state.selectedListId;
    if (selectedId == listId) {
      selectedId = lists.isNotEmpty ? lists.first.id : null;
    }
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
      selectedListId: selectedId,
    ));
    await _persistState();

    final success = await _attemptRemote(() async {
      await _remote.deleteList(listId);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.deleteList, {
        'id': listId,
      });
    }
  }

  Future<void> setSelectedList(String listId) async {
    await ensureInitialized();
    if (state.selectedListId == listId) return;
    if (!state.lists.any((list) => list.id == listId)) return;
    _emitState(state.copyWith(selectedListId: listId));
    await _persistState();
  }

  Future<void> addManualItem(
    String listId, {
    required String name,
    String? quantity,
    String? unit,
    String? note,
    String? recipeId,
    String? recipeTitle,
  }) async {
    await ensureInitialized();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final item = ShoppingItem(
      id: generateId(),
      shoppingListId: listId,
      name: trimmedName,
      quantity: quantity?.trim().isEmpty == true ? null : quantity?.trim(),
      quantityValue: QuantityUtils.parse(quantity),
      unit: unit?.trim().isEmpty == true ? null : unit?.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      checked: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _addItems(listId, [item]);
  }

  Future<void> addRecipeToList(
      String listId, Recipe recipe, double targetServings) async {
    await ensureInitialized();
    final baseServings = recipe.servings <= 0 ? 1 : recipe.servings;
    final ratio = targetServings <= 0
        ? 1.0
        : targetServings / (baseServings.toDouble());
    final now = DateTime.now();
    final items = recipe.ingredients
        .map((ingredient) => ShoppingItem.fromIngredient(
              ingredient,
              shoppingListId: listId,
              ratio: ratio,
              recipeTitle: recipe.title,
            ).copyWith(
              recipeId: recipe.id,
              createdAt: now,
              updatedAt: now,
            ))
        .toList();
    await _addItems(listId, items, metadata: {
      'recipeId': recipe.id,
      'recipeTitle': recipe.title,
      'servings': targetServings,
    });
  }

  Future<void> toggleChecked(String listId, String itemId) async {
    await ensureInitialized();
    final lists = state.lists.toList();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) return;
    final items = lists[listIndex].items.toList();
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) return;
    final toggled = items[itemIndex].copyWith(
      checked: !items[itemIndex].checked,
      updatedAt: DateTime.now(),
    );
    items[itemIndex] = toggled;
    lists[listIndex] = lists[listIndex]
        .copyWith(items: List<ShoppingItem>.unmodifiable(items));
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final success = await _attemptRemote(() async {
      await _remote.setChecked(itemId, toggled.checked);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.toggleItem, {
        'itemId': itemId,
        'listId': listId,
        'isChecked': toggled.checked,
      });
    }
  }

  Future<void> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    String? unit,
    String? note,
  }) async {
    await ensureInitialized();
    final listIndex = state.lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) return;
    final lists = state.lists.toList();
    final items = lists[listIndex].items.toList();
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) return;

    final trimmedName = name?.trim();
    final trimmedQuantity = quantity?.trim();
    final trimmedUnit = unit?.trim();
    final trimmedNote = note?.trim();

    final updatedQuantityValue = trimmedQuantity != null
        ? QuantityUtils.parse(trimmedQuantity)
        : items[itemIndex].quantityValue;

    final updatedItem = items[itemIndex].copyWith(
      name: trimmedName?.isNotEmpty == true ? trimmedName : null,
    quantity: trimmedQuantity != null && trimmedQuantity.isNotEmpty
      ? trimmedQuantity
      : null,
    quantityCleared: trimmedQuantity != null && trimmedQuantity.isEmpty,
    quantityValueCleared:
      trimmedQuantity != null && trimmedQuantity.isEmpty,
      quantityValue: updatedQuantityValue,
    unit: trimmedUnit != null && trimmedUnit.isNotEmpty
      ? trimmedUnit
      : null,
    unitCleared: trimmedUnit != null && trimmedUnit.isEmpty,
      noteCleared: trimmedNote != null && trimmedNote.isEmpty,
      note: trimmedNote?.isNotEmpty == true ? trimmedNote : null,
      checked: false,
      updatedAt: DateTime.now(),
    );

    items[itemIndex] = updatedItem;
    lists[listIndex] = lists[listIndex]
        .copyWith(items: List<ShoppingItem>.unmodifiable(items));
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final changes = <String, dynamic>{};
    if (trimmedName != null) {
      changes['ingredientName'] =
          trimmedName.isEmpty ? updatedItem.name : trimmedName;
    }
    if (trimmedQuantity != null) {
      changes['quantity'] =
          trimmedQuantity.isEmpty ? null : updatedItem.quantity;
    }
    if (trimmedUnit != null) {
      changes['unit'] = trimmedUnit.isEmpty ? null : trimmedUnit;
    }
    if (trimmedNote != null) {
      changes['note'] = trimmedNote.isEmpty ? null : trimmedNote;
    }

    if (changes.isEmpty) return;

    final success = await _attemptRemote(() async {
      await _remote.updateItem(itemId, changes);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.updateItem, {
        'itemId': itemId,
        'listId': listId,
        'changes': changes,
      });
    }
  }

  Future<void> removeItem(String listId, String itemId) async {
    await ensureInitialized();
    final lists = state.lists.toList();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) return;
    final items = lists[listIndex].items
        .where((item) => item.id != itemId)
        .toList();
    lists[listIndex] = lists[listIndex]
        .copyWith(items: List<ShoppingItem>.unmodifiable(items));
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final success = await _attemptRemote(() async {
      await _remote.deleteItem(itemId);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.deleteItem, {
        'itemId': itemId,
        'listId': listId,
      });
    }
  }

  Future<void> clearChecked(String listId) async {
    await ensureInitialized();
    final lists = state.lists.toList();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) return;
    final items = lists[listIndex]
        .items
        .where((item) => item.checked != true)
        .toList();
    lists[listIndex] = lists[listIndex]
        .copyWith(items: List<ShoppingItem>.unmodifiable(items));
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final success = await _attemptRemote(() async {
      await _remote.clearChecked(listId);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.clearChecked, {
        'listId': listId,
      });
    }
  }

  Future<void> mergeDuplicates(String listId) async {
    await ensureInitialized();
    final lists = state.lists.toList();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) return;
    final merged = _mergeItems(const <ShoppingItem>[], lists[listIndex].items);
    lists[listIndex] = lists[listIndex]
        .copyWith(items: List<ShoppingItem>.unmodifiable(merged));
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final success = await _attemptRemote(() async {
      await _remote.mergeDuplicates(listId);
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.mergeDuplicates, {
        'listId': listId,
      });
    }
  }

  Future<void> syncPending() async {
    await ensureInitialized();
    if (_pendingOps.isEmpty) return;
    if (!await _isAuthenticated()) return;
    if (_syncing) return;
    _syncing = true;
    _emitState(state.copyWith(isSyncing: true));
    try {
      while (_pendingOps.isNotEmpty) {
        final op = _pendingOps.first;
        await _executeRemote(op);
        _pendingOps.removeAt(0);
        await _persistPendingOps();
        _emitState(state.copyWith(
          pendingOperationCount: _pendingOps.length,
        ));
      }
      _emitState(state.copyWith(lastSyncedAt: DateTime.now()));
      await _persistState();
    } finally {
      _syncing = false;
      _emitState(state.copyWith(isSyncing: false));
    }
  }

  Future<String> _fetchUserKey() async {
    try {
      final user = await _authService.getUser();
      return user?.id ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  Future<void> _load() async {
    _emitState(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      await _maybeMigrateLegacy(prefs);

      List<ShoppingList> lists = <ShoppingList>[];
      String? selectedListId;
      DateTime? lastSyncedAt;

      final raw = prefs.getString(_stateStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final rawLists = data['lists'];
          if (rawLists is List) {
            lists = rawLists
                .whereType<Map>()
                .map((entry) => ShoppingList.fromJson(
                    Map<String, dynamic>.from(entry)))
                .toList();
          }
          final selectedRaw = data['selectedListId'];
          if (selectedRaw != null) {
            selectedListId = selectedRaw.toString();
          }
          final syncRaw = data['lastSyncedAt'];
          if (syncRaw != null && syncRaw.toString().isNotEmpty) {
            lastSyncedAt = DateTime.tryParse(syncRaw.toString());
          }
        }
      }

      _pendingOps.clear();
      final pendingRaw = prefs.getString(_pendingStorageKey);
      if (pendingRaw != null && pendingRaw.isNotEmpty) {
        final pendingData = jsonDecode(pendingRaw);
        if (pendingData is List) {
          for (final entry in pendingData) {
            if (entry is Map) {
              _pendingOps.add(PendingShoppingOperation.fromJson(
                  Map<String, dynamic>.from(entry)));
            }
          }
        }
      }

      final sanitized = _sanitizeLists(lists);
      if (selectedListId == null ||
          !sanitized.any((list) => list.id == selectedListId)) {
        selectedListId = sanitized.isNotEmpty ? sanitized.first.id : null;
      }

      _emitState(state.copyWith(
        isLoading: false,
        lists: sanitized,
        selectedListId: selectedListId,
        lastSyncedAt: lastSyncedAt,
        pendingOperationCount: _pendingOps.length,
      ));
    } finally {
      _loaded = true;
      _loadFuture = null;
    }
  }

  Future<void> _maybeMigrateLegacy(SharedPreferences prefs) async {
    final legacy = prefs.getStringList(_legacyItemsKey);
    if (legacy == null || legacy.isEmpty) return;
    final now = DateTime.now();
    final listId = generateId();
    final items = legacy
        .map((entry) {
          try {
            final decoded = jsonDecode(entry);
            if (decoded is Map<String, dynamic>) {
              return ShoppingItem.fromJson(decoded).copyWith(
                shoppingListId: listId,
                createdAt: now,
                updatedAt: now,
              );
            }
          } catch (_) {
            return null;
          }
          return null;
        })
        .whereType<ShoppingItem>()
        .toList();

    final list = ShoppingList(
      id: listId,
      ownerId: _userKey,
      name: 'Danh sách của tôi',
      items: items,
      createdAt: now,
      updatedAt: now,
    );

    final payload = jsonEncode({
      'lists': [list.toJson()],
      'selectedListId': listId,
      'lastSyncedAt': now.toIso8601String(),
    });

    await prefs.setString(_stateStorageKey, payload);
    await prefs.remove(_legacyItemsKey);
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'lists': state.lists.map((list) => list.toJson()).toList(),
      'selectedListId': state.selectedListId,
      'lastSyncedAt': state.lastSyncedAt?.toIso8601String(),
    };
    await prefs.setString(_stateStorageKey, jsonEncode(data));
  }

  Future<void> _persistPendingOps() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _pendingOps.map((op) => op.toJson()).toList();
    await prefs.setString(_pendingStorageKey, jsonEncode(data));
  }

  void _emitState(ShoppingListState newState) {
    stateNotifier.value = newState;
  }

  List<ShoppingList> _sanitizeLists(List<ShoppingList> lists) {
    return List<ShoppingList>.unmodifiable(lists.map((list) {
      final items = list.items
          .map((item) => item.shoppingListId.isEmpty
              ? item.copyWith(shoppingListId: list.id)
              : item)
          .toList();
      return list.withItems(List<ShoppingItem>.unmodifiable(items));
    }));
  }

  Future<bool> _attemptRemote(Future<void> Function() action) async {
    if (!await _isAuthenticated()) return false;
    try {
      await action();
      return true;
    } on ShoppingListRemoteException catch (error) {
      if (_shouldIgnoreRemoteError(error)) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  bool _shouldIgnoreRemoteError(Object error) {
    if (error is! ShoppingListRemoteException) return false;
    final code = error.statusCode ?? 0;
    if (code == 404 || code == 410) return true;
    if (code == 400) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid item id') ||
          message.contains('item not found') ||
          message.contains('invalid list id')) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isAuthenticated() async {
    try {
      return await _authService.isLoggedIn();
    } catch (_) {
      return false;
    }
  }

  Future<void> _enqueueOperation(
    ShoppingOperationType type,
    Map<String, dynamic> payload,
  ) async {
    final operation = PendingShoppingOperation(
      id: generateId(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    _pendingOps.add(operation);
    _emitState(state.copyWith(pendingOperationCount: _pendingOps.length));
    await _persistPendingOps();
  }

  Future<void> _addItems(
    String listId,
    List<ShoppingItem> items, {
    Map<String, dynamic>? metadata,
  }) async {
    if (items.isEmpty) return;
    final lists = state.lists.toList();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex < 0) return;

    final prepared = items.map((item) => _prepareNewItem(item, listId)).toList();
    final updatedItems = _mergeItems(lists[listIndex].items, prepared);
    lists[listIndex] = lists[listIndex]
        .copyWith(items: List<ShoppingItem>.unmodifiable(updatedItems));

    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
    ));
    await _persistState();

    final payload = {
      'listId': listId,
      'items': prepared.map((item) => item.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };

    final success = await _attemptRemote(() async {
      final remoteList = await _remote.bulkAddItems(listId, prepared);
      if (remoteList != null) {
        _applyRemoteList(remoteList,
            select: state.selectedListId == listId);
        await _persistState();
      }
    });

    if (!success) {
      await _enqueueOperation(ShoppingOperationType.addItems, payload);
    }
  }

  ShoppingItem _prepareNewItem(ShoppingItem item, String listId) {
    final now = DateTime.now();
    final quantityValue =
        item.quantityValue ?? QuantityUtils.parse(item.quantity);
    return item.copyWith(
      id: item.id.isNotEmpty ? item.id : generateId(),
      shoppingListId: listId,
      quantityValue: quantityValue,
      checked: false,
      createdAt: item.createdAt ?? now,
      updatedAt: now,
    );
  }

  List<ShoppingItem> _mergeItems(
    List<ShoppingItem> existing,
    List<ShoppingItem> incoming,
  ) {
    final result = existing.toList();
    for (final item in incoming) {
      final index = result.indexWhere((element) => element.mergeKey == item.mergeKey);
      if (index >= 0) {
        result[index] = _mergeItem(result[index], item);
      } else {
        result.add(item);
      }
    }
    return result;
  }

  ShoppingItem _mergeItem(ShoppingItem base, ShoppingItem incoming) {
    double? mergedValue;
    if (base.quantityValue != null || incoming.quantityValue != null) {
      final baseValue = base.quantityValue ?? QuantityUtils.parse(base.quantity) ?? 0;
      final incomingValue =
          incoming.quantityValue ?? QuantityUtils.parse(incoming.quantity) ?? 0;
      mergedValue = baseValue + incomingValue;
    }
    final mergedQuantity = mergedValue != null
        ? QuantityUtils.format(mergedValue)
        : QuantityUtils.mergeDisplay(base.quantity, incoming.quantity);

    return base.copyWith(
      quantity: mergedQuantity,
      quantityValue: mergedValue ?? base.quantityValue,
      unit: base.unit ?? incoming.unit,
      checked: false,
      note: (base.note != null && base.note!.isNotEmpty)
          ? base.note
          : incoming.note,
      recipeId: base.recipeId ?? incoming.recipeId,
      recipeTitle: base.recipeTitle ?? incoming.recipeTitle,
      updatedAt: DateTime.now(),
    );
  }

  void _applyRemoteList(ShoppingList list, {bool select = false}) {
    final sanitized = list.withItems(List<ShoppingItem>.unmodifiable(
        list.items.map((item) => item.copyWith(shoppingListId: list.id))));
    final lists = state.lists.toList();
    final index = lists.indexWhere((element) => element.id == sanitized.id);
    if (index >= 0) {
      lists[index] = sanitized;
    } else {
      // Thêm danh sách mới vào đầu thay vì cuối
      lists.insert(0, sanitized);
    }
    _emitState(state.copyWith(
      lists: List<ShoppingList>.unmodifiable(lists),
      selectedListId: select ? sanitized.id : state.selectedListId,
    ));
  }

  Future<void> _executeRemote(PendingShoppingOperation op) async {
    switch (op.type) {
      case ShoppingOperationType.createList:
        final name = op.payload['name']?.toString() ?? 'Danh sách mới';
        final id = op.payload['id']?.toString();
        final remoteList = await _remote.createList(name, id: id);
        _applyRemoteList(remoteList, select: state.selectedListId == id);
        await _persistState();
        break;
      case ShoppingOperationType.renameList:
        final id = op.payload['id']?.toString();
        final name = op.payload['name']?.toString();
        if (id != null && name != null) {
          try {
            await _remote.renameList(id, name);
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
      case ShoppingOperationType.deleteList:
        final id = op.payload['id']?.toString();
        if (id != null) {
          try {
            await _remote.deleteList(id);
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
      case ShoppingOperationType.addItems:
        final listId = op.payload['listId']?.toString();
        if (listId == null) break;
        final itemsPayload = op.payload['items'];
        if (itemsPayload is List) {
          final items = itemsPayload
              .whereType<Map>()
              .map((entry) => ShoppingItem.fromJson(
                  Map<String, dynamic>.from(entry)))
              .toList();
          final remoteList = await _remote.bulkAddItems(listId, items);
          if (remoteList != null) {
            _applyRemoteList(remoteList,
                select: state.selectedListId == listId);
            await _persistState();
          }
        }
        break;
      case ShoppingOperationType.updateItem:
        final itemId = op.payload['itemId']?.toString();
        final changes = op.payload['changes'];
        if (itemId != null && changes is Map) {
          try {
            await _remote.updateItem(
                itemId, Map<String, dynamic>.from(changes));
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
      case ShoppingOperationType.deleteItem:
        final itemId = op.payload['itemId']?.toString();
        if (itemId != null) {
          try {
            await _remote.deleteItem(itemId);
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
      case ShoppingOperationType.toggleItem:
        final itemId = op.payload['itemId']?.toString();
        final isChecked = op.payload['isChecked'] == true;
        if (itemId != null) {
          try {
            await _remote.setChecked(itemId, isChecked);
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
      case ShoppingOperationType.clearChecked:
        final listId = op.payload['listId']?.toString();
        if (listId != null) {
          try {
            await _remote.clearChecked(listId);
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
      case ShoppingOperationType.mergeDuplicates:
        final listId = op.payload['listId']?.toString();
        if (listId != null) {
          try {
            await _remote.mergeDuplicates(listId);
          } on ShoppingListRemoteException catch (error) {
            if (!_shouldIgnoreRemoteError(error)) rethrow;
          }
        }
        break;
    }
  }
}
