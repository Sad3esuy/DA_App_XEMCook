import 'package:flutter/material.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/screens/recipe/recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Recipe> _future;
  bool _busy = false;
  bool _favorite = false;
  double _avg = 0;
  int _total = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _future = RecipeApiService.getRecipeById(widget.recipeId);
    _loadCurrentUser();
  }

  Future<void> _reload() async {
    setState(() {
      _future = RecipeApiService.getRecipeById(widget.recipeId);
    });
    await _future.catchError((_) {});
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getUser();
    if (!mounted) return;
    setState(() => _currentUserId = user?.id);
  }

  Future<void> _openRateSheet(String recipeId) async {
    int selected = 5;
    final commentCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đánh giá công thức', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return IconButton(
                        onPressed: () => setSheetState(() => selected = idx),
                        icon: Icon(idx <= selected ? Icons.star : Icons.star_border, color: AppTheme.primaryOrange, size: 28),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentCtrl,
                    decoration: const InputDecoration(hintText: 'Nhận xét (tuỳ chọn)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Gửi đánh giá'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true) {
      try {
        final data = await RecipeApiService.rateRecipe(recipeId, selected, comment: commentCtrl.text.trim());
        setState(() {
          _avg = (data['avgRating'] ?? 0.0) is num ? (data['avgRating'] + 0.0) : 0.0;
          _total = data['totalRatings'] ?? _total;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá')));
        }
        await _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đánh giá: $e')));
        }
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá công thức'),
        content: const Text('Bạn chắc chắn muốn xoá công thức này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await RecipeApiService.deleteRecipe(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá công thức')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xoá thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Recipe>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 40),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thất bại, thử lại'),
                      )
                    ],
                  ),
                ),
              );
            }

            final recipe = snapshot.data!;
            _favorite = recipe.isFavorite;
            _avg = recipe.avgRating;
            _total = recipe.totalRatings;

            final totalTime = recipe.prepTime + recipe.cookTime;
            final canManage = _currentUserId != null &&
                (recipe.userId ?? '').isNotEmpty &&
                recipe.userId == _currentUserId;
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 260,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      tooltip: _favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                final isFav = await RecipeApiService.toggleFavorite(recipe.id);
                                if (!mounted) return;
                                setState(() => _favorite = isFav);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border, color: AppTheme.primaryOrange),
                    ),
                    if (canManage)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RecipeFormScreen(recipeId: recipe.id)),
                            );
                            if (updated == true) {
                              _reload();
                            }
                          } else if (value == 'delete') {
                            _delete(recipe.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Sửa')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Xoá', style: TextStyle(color: AppTheme.errorRed)),
                          ),
                        ],
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
                    title: Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.lightCream),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppTheme.secondaryYellow,
                          child: recipe.imageUrl.isEmpty
                              ? const Center(child: Icon(Icons.image, color: AppTheme.textLight))
                              : Image.network(
                                  recipe.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => const Center(
                                    child: Icon(Icons.broken_image_outlined, color: AppTheme.textLight),
                                  ),
                                ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black26],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(icon: Icons.category, label: recipe.category),
                          _Chip(icon: Icons.leaderboard, label: recipe.difficulty),
                      const SizedBox(height: 12),
                      _RatingSummary(avg: _avg, total: _total),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _openRateSheet(recipe.id),
                          icon: const Icon(Icons.star_rate_rounded, color: AppTheme.primaryOrange),
                          label: const Text('Đánh giá'),
                        ),
                      ),
                          _Chip(icon: Icons.timer, label: '$totalTime phút'),
                          _Chip(icon: Icons.person, label: '${recipe.servings} khẩu phần'),
                        ],
                      ),
                      if (recipe.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: recipe.tags
                              .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _SectionTitle(icon: Icons.description_outlined, title: 'Mô tả'),
                      const SizedBox(height: 6),
                      Text(recipe.description, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      _SectionTitle(icon: Icons.shopping_bag_outlined, title: 'Nguyên liệu'),
                      const SizedBox(height: 8),
                      ...recipe.ingredients.map((i) => _Bullet('${i.quantity} ${i.unit} - ${i.name}')),
                      const SizedBox(height: 16),
                      _SectionTitle(icon: Icons.format_list_numbered, title: 'Các bước thực hiện'),
                      const SizedBox(height: 8),
                      ...recipe.instructions.map((s) => _Bullet('Bước ${s.step}: ${s.description}')),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Recipe recipe;
  const _Header({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final totalTime = recipe.prepTime + recipe.cookTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: AppTheme.secondaryYellow,
            child: recipe.imageUrl.isEmpty
                ? const Center(child: Icon(Icons.image, color: AppTheme.textLight))
                : Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: AppTheme.textLight),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(icon: Icons.category, label: recipe.category),
                  _Chip(icon: Icons.leaderboard, label: recipe.difficulty),
                  _Chip(icon: Icons.timer, label: '$totalTime phút'),
                  _Chip(icon: Icons.person, label: '${recipe.servings} khẩu phần'),
                ],
              ),
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: recipe.tags
                      .map((t) => Chip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        )
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryOrange),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondaryYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppTheme.textDark,
                ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double avg;
  final int total;
  const _RatingSummary({required this.avg, required this.total});

  @override
  Widget build(BuildContext context) {
    final full = avg.floor();
    final hasHalf = (avg - full) >= 0.5;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < full) return const Icon(Icons.star, color: AppTheme.primaryOrange, size: 18);
          if (i == full && hasHalf) return const Icon(Icons.star_half, color: AppTheme.primaryOrange, size: 18);
          return const Icon(Icons.star_border, color: AppTheme.primaryOrange, size: 18);
        }),
        const SizedBox(width: 8),
        Text('${avg.toStringAsFixed(1)} • $total đánh giá', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

