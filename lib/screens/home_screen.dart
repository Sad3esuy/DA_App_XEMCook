import 'package:flutter/material.dart';
import '../model/recipe.dart';
import '../model/user.dart';
import '../services/auth_service.dart';
import '../services/recipe_api_service.dart';
import '../theme/app_theme.dart';
import 'recipe/recipe_detail_screen.dart';
import 'recipe/recipe_form_screen.dart';
import 'recipe/recipes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _recipesFuture = _fetchRecipes();
  }

  Future<List<Recipe>> _fetchRecipes() {
    return RecipeApiService.getAllRecipes();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _refreshRecipes() {
    final future = _fetchRecipes();
    setState(() {
      _recipesFuture = future;
    });
    return future;
  }

  void _openRecipeDetail(Recipe recipe) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryOrange,
        onPressed: () async {
          final created =
              await Navigator.of(context, rootNavigator: true).push<bool>(
            MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
          );
          if (created == true && mounted) {
            await _refreshRecipes();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Recipe>>(
          future: _recipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refreshRecipes,
              );
            }

            final recipes = snapshot.data ?? const <Recipe>[];
            final creators = _collectCreators(recipes);

            if (recipes.isEmpty) {
              return _EmptyState(onCreate: _openCreateRecipe);
            }

            return RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: _refreshRecipes,
              child: ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  _FeaturedRecipeBanner(
                    recipe: recipes.first,
                    onTap: () => _openRecipeDetail(recipes.first),
                  ),
                  const SizedBox(height: 36),
                  _SectionHeader(
                    title: 'Our Latest Recipes',
                    actionLabel: 'See all',
                    onActionTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => const RecipesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _LatestRecipesStrip(
                    recipes: recipes.skip(1).take(6).toList(),
                    onRecipeTap: _openRecipeDetail,
                  ),
                  if (creators.isNotEmpty) ...[
                    const SizedBox(height: 36),
                    Text(
                      'Explore the best recipes from',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _CreatorStrip(creators: creators),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCreateRecipe() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final name = (_currentUser?.fullName ?? '').trim();
    final displayName = name.isEmpty ? 'Chef' : name;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $displayName 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like to cook today?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 71, 186, 232).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.primaryOrange,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  List<_AuthorProfile> _collectCreators(List<Recipe> recipes) {
    final seen = <String>{};
    final result = <_AuthorProfile>[];
    for (final recipe in recipes) {
      final rawName = recipe.authorName ?? '';
      final name = rawName.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) {
        result.add(
          _AuthorProfile(
            name: name,
            avatar: recipe.authorAvatar,
          ),
        );
      }
    }
    return result;
  }
}

class _FeaturedRecipeBanner extends StatelessWidget {
  const _FeaturedRecipeBanner({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authorName =
        (recipe.authorName ?? '').isEmpty ? 'Unknown chef' : recipe.authorName!;
    final likes =
        recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 320,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration:
                    const BoxDecoration(color: AppTheme.secondaryYellow),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (recipe.imageUrl.isNotEmpty)
                      Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImageFallback(),
                      )
                    else
                      const _ImageFallback(),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 12),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's Recipe",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        _LikePill(count: likes),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestRecipesStrip extends StatelessWidget {
  const _LatestRecipesStrip({required this.recipes, required this.onRecipeTap});

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Text(
        'Add more recipes to keep the inspiration flowing.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _LatestRecipeCard(
            recipe: recipe,
            onTap: () => onRecipeTap(recipe),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemCount: recipes.length,
      ),
    );
  }
}

class _LatestRecipeCard extends StatelessWidget {
  const _LatestRecipeCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTime = recipe.prepTime + recipe.cookTime;
    final likes =
        recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;

    final chips = <_RecipeChip>[];
    if (totalTime > 0) {
      chips.add(
        _RecipeChip(
          label: '$totalTime min',
          background: const Color(0xFFFFEDCF),
          foreground: AppTheme.textDark,
        ),
      );
    }
    final tag = recipe.tags.isNotEmpty ? recipe.tags.first.trim() : '';
    if (tag.isNotEmpty) {
      chips.add(
        _RecipeChip(
          label: _formatTag(tag),
          background: const Color(0xFFE7F8ED),
          foreground: AppTheme.accentGreen,
        ),
      );
    }

    final authorName = (recipe.authorName ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.06),
          //     blurRadius: 20,
          //     offset: const Offset(0, 10),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration:
                          const BoxDecoration(color: AppTheme.secondaryYellow),
                      child: recipe.imageUrl.isNotEmpty
                          ? Image.network(
                              recipe.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  const _ImageFallback(),
                            )
                          : const _ImageFallback(),
                    ),
                  ),
                  if (chips.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'roboto',
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondaryYellow,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: _AuthorAvatar(
                            avatarUrl: recipe.authorAvatar,
                            name: authorName,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authorName.isEmpty ? 'Anonymous' : authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color.fromARGB(255, 239, 10, 10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTag(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

class _CreatorStrip extends StatelessWidget {
  const _CreatorStrip({required this.creators});

  final List<_AuthorProfile> creators;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final profile = creators[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryYellow.withValues(alpha: 0.8),
                ),
                alignment: Alignment.center,
                child: _AuthorAvatar(
                  avatarUrl: profile.avatar,
                  name: profile.name,
                  size: 60,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 72,
                child: Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color.fromARGB(255, 44, 44, 44),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemCount: creators.length,
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.avatarUrl,
    required this.name,
    this.size = 60,
  });

  final String? avatarUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dimension = size;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          fit: BoxFit.cover,
          width: dimension,
          height: dimension,
          errorBuilder: (_, __, ___) =>
              _InitialsBadge(name: name, size: dimension),
        ),
      );
    }
    return _InitialsBadge(name: name, size: dimension);
  }
}

class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initials = trimmed.isEmpty
        ? 'C'
        : trimmed
            .split(RegExp(r'\\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.primaryOrange,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _RecipeChip extends StatelessWidget {
  const _RecipeChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 48, color: AppTheme.primaryOrange),
            const SizedBox(height: 16),
            Text(
              'Let us cook something',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first recipe to see it featured here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Add a recipe'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorProfile {
  const _AuthorProfile({required this.name, this.avatar});

  final String name;
  final String? avatar;
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

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
