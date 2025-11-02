import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/app_notification.dart';
import '../../services/notification_api_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [];
  final ScrollController _scrollController = ScrollController();

  NotificationMeta? _meta;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    if (_isLoadingMore || (_isLoading && !reset)) return;
    final int nextPage;
    if (reset) {
      nextPage = 1;
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    } else {
      nextPage = (_meta?.page ?? 1) + 1;
      if (!(_meta?.hasMore ?? false)) {
        return;
      }
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await NotificationApiService.getNotifications(
        status: _statusFilter,
        page: nextPage,
        limit: 20,
      );

      setState(() {
        if (reset) {
          _notifications
            ..clear()
            ..addAll(response.items);
        } else {
          _notifications.addAll(response.items);
        }
        _meta = response.meta;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          if (reset) {
            _isLoading = false;
          }
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 160 &&
        !_isLoadingMore &&
        (_meta?.hasMore ?? false)) {
      _loadNotifications(reset: false);
    }
  }

  Future<void> _refresh() => _loadNotifications(reset: true);

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      final updated = await NotificationApiService.markAsRead(notification.id);
      final index = _notifications.indexWhere((item) => item.id == notification.id);
      if (index >= 0) {
        setState(() {
          _notifications[index] = updated;
          if (_meta != null) {
            final updatedUnread =
                math.max(0, _meta!.unreadCount - 1);
            _meta = _meta!.copyWith(unreadCount: updatedUnread);
          }
        });
      }
    } catch (error) {
      _showErrorSnackBar('Không thể cập nhật thông báo: $error');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationApiService.markAllAsRead();
      setState(() {
        for (var i = 0; i < _notifications.length; i += 1) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        if (_meta != null) {
          _meta = _meta!.copyWith(unreadCount: 0);
        }
      });
      _showSnackBar('Đã đánh dấu tất cả thông báo là đã đọc');
    } catch (error) {
      _showErrorSnackBar('Không thể cập nhật thông báo: $error');
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await NotificationApiService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((item) => item.id == notification.id);
        if (_meta != null) {
          final updatedTotal = math.max(0, _meta!.total - 1);
          final updatedUnread = notification.isRead
              ? _meta!.unreadCount
              : math.max(0, _meta!.unreadCount - 1);
          _meta = _meta!.copyWith(
            total: updatedTotal,
            unreadCount: updatedUnread,
          );
        }
      });
      _showSnackBar('Đã xóa thông báo');
    } catch (error) {
      _showErrorSnackBar('Không thể xóa thông báo: $error');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _changeFilter(String status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    _loadNotifications(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if ((_meta?.unreadCount ?? 0) > 0)
            IconButton(
              tooltip: 'Đánh dấu tất cả đã đọc',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: _markAllAsRead,
            ),
          PopupMenuButton<String>(
            initialValue: _statusFilter,
            onSelected: _changeFilter,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'all',
                child: Text('Tất cả'),
              ),
              PopupMenuItem(
                value: 'unread',
                child: Text('Chưa đọc'),
              ),
              PopupMenuItem(
                value: 'read',
                child: Text('Đã đọc'),
              ),
            ],
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Không thể tải thông báo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadNotifications(reset: true),
                child: const Text('Thử lại'),
              )
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryOrange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Center(child: Text('Chưa có thông báo nào')),
            SizedBox(height: 120),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = _notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _markAsRead(notification),
            onDelete: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _resolveIcon() {
    switch (notification.type) {
      case 'recipe':
        return Icons.restaurant_menu_rounded;
      case 'social':
        return Icons.group_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = notification.isRead
        ? Colors.white
        : AppTheme.primaryOrange.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : AppTheme.primaryOrange.withOpacity(0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _resolveIcon(),
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: onDelete,
                            tooltip: 'Xóa thông báo',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimeAgo(notification.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          if (!notification.isRead)
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: const Text(
                                'Mới',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
