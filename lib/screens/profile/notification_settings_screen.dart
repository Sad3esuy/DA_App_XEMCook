import 'package:flutter/material.dart';

import '../../model/notification_settings.dart';
import '../../services/notification_api_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  NotificationSettings? _settings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await NotificationApiService.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _updateSetting({
    bool? pushRecipe,
    bool? pushSocial,
    bool? pushReminder,
    bool? pushSystem,
  }) async {
    if (_settings == null) return;
    final previous = _settings;

    NotificationSettings optimistic = _settings!;
    if (pushRecipe != null) optimistic = optimistic.copyWith(pushRecipe: pushRecipe);
    if (pushSocial != null) optimistic = optimistic.copyWith(pushSocial: pushSocial);
    if (pushReminder != null) optimistic = optimistic.copyWith(pushReminder: pushReminder);
    if (pushSystem != null) optimistic = optimistic.copyWith(pushSystem: pushSystem);

    setState(() {
      _settings = optimistic;
      _isProcessing = true;
    });

    try {
      final updated = await NotificationApiService.updateSettings(
        pushRecipe: pushRecipe,
        pushSocial: pushSocial,
        pushReminder: pushReminder,
        pushSystem: pushSystem,
      );
      if (!mounted) return;
      setState(() {
        _settings = updated;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật cài đặt: $error'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSettings,
                child: const Text('Thử lại'),
              )
            ],
          ),
        ),
      );
    }

    final settings = _settings!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý loại thông báo bạn muốn nhận',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            title: 'Cập nhật công thức',
            subtitle: 'Thông báo khi có hoạt động liên quan đến công thức của bạn',
            value: settings.pushRecipe,
            onChanged: (value) => _updateSetting(pushRecipe: value),
          ),
          _buildSettingTile(
            title: 'Hoạt động cộng đồng',
            subtitle: 'Thông báo khi có tương tác xã hội, theo dõi, bình luận',
            value: settings.pushSocial,
            onChanged: (value) => _updateSetting(pushSocial: value),
          ),
          _buildSettingTile(
            title: 'Nhắc nhở & gợi ý',
            subtitle: 'Nhắc nhở chế biến món ăn, góp ý thực đơn',
            value: settings.pushReminder,
            onChanged: (value) => _updateSetting(pushReminder: value),
          ),
          _buildSettingTile(
            title: 'Thông báo hệ thống',
            subtitle: 'Tin tức, cập nhật tính năng từ XEMCook',
            value: settings.pushSystem,
            onChanged: (value) => _updateSetting(pushSystem: value),
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Đang đồng bộ...'),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        value: value,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
        onChanged: (val) {
          onChanged(val);
        },
        activeColor: AppTheme.primaryOrange,
      ),
    );
  }
}
