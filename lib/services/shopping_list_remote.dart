import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/shopping_item.dart';
import '../model/shopping_list.dart';
import 'auth_service.dart';

class ShoppingListRemoteException implements Exception {
  ShoppingListRemoteException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ShoppingListRemoteException(statusCode: $statusCode, message: $message)';
}

class ShoppingListRemoteDataSource {
  ShoppingListRemoteDataSource();

  final AuthService _authService = AuthService();
  static const String _endpoint =
      '${AuthService.baseUrl}/recipes/shopping-lists';
  static const Duration _timeout = Duration(seconds: 15);

  Future<List<ShoppingList>> fetchLists() async {
    final headers = await _headers();
    final response = await _send(() =>
        http.get(Uri.parse(_endpoint), headers: headers).timeout(
              _timeout,
            ));
    final body = _decode(response);
    final data = body['data'];
    if (data is List) {
      return data
          .map((entry) => ShoppingList.fromJson(
              Map<String, dynamic>.from(entry as Map)))
          .toList(growable: false);
    }
    return const [];
  }

  Future<ShoppingList> createList(String name, {String? id}) async {
    final payload = <String, dynamic>{'name': name};
    if (id != null) payload['id'] = id;
  final headers = await _headers();
  final response = await _send(() => http
    .post(Uri.parse(_endpoint), headers: headers, body: jsonEncode(payload))
    .timeout(_timeout));
    final body = _decode(response);
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return ShoppingList.fromJson(data);
    }
    throw ShoppingListRemoteException('Không nhận được dữ liệu danh sách');
  }

  Future<void> renameList(String id, String name) async {
  final headers = await _headers();
  await _send(() => http
    .put(Uri.parse('$_endpoint/$id'),
      headers: headers, body: jsonEncode({'name': name}))
    .timeout(_timeout));
  }

  Future<void> deleteList(String id) async {
  final headers = await _headers();
  await _send(() => http
    .delete(Uri.parse('$_endpoint/$id'), headers: headers)
    .timeout(_timeout));
  }

  Future<ShoppingList?> bulkAddItems(
      String listId, List<ShoppingItem> items) async {
    final headers = await _headers();
    final response = await _send(() => http
        .post(Uri.parse('$_endpoint/$listId/items/bulk'),
            headers: headers,
            body: jsonEncode({
              'items': items.map((item) => item.toRemotePayload()).toList(),
            }))
        .timeout(_timeout));
    final body = _decode(response);
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final listPayload = data['list'];
      if (listPayload is Map<String, dynamic>) {
        return ShoppingList.fromJson(listPayload);
      }
    }
    return null;
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> payload) async {
  final headers = await _headers();
  await _send(() => http
    .put(Uri.parse('$_endpoint/items/$itemId'),
      headers: headers, body: jsonEncode(payload))
    .timeout(_timeout));
  }

  Future<void> deleteItem(String itemId) async {
  final headers = await _headers();
  await _send(() => http
    .delete(Uri.parse('$_endpoint/items/$itemId'), headers: headers)
    .timeout(_timeout));
  }

  Future<void> setChecked(String itemId, bool isChecked) async {
    await updateItem(itemId, {'isChecked': isChecked});
  }

  Future<void> clearChecked(String listId) async {
  final headers = await _headers();
  await _send(() => http
    .post(Uri.parse('$_endpoint/$listId/clear-checked'), headers: headers)
    .timeout(_timeout));
  }

  Future<void> mergeDuplicates(String listId) async {
  final headers = await _headers();
  await _send(() => http
    .post(Uri.parse('$_endpoint/$listId/merge-duplicates'),
      headers: headers)
    .timeout(_timeout));
  }

  Future<http.Response> _send(
      Future<http.Response> Function() requestBuilder) async {
    final response = await requestBuilder();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    final body = _tryDecode(response.body);
    final message = body['message']?.toString() ?? 'Yêu cầu thất bại';
    throw ShoppingListRemoteException(message, statusCode: response.statusCode);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = _tryDecode(response.body);
    if (body['success'] == false) {
      throw ShoppingListRemoteException(
        body['message']?.toString() ?? 'Yêu cầu thất bại',
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Map<String, dynamic> _tryDecode(String source) {
    if (source.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }
}
