import 'package:flutter/material.dart';
import 'package:test_ui_app/theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Về Chúng Tôi'),
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange.withOpacity(0.1),
                        AppTheme.primaryOrange.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: 64,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Main Intro
              Center(
                child: Text(
                  'XEMCook',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chúng tôi tạo ra XEMCook để giúp bạn trở thành đầu bếp thông thái trong chính căn bếp của mình.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppTheme.textDark.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ứng dụng kết hợp công thức nấu ăn đa dạng, mẹo vặt hữu ích và các công cụ quản lý thông minh để biến việc nấu nướng hàng ngày trở nên đơn giản và thú vị hơn bao giờ hết.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppTheme.textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Info Blocks
              const _InfoBlock(
                icon: Icons.track_changes_rounded,
                title: 'Sứ Mệnh',
                description:
                    'Hỗ trợ bạn lên thực đơn linh hoạt, tìm công thức phù hợp và tiết kiệm tối đa thời gian trong bếp.',
                bulletPoints: [
                  'Khuyến khích lối sống ẩm thực lành mạnh',
                  'Tính toán nguyên liệu thông minh và chính xác',
                  'Tạo cảm hứng mỗi ngày cho mọi bữa ăn',
                  'Kết nối cộng đồng yêu nấu ăn',
                ],
              ),
              const _InfoBlock(
                icon: Icons.diamond_outlined,
                title: 'Giá Trị Cốt Lõi',
                description:
                    'Chúng tôi đặt người dùng làm trung tâm của mọi tính năng và quyết định phát triển.',
                bulletPoints: [
                  'Giao diện đơn giản, trực quan và dễ sử dụng',
                  'Nội dung tin cậy được kiểm duyệt kỹ lưỡng',
                  'Cập nhật liên tục từ góp ý cộng đồng',
                  'Minh bạch trong cách vận hành',
                ],
              ),
              const _InfoBlock(
                icon: Icons.groups_rounded,
                title: 'Đội Ngũ',
                description:
                    'Một tập thể nhỏ nhưng tràn đầy đam mê với công nghệ và ẩm thực. Chúng tôi luôn lắng nghe và không ngừng cải tiến để mang đến trải nghiệm tốt nhất.',
              ),
              _InfoBlock(
                icon: Icons.support_agent_rounded,
                title: 'Liên Hệ',
                description:
                    'Chúng tôi luôn sẵn sàng hỗ trợ và giải đáp mọi thắc mắc của bạn.',
                contactInfo: ContactInfo(
                  email: 'support@xemcook.com',
                  phone: '0123 456 789',
                  workingHours: 'Từ 9h đến 18h, Thứ 2 đến Thứ 6',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Footer
              Center(
                child: Text(
                  'Cảm ơn bạn đã tin tưởng XEMCook! 🧡',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactInfo {
  final String email;
  final String phone;
  final String workingHours;

  ContactInfo({
    required this.email,
    required this.phone,
    required this.workingHours,
  });
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String>? bulletPoints;
  final ContactInfo? contactInfo;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.description,
    this.bulletPoints,
    this.contactInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: AppTheme.textDark.withOpacity(0.8),
            ),
          ),
          if (bulletPoints != null) ...[
            const SizedBox(height: 16),
            ...bulletPoints!.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (contactInfo != null) ...[
            const SizedBox(height: 16),
            _ContactItem(
              icon: Icons.email_outlined,
              label: 'Email',
              value: contactInfo!.email,
            ),
            const SizedBox(height: 12),
            _ContactItem(
              icon: Icons.phone_outlined,
              label: 'Hotline',
              value: contactInfo!.phone,
            ),
            const SizedBox(height: 12),
            _ContactItem(
              icon: Icons.access_time_rounded,
              label: 'Thời gian hỗ trợ',
              value: contactInfo!.workingHours,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryOrange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textDark.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}