import 'package:flutter/material.dart';

import '../../model/chef_profile.dart';
import '../../model/collection.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/my_recipe_cards.dart';
import '../recipe/recipe_detail_screen.dart';
import 'widget/statItem.dart';

class ChefProfileScreen extends StatefulWidget {
  const ChefProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatar,
  });

  final String userId;
  final String? initialName;
  final String? initialAvatar;

  @override
  State<ChefProfileScreen> createState() => _ChefProfileScreenState();
}

class _ChefProfileScreenState extends State<ChefProfileScreen> {
  final _authService = AuthService();

  ChefProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _authService.getChefProfile(widget.userId);
      if (!mounted) return;
      if (data == null) {
        setState(() {
          _error = 'Không tìm thấy hồ sơ chef này.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final title = _profile?.user.fullName ??
        widget.initialName ??
        'Chef profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.lightCream,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: _loadProfile,
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const _ErrorView(
        message: 'Không thể tải dữ liệu hồ sơ.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryOrange,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              profile: profile,
              fallbackAvatar: widget.initialAvatar,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          SliverToBoxAdapter(
            child: _CollectionsSection(collections: profile.collections),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          if (profile.recipes.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 250,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = profile.recipes[index];
                    return RecipeGridCard(
                      recipe: recipe,
                      onTap: () => Navigator.of(context, rootNavigator: true)
                          .push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(recipeId: recipe.id),
                        ),
                      ),
                    );
                  },
                  childCount: profile.recipes.length,
                ),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: _EmptySectionMessage(
                title: 'Chưa có công thức công khai',
                subtitle:
                    'Khi chef này chia sẻ công thức, chúng sẽ xuất hiện ở đây.',
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.fallbackAvatar,
  });

  final ChefProfile profile;
  final String? fallbackAvatar;

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final bio = user.bio?.trim() ?? '';
    final stats = profile.stats;
    final avatarUrl = _resolveAvatarUrl(user.avatar ?? fallbackAvatar);
    final initials = _initialsFor(user.fullName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.secondaryYellow,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                ),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textDark,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatItem(
                icon: Icons.restaurant_menu,
                label: 'Công thức',
                value: stats.totalRecipes.toString(),
              ),
              StatItem(
                icon: Icons.folder_special,
                label: 'Bộ sưu tập',
                value: stats.totalCollections.toString(),
              ),
              StatItem(
                icon: Icons.favorite_rounded,
                label: 'Yêu thích',
                value: stats.totalFavorites.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String? _resolveAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('data:image')) return null;
    final parsed = Uri.tryParse(avatar);
    if (parsed != null && parsed.hasScheme) {
      return avatar;
    }
    final baseUri = Uri.parse(AuthService.baseUrl);
    final path = avatar.startsWith('/') ? avatar : '/$avatar';
    final port = baseUri.hasPort ? ':${baseUri.port}' : '';
    return '${baseUri.scheme}://${baseUri.host}$port$path';
  }

  static String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) {
      final word = parts.first;
      final chars = word.length >= 2 ? word.substring(0, 2) : word[0];
      return chars.toUpperCase();
    }
    final first = parts.first;
    final last = parts.last;
    final firstInitial = first.isNotEmpty ? first[0] : '';
    final lastInitial = last.isNotEmpty ? last[0] : '';
    final seed = '$firstInitial$lastInitial'.trim();
    return seed.isEmpty ? 'C' : seed.toUpperCase();
  }
}

class _CollectionsSection extends StatelessWidget {
  const _CollectionsSection({required this.collections});

  final List<Collection> collections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bộ sưu tập công khai',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: 12),
          if (collections.isEmpty)
            const _EmptySectionMessage(
              title: 'Chưa có bộ sưu tập công khai',
              subtitle:
                  'Khi chef này chia sẻ bộ sưu tập, chúng sẽ hiển thị ở đây.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 100,
              ),
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];
                final colors = _collectionPalette;
                final color = colors[index % colors.length];
                return CollectionSummaryCard(
                  title: collection.name,
                  subtitle: '${collection.recipeCount} công thức',
                  backgroundColor: color,
                  icon: Icons.folder_rounded,
                  iconColor: AppTheme.accentGreen,
                );
              },
            ),
        ],
      ),
    );
  }

  static const _collectionPalette = [
    Color.fromARGB(208, 238, 240, 221),
    Color.fromARGB(208, 232, 240, 221),
    Color.fromARGB(208, 240, 221, 232),
    Color.fromARGB(208, 221, 232, 240),
    Color.fromARGB(208, 240, 232, 221),
    Color.fromARGB(208, 232, 221, 240),
  ];
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied,
              color: AppTheme.primaryOrange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
