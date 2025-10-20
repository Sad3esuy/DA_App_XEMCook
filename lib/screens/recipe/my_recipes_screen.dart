import 'package:flutter/material.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';

import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import '../favorite_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  late Future<List<Recipe>> _future;

  @override
  void initState() {
    super.initState();
    _future = RecipeApiService.getMyRecipes();
  }

  Future<void> _reload() async {
    setState(() => _future = RecipeApiService.getMyRecipes());
    await _future.catchError((_) {});
  }

  Future<void> _openCreateRecipe() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
    );
    if (created == true) {
      await _reload();
    }
  }

  Future<void> _openRecipeDetail(String recipeId) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipeId)),
    );
  }

  Future<void> _handleMenuSelection(String value, Recipe recipe) async {
    if (value == 'edit') {
      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(recipeId: recipe.id),
        ),
      );
      if (updated == true) {
        await _reload();
      }
    } else if (value == 'view') {
      await _openRecipeDetail(recipe.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công thức của tôi'),
        titleTextStyle: TextStyle(
            fontSize: 24,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins'),
        backgroundColor: AppTheme.lightCream,
        actions: [
          IconButton(
              onPressed: () async {
                final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecipeFormScreen()));
                if (created == true) _reload();
              },
              icon: const Icon(Icons.add))
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 5, // ✅ thấp hơn, đẹp hơn
        ),
        child: FloatingActionButton(
          backgroundColor: const Color.fromARGB(131, 66, 107, 93),
          foregroundColor: Colors.white,
          onPressed: _openCreateRecipe,
          child: const Icon(Icons.add),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          color: AppTheme.primaryOrange,
          child: FutureBuilder<List<Recipe>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _LoadingView(theme: theme);
              }
              if (snapshot.hasError) {
                return _ErrorView(
                  error: snapshot.error,
                  onRetry: _reload,
                );
              }
              final recipes = snapshot.data ?? const <Recipe>[];
              if (recipes.isEmpty) {
                return const _EmptyView();
              }
              return _RecipesContent(
                recipes: recipes,
                onCreatePressed: _openCreateRecipe,
                onOpenRecipe: (recipe) => _openRecipeDetail(recipe.id),
                onMenuSelected: _handleMenuSelection,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomNavMetrics {
  const _BottomNavMetrics._();

  /// Approximate height of the custom bottom navigation content (excluding safe area).
  static const double navHeight = 72.0;

  /// Extra padding to keep the FAB above the bottom navigation bar.
  static double offsetFor(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return navHeight + safeBottom + 12; // 12 matches nav's vertical padding.
  }
}

class _RecipesContent extends StatelessWidget {
  const _RecipesContent({
    required this.recipes,
    required this.onCreatePressed,
    required this.onOpenRecipe,
    required this.onMenuSelected,
  });

  final List<Recipe> recipes;
  final VoidCallback onCreatePressed;
  final ValueChanged<Recipe> onOpenRecipe;
  final Future<void> Function(String value, Recipe recipe) onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesCount = recipes.where((r) => r.isFavorite).length;
    final quickMeals = recipes
        .where((r) =>
            (r.prepTime + r.cookTime) <= 30 && (r.prepTime + r.cookTime) > 0)
        .length;

    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Collection Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: _CollectionCard(
                    title: 'Yêu thích',
                    subtitle: '$favoritesCount công thức',
                    backgroundColor: const Color(0xD0DDF0E8), // = ARGB(208,221,240,232)
                    icon: Icons.favorite_rounded,
                    iconColor: AppTheme.primaryOrange,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CollectionCard(
                    title: 'Ggg',
                    subtitle: '$quickMeals items',
                    backgroundColor: const Color.fromARGB(208, 221, 240, 232),
                    icon: Icons.grid_view_rounded,
                    iconColor: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recipe Grid
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            20, 0, 20,
            _BottomNavMetrics.offsetFor(context) + 16, // chừa giống FAB
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              mainAxisExtent: 250,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = recipes[index];
                return _RecipeGridCard(
                  recipe: recipe,
                  onOpen: () => onOpenRecipe(recipe),
                  onMenuSelected: (value) => onMenuSelected(value, recipe),
                );
              },
              childCount: recipes.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error?.toString() ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long,
                    size: 52, color: AppTheme.primaryOrange),
                const SizedBox(height: 16),
                Text(
                  'No recipes yet',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first recipe or save dishes you love to keep them here.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontSize: 13,
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



class _RecipeGridCard extends StatelessWidget {
  const _RecipeGridCard({
    required this.recipe,
    required this.onOpen,
    required this.onMenuSelected,
  });

  final Recipe recipe;
  final VoidCallback onOpen;
  final Future<void> Function(String value) onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTime = recipe.prepTime + recipe.cookTime;
    final tag = recipe.tags.isNotEmpty ? recipe.tags.first.trim() : '';
    final likes =
        recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: recipe.imageUrl.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const _ImagePlaceholder(),
                          )
                        : const _ImagePlaceholder(),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (totalTime > 0) _Badge(label: '$totalTime min'),
                        if (tag.isNotEmpty)
                          _Badge(
                            label: _formatTag(tag),
                            foreground: AppTheme.accentGreen,
                            background: const Color(0xFFE7F8ED),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _LikePill(count: likes),
                  ),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTag(String raw) {
    if (raw.isEmpty) return raw;
    final lower = raw.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

class _RecipeImage extends StatelessWidget {
  const _RecipeImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppTheme.secondaryYellow,
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: AppTheme.primaryOrange),
      ),
    );

    if (imageUrl.isEmpty) {
      return placeholder;
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.background, this.foreground});

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFFFEDCF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground ?? AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LikePill extends StatelessWidget {
  const _LikePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border,
              size: 16, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.secondaryYellow,
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: AppTheme.primaryOrange),
      ),
    );
  }
}

String _formatTag(String value) {
  if (value.isEmpty) return value;
  final lower = value.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}
