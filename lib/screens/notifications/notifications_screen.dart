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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _changeFilter(String status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    _loadNotifications(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _meta?.unreadCount ?? 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Đánh dấu tất cả đã đọc',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.done_all_rounded,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _statusFilter == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? AppTheme.primaryOrange : AppTheme.textLight,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppTheme.primaryOrange : AppTheme.textDark,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppTheme.primaryOrange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            isSelected: _statusFilter == 'all',
            onTap: () => _changeFilter('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Chưa đọc',
            isSelected: _statusFilter == 'unread',
            onTap: () => _changeFilter('unread'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Đã đọc',
            isSelected: _statusFilter == 'read',
            onTap: () => _changeFilter('read'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_hasError && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Không thể tải thông báo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadNotifications(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
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
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightCream.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: AppTheme.primaryOrange.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có thông báo nào',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các thông báo của bạn sẽ xuất hiện ở đây',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryOrange),
              ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange
              : const Color.fromARGB(208, 221, 240, 232),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
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

  Map<String, dynamic> _resolveIconData() {
    switch (notification.type) {
      case 'recipe':
        return {
          'icon': Icons.restaurant_menu_rounded,
          'color': AppTheme.primaryOrange,
        };
      case 'social':
        return {
          'icon': Icons.group_rounded,
          'color': const Color(0xFF2196F3),
        };
      case 'reminder':
        return {
          'icon': Icons.alarm_rounded,
          'color': const Color(0xFF9C27B0),
        };
      default:
        return {
          'icon': Icons.notifications_rounded,
          'color': AppTheme.accentGreen,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _resolveIconData();
    final iconColor = iconData['color'] as Color;
    final icon = iconData['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: notification.isRead
            ? null
            : Border.all(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                width: 2,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(notification.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const Spacer(),
                          if (!notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Mới',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
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