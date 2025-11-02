import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/app_notification.dart';

class NotificationSummary {
  final int totalCount;
  final int unreadCount;
  final String? latestNotificationId;
  final DateTime? latestCreatedAt;

  const NotificationSummary({
    required this.totalCount,
    required this.unreadCount,
    this.latestNotificationId,
    this.latestCreatedAt,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: false);
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return NotificationSummary(
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      latestNotificationId: data['latestNotificationId']?.toString(),
      latestCreatedAt: parseDate(data['latestCreatedAt']),
    );
  }
}

class NotificationPage {
  final List<AppNotification> items;
  final NotificationMeta meta;

  const NotificationPage({
    required this.items,
    required this.meta,
  });
}

class NotificationApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/notifications';
  static const String _tokenKey = 'auth_token';

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _buildUri({
    Map<String, String>? query,
    String? pathSuffix,
  }) {
    final uri = Uri.parse(_baseUrl);
    if (pathSuffix != null && pathSuffix.isNotEmpty) {
      return uri.replace(path: '${uri.path}/$pathSuffix');
    }
    return uri.replace(queryParameters: query);
  }

  static Future<NotificationPage> getNotifications({
    String status = 'all',
    int page = 1,
    int limit = 20,
    DateTime? before,
    DateTime? after,
  }) async {
    final params = <String, String>{
      'status': status,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (before != null) {
      params['before'] = before.toIso8601String();
    }
    if (after != null) {
      params['after'] = after.toIso8601String();
    }

    final response = await http.get(
      _buildUri(query: params),
      headers: await _authHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load notifications (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    final data = payload['data'] as List<dynamic>? ?? const [];
    final meta = NotificationMeta.fromJson(
        payload['meta'] as Map<String, dynamic>? ?? const {});

    final items = data
        .map((item) => AppNotification.fromJson(
            item as Map<String, dynamic>? ?? const {}))
        .toList();

    return NotificationPage(items: items, meta: meta);
  }

  static Future<NotificationSummary> getSummary() async {
    final response = await http.get(
      _buildUri(pathSuffix: 'summary'),
      headers: await _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load notification summary (${response.statusCode})');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    return NotificationSummary.fromJson(
        payload['data'] as Map<String, dynamic>? ?? const {});
  }

  static Future<AppNotification> markAsRead(String id) async {
    final response = await http.patch(
      _buildUri(pathSuffix: '$id/read'),
      headers: await _authHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to mark notification as read (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    return AppNotification.fromJson(
        payload['data'] as Map<String, dynamic>? ?? const {});
  }

  static Future<void> markAllAsRead() async {
    final response = await http.patch(
      _buildUri(pathSuffix: 'read-all'),
      headers: await _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to mark all notifications as read (${response.statusCode})');
    }
  }

  static Future<void> deleteNotification(String id) async {
    final response = await http.delete(
      _buildUri(pathSuffix: id),
      headers: await _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete notification (${response.statusCode})');
    }
  }

  static Future<AppNotification> createNotification({
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? imageUrl,
    DateTime? expiresAt,
  }) async {
    final body = {
      'title': title,
      'message': message,
      'type': type,
      if (metadata != null) 'metadata': metadata,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
    };

    final response = await http.post(
      _buildUri(),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create notification (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    return AppNotification.fromJson(
        payload['data'] as Map<String, dynamic>? ?? const {});
  }

  static Future<void> registerToken({
    required String token,
    String platform = 'unknown',
    String? deviceName,
  }) async {
    final body = <String, dynamic>{
      'token': token,
      'platform': platform,
      if (deviceName != null && deviceName.isNotEmpty) 'deviceName': deviceName,
    };

    final response = await http.post(
      _buildUri(pathSuffix: 'tokens'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to register FCM token (${response.statusCode})');
    }
  }

  static Future<void> unregisterToken(String token) async {
    final encoded = Uri.encodeComponent(token);
    final response = await http.delete(
      _buildUri(pathSuffix: 'tokens/$encoded'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 404) {
      return;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to unregister FCM token (${response.statusCode})');
    }
  }
}
