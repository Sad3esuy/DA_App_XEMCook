import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ui_app/model/user.dart';
import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'change_password_screen.dart';
import 'package:test_ui_app/model/recipe.dart';
import '../recipe/recipe_detail_screen.dart';
import '../recipe/my_recipes_screen.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import 'widget/statItem.dart';
import 'widget/menuItem.dart';
import 'widget/menuSection.dart';
import '../favorite_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  User? _user;
  UserStats? _stats;
  bool _busy = false;
  int _avatarVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.getUser();
    setState(() => _user = u);
    await _auth.getMe();
    final refreshed = await _auth.getUser();
    setState(() => _user = refreshed ?? u);
    if (_user != null) {
      final s = await _auth.getUserStats(_user!.id);
      setState(() => _stats = s);
    }
  }

  String? _resolveNetworkAvatarUrl(String avatar) {
    if (avatar.startsWith('data:image')) return null;
    var resolved = avatar;
    final parsed = Uri.tryParse(resolved);
    if (parsed == null ||
        !(parsed.hasScheme &&
            (parsed.isScheme('http') || parsed.isScheme('https')))) {
      final baseUri = Uri.parse(AuthService.baseUrl);
      final portPart = baseUri.hasPort ? ':${baseUri.port}' : '';
      if (!resolved.startsWith('/')) {
        resolved = '/$resolved';
      }
      resolved = '${baseUri.scheme}://${baseUri.host}$portPart$resolved';
    }
    return resolved;
  }

  ImageProvider<Object>? _buildAvatarImageProvider(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('data:image')) {
      try {
        final commaIndex = avatar.indexOf(',');
        final data =
            commaIndex != -1 ? avatar.substring(commaIndex + 1) : avatar;
        final bytes = base64Decode(data);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    final resolved = _resolveNetworkAvatarUrl(avatar);
    if (resolved == null) return null;
    final url = resolved.contains('?')
        ? '$resolved&v=$_avatarVersion'
        : '$resolved?v=$_avatarVersion';
    return NetworkImage(url);
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';
      final b64 = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$b64';
      final res = await _auth.updateProfile(avatarUploadBase64: dataUri);
      if (res.isSuccess) {
        await _auth.getMe();
        final refreshed = await _auth.getUser();
        final newUrl = refreshed?.avatar;
        if (newUrl != null &&
            newUrl.isNotEmpty &&
            !newUrl.startsWith('data:image')) {
          final resolved = _resolveNetworkAvatarUrl(newUrl);
          try {
            if (resolved != null) {
              NetworkImage(resolved).evict();
            }
          } catch (_) {}
        }
        if (mounted) {
          setState(() {
            _user = refreshed ?? _user;
            _avatarVersion++;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cập nhật ảnh đại diện thành công')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Cập nhật không thành công')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(95, 209, 209, 209),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Huỷ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (_user == null) return;
    if (_user!.authProvider == 'google') {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Vui lòng gõ "delete" để xác nhận xóa tài khoản Google.'),
              const SizedBox(height: 12),
              TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'delete',hintStyle: const TextStyle(color: Color(0xFFC0C0C0)),)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy')),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (ok == true) {
        final text = controller.text.trim();
        if (text.toLowerCase() != 'delete') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bạn phải nhập đúng "delete"')));
          return;
        }
        setState(() => _busy = true);
        final res = await _auth.deleteAccount(confirm: 'delete');
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Đã xóa tài khoản')),
        );
      }
    } else {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập mật khẩu để xác nhận xóa tài khoản'),
              const SizedBox(height: 12),
              TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Mật khẩu')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy')),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (ok == true) {
        setState(() => _busy = true);
        final res = await _auth.deleteAccount(password: controller.text.trim());
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Đã xóa tài khoản')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final avatarProvider = _buildAvatarImageProvider(user?.avatar);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tài khoản'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Color(0xFFFF8C42),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        color: AppTheme.primaryOrange,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        // Hàm gọi khi kéo xuống
        onRefresh: () async => _load(),   // hoặc: () => _load()
        // Nội dung cuộn
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // rất quan trọng
          slivers: [
                // Header với avatar và thông tin user
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8C42), // chỉ một màu
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Avatar với nút edit
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: avatarProvider,
                                  child: avatarProvider == null
                                      ? const Icon(Icons.person,
                                          size: 50,
                                          color: AppTheme.primaryOrange)
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _busy ? null : _pickAndUploadAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Tên user
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bio nếu có
                          if ((user.bio ?? '').isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                user.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Stats (nằm trong header luôn)
                          if (_stats != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    StatItem(
                                      icon: Icons.menu_book,
                                      label: 'Công thức',
                                      value: _stats!.totalRecipes.toString(),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey[300],
                                    ),
                                    StatItem(
                                      icon: Icons.collections_bookmark,
                                      label: 'Bộ sưu tập',
                                      value:
                                          _stats!.totalCollections.toString(),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey[300],
                                    ),
                                    StatItem(
                                      icon: Icons.favorite,
                                      label: 'Yêu thích',
                                      value: _stats!.totalFavorites.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Menu items
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      MenuSection(
                        title: 'Quản lý tài khoản',
                        items: [
                          MenuItem(
                            icon: Icons.edit_outlined,
                            title: 'Chỉnh sửa hồ sơ',
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileInline(
                                    initialName: user.fullName,
                                    initialBio: user.bio ?? '',
                                  ),
                                ),
                              );
                              if (updated == true) _load();
                            },
                          ),
                          MenuItem(
                            icon: Icons.lock_outline,
                            title: 'Đổi mật khẩu',
                            onTap: user.authProvider == 'google'
                                ? () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tài khoản Google không thể đổi mật khẩu trên ứng dụng. Vui lòng đổi trên Google.',
                                        ),
                                      ),
                                    )
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ChangePasswordScreen(),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      MenuSection(
                        title: 'Nội dung',
                        items: [
                          MenuItem(
                            icon: Icons.favorite_border_outlined,
                            title: 'Món yêu thích',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoritesScreen(),
                              ),
                            ),
                          ),
                          MenuItem(
                            icon: Icons.mode_comment_outlined,
                            title: 'Đánh giá của tôi',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyRecipesScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      MenuSection(
                        title: 'Cài đặt hệ thống',
                        items: [
                          MenuItem(
                            icon: Icons.language_outlined,
                            title: 'Ngôn ngữ',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoritesScreen(),
                              ),
                            ),
                          ),
                          MenuItem(
                            icon: Icons.brightness_4_outlined,
                            title: 'Giao diện',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyRecipesScreen(),
                              ),
                            ),
                          ),
                          MenuItem(
                            icon: Icons.circle_notifications_outlined,
                            title: 'Thông báo',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyRecipesScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      MenuSection(
                        title: 'Thông tin',
                        items: [
                          MenuItem(
                            icon: Icons.info_outlined,
                            title: 'Về chúng tôi',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoritesScreen(),
                              ),
                            ),
                          ),
                          MenuItem(
                            icon: Icons.policy_outlined,
                            title: 'chính sách bảo mật',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyRecipesScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      MenuSection(
                        title: 'Nguy hiểm',
                        items: [
                          MenuItem(
                            icon: Icons.delete_outline,
                            title: 'Xóa tài khoản',
                            isDestructive: true,
                            onTap: _busy ? null : _deleteAccount,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      //logout button
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _signOut,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.logout),
                          label: const Text('Đăng xuất'),
                        ),
                      ),

                      const SizedBox(height: 128),
                    ]),
                  ),
                ),
              ],
            ),
          )
    );
  }
}

