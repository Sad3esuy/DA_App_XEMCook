class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> metadata;
  final String? actionUrl;
  final String? imageUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.actionUrl,
    this.imageUrl,
    this.readAt,
    this.expiresAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parseMetadata(dynamic value) {
      if (value == null) return const {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, dynamic val) => MapEntry(key.toString(), val));
      }
      return const {};
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: false);
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      metadata: parseMetadata(json['metadata']),
      actionUrl: json['actionUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isRead: json['isRead'] == true,
      readAt: parseDate(json['readAt']),
      expiresAt: parseDate(json['expiresAt']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'metadata': metadata,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? imageUrl,
    bool? isRead,
    DateTime? readAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class NotificationMeta {
  final int total;
  final int page;
  final int limit;
  final int unreadCount;
  final bool hasMore;

  const NotificationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.unreadCount,
    required this.hasMore,
  });

  factory NotificationMeta.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return NotificationMeta(
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? 1,
      limit: (data['limit'] as num?)?.toInt() ?? 20,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      hasMore: data['hasMore'] == true,
    );
  }

  NotificationMeta copyWith({
    int? total,
    int? page,
    int? limit,
    int? unreadCount,
    bool? hasMore,
  }) {
    return NotificationMeta(
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
