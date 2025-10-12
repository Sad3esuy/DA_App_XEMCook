import 'package:flutter/material.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _future = RecipeApiService.getRecipeById(widget.recipeId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = RecipeApiService.getRecipeById(widget.recipeId);
    });
    await _future.catchError((_) {});
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công thức'),
        content: const Text('Bạn có chắc muốn xóa công thức này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Xóa'),
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
        const SnackBar(content: Text('Đã xóa công thức')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e')),
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
                        label: const Text('Thử lại'),
                      )
                    ],
                  ),
                ),
              );
            }

            final recipe = snapshot.data!;
            _favorite = recipe.isFavorite;

            final totalTime = recipe.prepTime + recipe.cookTime;
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
                                final updated = await RecipeApiService.toggleFavorite(recipe.id);
                                if (!mounted) return;
                                setState(() => _favorite = updated.isFavorite);
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
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        // if (value == 'edit') {
                        //   final updated = await Navigator.of(context).push<bool>(
                        //     MaterialPageRoute(builder: (_) => RecipeFormScreen(initial: recipe)),
                        //   );
                        //   if (updated == true) _reload();
                        // } else 
                        if (value == 'delete') {
                          _delete(recipe.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa', style: TextStyle(color: AppTheme.errorRed)),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
                    title: Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textDark),
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
