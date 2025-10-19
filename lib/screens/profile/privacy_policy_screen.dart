import 'package:flutter/material.dart';
import 'package:test_ui_app/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chính Sách Bảo Mật'),
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
              // Header Section
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 56,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Center(
                child: Text(
                  'Cam kết bảo mật thông tin',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'XEMCook cam kết bảo vệ quyền riêng tư và dữ liệu cá nhân của bạn. Chúng tôi áp dụng các biện pháp bảo mật hiện đại để đảm bảo thông tin của bạn luôn an toàn.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppTheme.textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Last Updated
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cập nhật lần cuối: 19/10/2025',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Policy Blocks
              const _PolicyBlock(
                icon: Icons.description_outlined,
                title: 'Thông Tin Chung',
                description:
                    'XEMCook tôn trọng quyền riêng tư và cam kết bảo vệ dữ liệu cá nhân của người dùng. Chính sách này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ thông tin của bạn.',
              ),
              const _PolicyBlock(
                icon: Icons.storage_rounded,
                title: 'Dữ Liệu Thu Thập',
                description:
                    'Chúng tôi chỉ thu thập các thông tin cần thiết để cung cấp dịch vụ tốt nhất cho bạn:',
                bulletPoints: [
                  'Thông tin tài khoản: email, tên hiển thị, mật khẩu đã mã hóa',
                  'Hình ảnh đại diện do bạn tải lên',
                  'Danh sách công thức đã lưu và yêu thích',
                  'Nhật ký mua sắm và danh sách nguyên liệu',
                  'Số liệu sử dụng ứng dụng để cải thiện trải nghiệm',
                ],
              ),
              const _PolicyBlock(
                icon: Icons.track_changes_rounded,
                title: 'Mục Đích Sử Dụng',
                description:
                    'Dữ liệu của bạn được sử dụng để:',
                bulletPoints: [
                  'Đồng bộ công thức và dữ liệu giữa các thiết bị',
                  'Gợi ý công thức phù hợp với sở thích của bạn',
                  'Cải thiện tính năng và trải nghiệm người dùng',
                  'Hỗ trợ kỹ thuật khi bạn cần giúp đỡ',
                  'Gửi thông báo về cập nhật và tính năng mới (nếu bạn đồng ý)',
                ],
              ),
              const _PolicyBlock(
                icon: Icons.share_outlined,
                title: 'Chia Sẻ Với Bên Thứ Ba',
                description:
                    'XEMCook cam kết KHÔNG bán hoặc cho thuê dữ liệu cá nhân của bạn. Chúng tôi chỉ chia sẻ thông tin khi:',
                bulletPoints: [
                  'Có sự đồng ý rõ ràng từ bạn',
                  'Cần thiết để cung cấp dịch vụ (ví dụ: dịch vụ lưu trữ đám mây)',
                  'Tuân thủ yêu cầu pháp lý hoặc quy định của cơ quan chức năng',
                ],
              ),
              const _PolicyBlock(
                icon: Icons.verified_user_outlined,
                title: 'Quyền Của Người Dùng',
                description:
                    'Bạn có toàn quyền kiểm soát dữ liệu cá nhân của mình:',
                bulletPoints: [
                  'Xem và cập nhật thông tin trong trang hồ sơ bất kỳ lúc nào',
                  'Yêu cầu xuất dữ liệu cá nhân dưới dạng file',
                  'Yêu cầu xóa tài khoản và toàn bộ dữ liệu liên quan',
                  'Tắt thông báo và tùy chỉnh quyền riêng tư trong phần cài đặt',
                  'Từ chối cho phép thu thập dữ liệu không bắt buộc',
                ],
              ),
              const _PolicyBlock(
                icon: Icons.lock_outline,
                title: 'Bảo Mật Dữ Liệu',
                description:
                    'Chúng tôi áp dụng các biện pháp bảo mật hiện đại:',
                bulletPoints: [
                  'Mã hóa dữ liệu trong quá trình truyền tải (SSL/TLS)',
                  'Lưu trữ mật khẩu dưới dạng băm (hash) không thể đảo ngược',
                  'Kiểm tra bảo mật định kỳ và cập nhật hệ thống',
                  'Giới hạn quyền truy cập dữ liệu chỉ cho nhân viên cần thiết',
                  'Sao lưu dữ liệu thường xuyên để phòng ngừa mất mát',
                ],
              ),
              const _PolicyBlock(
                icon: Icons.cookie_outlined,
                title: 'Cookie và Công Nghệ Theo Dõi',
                description:
                    'XEMCook sử dụng cookie và công nghệ tương tự để:',
                bulletPoints: [
                  'Duy trì phiên đăng nhập của bạn',
                  'Ghi nhớ tùy chọn và cài đặt cá nhân',
                  'Phân tích cách sử dụng ứng dụng để cải thiện dịch vụ',
                  'Bạn có thể quản lý cookie trong phần cài đặt trình duyệt',
                ],
              ),
              const _PolicyBlock(
                icon: Icons.support_agent_rounded,
                title: 'Liên Hệ',
                description:
                    'Nếu có bất kỳ thắc mắc nào về chính sách bảo mật, vui lòng liên hệ:',
                contactInfo: const [
                  'Email: privacy@xemcook.com',
                  'Hotline: 0123 456 789',
                  'Thời gian: 9h - 18h, Thứ 2 - Thứ 6',
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Important Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notification_important_outlined,
                      color: Colors.amber[800],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chúng tôi có thể cập nhật chính sách này theo thời gian. Bạn nên kiểm tra định kỳ để nắm bắt các thay đổi. Nếu có thay đổi quan trọng, chúng tôi sẽ thông báo trực tiếp đến bạn.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
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

class _PolicyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String>? bulletPoints;
  final List<String>? contactInfo;

  const _PolicyBlock({
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue[700],
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
                        color: Colors.blue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.blue[700],
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: contactInfo!.map((info) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      info,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}