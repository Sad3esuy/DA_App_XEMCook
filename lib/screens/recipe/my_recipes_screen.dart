import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/model/collection.dart';
import 'package:test_ui_app/services/favorite_state.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/widgets/my_recipe_cards.dart';

import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'favorite_screen.dart';
import 'collection/create_collection_screen.dart';
import 'collection/collection_detail_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<Recipe> _recipes = [];
  List<Collection> _collections = [];
  bool _isLoadingRecipes = true;
  bool _isLoadingCollections = false;
  String? _error;
  late final FavoriteState _favoriteState;
  VoidCallback? _favoriteListener;
  final Set<String> _favoriteBusy = <String>{};

  @override
  void initState() {
    super.initState();
    _favoriteState = context.read<FavoriteState>();
    _favoriteListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _favoriteState.addListener(_favoriteListener!);
    _loadData();
  }

  @override
  void dispose() {
    if (_favoriteListener != null) {
      _favoriteState.removeListener(_favoriteListener!);
    }
    super.dispose();
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoadingRecipes = true;
        _isLoadingCollections = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        RecipeApiService.getMyRecipes(),
        RecipeApiService.getMyCollections(limit: 100),
      ]);

      if (!mounted) return;

      setState(() {
        _recipes = results[0] as List<Recipe>;
        _collections = results[1] as List<Collection>;
        _isLoadingRecipes = false;
        _isLoadingCollections = false;
        _error = null;
      });
      _favoriteState.absorbRecipes(_recipes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingRecipes = false;
        _isLoadingCollections = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoadingCollections = true);
    try {
      final collections = await RecipeApiService.getMyCollections(limit: 100);
      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoadingCollections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCollections = false);
      }
      debugPrint('Error loading collections: $e');
    }
  }

  Future<void> _reload() async {
    await _loadData(showSpinner: false);
  }

  Future<void> _openCreateCollection() async {
    final result = await Navigator.push<Collection>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
    );
    if (result != null) {
      await _loadCollections();
    }
  }

  Future<void> _openCreateRecipe() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
    );
    if (created == true) {
      await _loadData(showSpinner: false);
    }
  }

  Future<void> _openRecipeDetail(String recipeId) async {
    final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipeId)),
    );
    if (changed == true && mounted) {
      await _loadData(showSpinner: false);
    }
  }

  Future<void> _handleFavoriteToggle(Recipe recipe) async {
    final recipeId = recipe.id;
    if (_favoriteBusy.contains(recipeId)) return;
    final nextValue = !_favoriteState.isFavorite(recipeId);
    
    // Helper to update local recipe list
    void updateLocalRecipe(String id, bool isFav, {bool increment = false, bool decrement = false}) {
      final index = _recipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        final r = _recipes[index];
        int newCount = r.totalRatings;
        if (increment) newCount++;
        if (decrement) newCount = (newCount > 0) ? newCount - 1 : 0;
        setState(() {
          _recipes[index] = r.copyWith(totalRatings: newCount, isFavorite: isFav);
        });
      }
    }

    setState(() {
      _favoriteBusy.add(recipeId);
      if (nextValue) {
        updateLocalRecipe(recipeId, nextValue, increment: true);
      } else {
        updateLocalRecipe(recipeId, nextValue, decrement: true);
      }
    });
    _favoriteState.setFavorite(recipeId, nextValue);
    try {
      final isFavorite = await _favoriteState.toggleFavorite(recipeId);
      if (!mounted) return;
      setState(() {
        _favoriteBusy.remove(recipeId);
        
        // Correct count if server returned different status
        if (isFavorite != nextValue) {
           if (isFavorite) {
             // We decremented, but it's fav (need +2: +1 to restore, +1 to inc?)
             // No, restore (+1) then set to true (which implies +1 vs original FALSE)
             // Simple: if we decremented (nextValue=false), but now isFavorite=true:
             // We need to increment twice? No.
             // Original: 5. 
             // Toggle -> 4 (next=false).
             // Server says true (5).
             // So we adding 1 back.
             updateLocalRecipe(recipeId, isFavorite, increment: true);
           } else {
             // We incremented (next=true), but server says false.
             // 5 -> 6. Server says false. Back to 5.
             updateLocalRecipe(recipeId, isFavorite, decrement: true);
           }
           _favoriteState.setFavorite(recipeId, isFavorite);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _favoriteBusy.remove(recipeId);
        // Revert
        if (nextValue) {
          updateLocalRecipe(recipeId, !nextValue, decrement: true);
        } else {
          updateLocalRecipe(recipeId, !nextValue, increment: true);
        }
      });
      _favoriteState.setFavorite(recipeId, !nextValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_isLoadingRecipes) {
      bodyContent = const _LoadingView();
    } else if (_error != null && _recipes.isEmpty) {
      bodyContent = _ErrorView(
        error: _error,
        onRetry: _reload,
      );
    } else if (_recipes.isEmpty) {
      bodyContent = const _EmptyView();
    } else {
      final favoriteIds = _favoriteState.ids;
      bodyContent = _RecipesContent(
        recipes: _recipes,
        collections: _collections,
        isLoadingCollections: _isLoadingCollections,
        onCreateCollection: _openCreateCollection,
        onOpenRecipe: (recipe) => _openRecipeDetail(recipe.id),
        onCollectionDeleted: _loadCollections,
        favoriteIds: favoriteIds,
        favoriteBusy: _favoriteBusy,
        onToggleFavorite: _handleFavoriteToggle,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công thức của tôi'),
        titleTextStyle: TextStyle(
            fontSize: 24,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins'),
        backgroundColor: AppTheme.lightCream,
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 5,
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
          child: bodyContent,
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
    required this.collections,
    required this.isLoadingCollections,
    required this.onCreateCollection,
    required this.onOpenRecipe,
    required this.onCollectionDeleted,
    required this.favoriteIds,
    required this.favoriteBusy,
    required this.onToggleFavorite,
  });

  final List<Recipe> recipes;
  final List<Collection> collections;
  final bool isLoadingCollections;
  final VoidCallback onCreateCollection;
  final ValueChanged<Recipe> onOpenRecipe;
  final Future<void> Function() onCollectionDeleted;
  final Set<String> favoriteIds;
  final Set<String> favoriteBusy;
  final Future<void> Function(Recipe) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    // Count all favorites from FavoriteState, not just from my recipes
    final favoritesCount = favoriteIds.length;

    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Collection Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Favorites Collection (always shown)
                Row(
                  children: [
                    Expanded(
                      child: CollectionSummaryCard(
                        title: 'Yêu thích',
                        subtitle: '$favoritesCount công thức',
                        backgroundColor: const Color(0xD0DDF0E8),
                        icon: Icons.favorite_rounded,
                        iconColor: AppTheme.primaryOrange,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          );
                        },
                      ),
                    ),
                    
                    // Create Collection button
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CreateCollectionCard(onTap: onCreateCollection),
                    ),
                  ],
                ),

                if (isLoadingCollections) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Show all user collections in a grid
                if (collections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _CollectionsGrid(
                    collections: collections,
                    onCollectionDeleted: onCollectionDeleted,
                  ),
                ],
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
                return RecipeGridCard(
                  recipe: recipe,
                  onTap: () => onOpenRecipe(recipe),
                  isFavorite: favoriteIds.contains(recipe.id) ||
                      recipe.isFavorite,
                  onToggleFavorite: () => onToggleFavorite(recipe),
                  isFavoriteBusy: favoriteBusy.contains(recipe.id),
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
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

// Widget for creating a new collection
class _CreateCollectionCard extends StatelessWidget {
  const _CreateCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(208, 240, 232, 221),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thêm bộ sưu tập',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for displaying all collections in a grid
class _CollectionsGrid extends StatelessWidget {
  const _CollectionsGrid({
    required this.collections,
    required this.onCollectionDeleted,
  });

  final List<Collection> collections;
  final Future<void> Function() onCollectionDeleted;

  @override
  Widget build(BuildContext context) {
    // Create a list of colors for collections
    final colors = [
      const Color.fromARGB(208, 238, 240, 221), // Green tint
      const Color.fromARGB(208, 232, 240, 221), // Light green
      const Color.fromARGB(208, 240, 221, 232), // Pink tint
      const Color.fromARGB(208, 221, 232, 240), // Blue tint
      const Color.fromARGB(208, 240, 232, 221), // Orange tint
      const Color.fromARGB(208, 232, 221, 240), // Purple tint
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        final color = colors[index % colors.length];
        return CollectionSummaryCard(
          title: collection.name,
          subtitle: '${collection.recipeCount} công thức',
          backgroundColor: color,
          icon: Icons.folder_rounded,
          iconColor: AppTheme.accentGreen,
          onTap: () async {
            final deleted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => CollectionDetailScreen(
                  collectionId: collection.id,
                  collectionName: collection.name,
                ),
              ),
            );
            // Reload collections if one was deleted
            if (deleted == true) {
              await onCollectionDeleted();
            }
          },
        );
      },
    );
  }
}

