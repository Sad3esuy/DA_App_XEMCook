import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ui_app/model/user.dart';
import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'recipe/recipe_detail_screen.dart';
// Screen món yêu thích
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _recipes = const <Recipe>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final data = await RecipeApiService.getFavorites();
      if (!mounted) return;
      setState(() {
        _recipes = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_recipes.isEmpty || showSpinner) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể làm mới danh sách: $e')),
        );
      }
    }
  }

  void _removeRecipe(String id) {
    setState(() {
      _recipes = _recipes.where((r) => r.id != id).toList();
    });
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 220),
        ],
      );
    }

    if (_error != null && _recipes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 52, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải danh sách yêu thích.\n$_error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _loadFavorites(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_recipes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border,
                    size: 52, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'Bạn chưa có món nào trong danh sách yêu thích.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy khám phá và thêm những công thức bạn thích.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return _FavoriteRecipeItem(
          key: ValueKey(recipe.id),
          recipe: recipe,
          onRemoved: () => _removeRecipe(recipe.id),
          onRefreshRequested: () => _loadFavorites(showSpinner: false),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _recipes.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Món yêu thích'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () => _loadFavorites(showSpinner: false),
        child: _buildBody(),
      ),
    );
  }
}

class _FavoriteRecipeItem extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onRemoved;
  final Future<void> Function() onRefreshRequested;

  const _FavoriteRecipeItem({
    required this.recipe,
    required this.onRemoved,
    required this.onRefreshRequested,
    super.key,
  });

  @override
  State<_FavoriteRecipeItem> createState() => _FavoriteRecipeItemState();
}

class _FavoriteRecipeItemState extends State<_FavoriteRecipeItem> {
  bool _busy = false;

  Future<void> _toggleFavorite() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final stillFavorite =
          await RecipeApiService.toggleFavorite(widget.recipe.id);
      if (!mounted) return;
      setState(() => _busy = false);
      if (!stillFavorite) {
        widget.onRemoved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bỏ khỏi danh sách yêu thích')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
      );
    }
  }

  Future<void> _openDetail() async {
    final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: widget.recipe.id),
      ),
    );
    if (changed == true && mounted) {
      await widget.onRefreshRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalTime = recipe.prepTime + recipe.cookTime;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: _openDetail,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FavoriteRecipeImage(imageUrl: recipe.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          color: AppTheme.primaryOrange,
                          tooltip: 'Bỏ khỏi yêu thích',
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _busy
                                ? const SizedBox(
                                    key: ValueKey('loader'),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryOrange),
                                    ),
                                  )
                                : const Icon(
                                    Icons.favorite,
                                    key: ValueKey('favorite'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.category, label: recipe.category),
                        _InfoChip(
                            icon: Icons.leaderboard, label: recipe.difficulty),
                        if (totalTime > 0)
                          _InfoChip(
                              icon: Icons.timer, label: '$totalTime phút'),
                      ],
                    ),
                    if (recipe.avgRating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 18, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.avgRating.toStringAsFixed(1)} (${recipe.totalRatings})',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteRecipeImage extends StatelessWidget {
  final String imageUrl;

  const _FavoriteRecipeImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 92,
        color: AppTheme.secondaryYellow,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _ImageFallback();
                },
              )
            : const _ImageFallback(),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image, color: AppTheme.textLight),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

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
          Icon(icon, size: 16, color: AppTheme.textDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
