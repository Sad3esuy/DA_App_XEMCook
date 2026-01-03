import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/recipe.dart';
import '../model/home_feed.dart';
import '../model/user.dart';
import '../services/auth_service.dart';
import '../services/favorite_state.dart';
import '../services/recipe_api_service.dart';
import '../services/notification_api_service.dart';
import '../theme/app_theme.dart';
import 'recipe/recipe_collection_screen.dart';
import 'recipe/recipe_detail_screen.dart';
import 'recipe/recipe_form_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/chef_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  bool _isLoading = true;
  HomeFeed? _homeFeed;
  bool _isFeedLoading = true;
  String? _feedError;
  
  // Local tracking is redundant if we use Provider for ids and HomeFeed for counts
  // But we keep _favoriteBusy to prevent double taps
  final Set<String> _favoriteBusy = {}; 

  final PageController _recipeOfTheDayController =
      PageController(viewportFraction: 0.88);
  int _recipeOfTheDayIndex = 0;
  int _unreadNotificationCount = 0;
  late final FavoriteState _favoriteState;
  late Set<String> _favoriteIds;
  VoidCallback? _favoriteListener;

  @override
  void initState() {
    super.initState();
    
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _fetchHomeFeed();
      _loadNotificationSummary();
    });
  }

  Future<void> _fetchHomeFeed() async {
    if (!mounted) return;
    setState(() {
      _isFeedLoading = true;
      _feedError = null;
    });

    try {
      final feed = await RecipeApiService.getHomeFeed();
      if (!mounted) return;
      
      // Sync initial favorite state
      context.read<FavoriteState>().absorbRecipes(feed.collectUniqueRecipes());
      
      setState(() {
        _homeFeed = feed;
        _isFeedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFeedLoading = false;
        _feedError = e.toString();
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = await context.read<AuthService>().getUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _loadNotificationSummary() async {
    try {
      final summary = await NotificationApiService.getSummary();
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = summary.unreadCount;
      });
    } catch (_) {
      // Ignore summary errors silently for now.
    }
  }

  // Future<void> _refreshHomeFeed() {
  //   final future = _fetchHomeFeed();
  //   setState(() {
  //     _homeFeedFuture = future;
  //     _recipeOfTheDayIndex = 0;
  //   });
  //   if (_recipeOfTheDayController.hasClients) {
  //     _recipeOfTheDayController.jumpToPage(0);
  //   }
  //   _loadNotificationSummary();
  //   return future;
  // }

  @override
  void dispose() {
    _recipeOfTheDayController.dispose();
    super.dispose();
  }

  Future<void> _handleFavoriteToggle(Recipe recipe) async {
    final recipeId = recipe.id;
    if (_favoriteBusy.contains(recipeId)) return;
    
    final favoriteState = context.read<FavoriteState>();
    // Determine new state based on current favorite state
    final isCurrentlyFavorite = favoriteState.isFavorite(recipeId);
    final nextValue = !isCurrentlyFavorite;
    
    setState(() {
      _favoriteBusy.add(recipeId);
      
      // OPTIMISTIC UPDATE FOR COUNT
      // Update local HomeFeed state to reflect the change in count immediately
      if (_homeFeed != null) {
        _homeFeed = _homeFeed!.updateRecipe(recipeId, (r) {
           int newCount = r.totalRatings;
           if (nextValue) {
             newCount++;
           } else {
             newCount = (newCount > 0) ? newCount - 1 : 0;
           }
           return r.copyWith(totalRatings: newCount, isFavorite: nextValue);
        });
      }
    });

    // Optimistic update for global favorite state (icon color)
    favoriteState.setFavorite(recipeId, nextValue);
    
    try {
      final isFavorite = await favoriteState.toggleFavorite(recipeId);
      if (!mounted) return;
      
      setState(() {
        _favoriteBusy.remove(recipeId);
        
        // Correct count if server returned different favorite status
        if (isFavorite != nextValue && _homeFeed != null) {
           _homeFeed = _homeFeed!.updateRecipe(recipeId, (r) {
             // Revert or adjust based on actual server result if needed
             // Simplest is to strict set based on isFavorite
             int newCount = r.totalRatings; 
             // If we thought it was true (added 1) but it's false, subtract 1
             if (nextValue && !isFavorite) newCount--;
             // If we thought it was false (sub 1) but it's true, add 1
             if (!nextValue && isFavorite) newCount++;
             
             return r.copyWith(totalRatings: newCount, isFavorite: isFavorite);
           });
        }
      });
      
      if (isFavorite != nextValue) {
        favoriteState.setFavorite(recipeId, isFavorite);
      }
    } catch (e) {
      if (!mounted) return;
       // Revert optimistic updates
      setState(() {
        _favoriteBusy.remove(recipeId);
         if (_homeFeed != null) {
            _homeFeed = _homeFeed!.updateRecipe(recipeId, (r) {
               int newCount = r.totalRatings;
               if (nextValue) {
                 newCount--; // was added, so remove
               } else {
                 newCount++; // was removed, so add
               }
               return r.copyWith(totalRatings: newCount, isFavorite: !nextValue);
            });
         }
      });
      favoriteState.setFavorite(recipeId, !nextValue); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
      );
    }
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
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryOrange,
        onPressed: () async {
          final created =
              await Navigator.of(context, rootNavigator: true).push<bool>(
            MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
          );
          if (created == true && mounted) {
            await _fetchHomeFeed();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_isFeedLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_feedError != null) {
               return _ErrorState(
                message: _feedError!,
                onRetry: _fetchHomeFeed,
              );
            }

            final feed = _homeFeed;
            if (feed == null) {
               return _EmptyState(onCreate: _openCreateRecipe);
            }

            final allRecipes = feed.collectUniqueRecipes();
            if (allRecipes.isEmpty) {
              return _EmptyState(onCreate: _openCreateRecipe);
            }

            final creators = _collectCreators(allRecipes);
            final topRated = feed.topRated.take(10).toList();
            final mostViewed = feed.mostViewed.take(10).toList();
            final quickMeals = feed.quickMeals.take(10).toList();
            final seasonalRecipes = feed.seasonal.recipes.take(10).toList();

            return RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: _fetchHomeFeed,
              child: ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  if (feed.recipeOfTheDay.hasRecipes) ...[
                    _buildRecipeOfTheDayCarousel(feed.recipeOfTheDay),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04), // Responsive spacing
                  ],
                  if (topRated.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Đánh giá cao nhất',
                      actionLabel: 'Xem tất cả',
                      onActionTap: () => _openCollection(
                        const RecipeCollectionConfig(title: 'Đánh giá cao nhất'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LatestRecipesStrip(
                      recipes: topRated,
                      onRecipeTap: _openRecipeDetail,
                      favoriteIds: context.watch<FavoriteState>().ids,
                      onToggleFavorite: _handleFavoriteToggle,
                      favoriteBusy: _favoriteBusy,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  ],
                  if (mostViewed.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Xem nhiều nhất',
                      actionLabel: 'Xem tất cả',
                      onActionTap: () => _openCollection(
                        const RecipeCollectionConfig(
                          title: 'Xem nhiều nhất',
                          initialSort: RecipeCollectionSort.views,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LatestRecipesStrip(
                      recipes: mostViewed,
                      onRecipeTap: _openRecipeDetail,
                      favoriteIds: context.watch<FavoriteState>().ids,
                      onToggleFavorite: _handleFavoriteToggle,
                      favoriteBusy: _favoriteBusy,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  ],
                  if (quickMeals.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Món nhanh - 20 phút',
                      actionLabel: 'Xem tất cả',
                      onActionTap: () => _openCollection(
                        const RecipeCollectionConfig(
                          title: 'Món nhanh',
                          subtitle: 'Sẵn sàng trong 20 phút hoặc ít hơn',
                          initialMaxTotalTime: 20,
                          initialSort: RecipeCollectionSort.totalTime,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LatestRecipesStrip(
                      recipes: quickMeals,
                      onRecipeTap: _openRecipeDetail,
                      favoriteIds: context.watch<FavoriteState>().ids,
                      onToggleFavorite: _handleFavoriteToggle,
                      favoriteBusy: _favoriteBusy,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  ],
                  if (feed.seasonal.hasRecipes &&
                      seasonalRecipes.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Món theo mùa',
                      actionLabel: 'Xem tất cả',
                      onActionTap: () => _openCollection(
                        RecipeCollectionConfig(
                          title: feed.seasonal.label,
                          subtitle: 'Món theo mùa được tuyển chọn cho bạn',
                          initialDietTags: feed.seasonal.tags,
                          initialTimeframe: 'month',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feed.seasonal.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                    if (feed.seasonal.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SeasonalTagRow(tags: feed.seasonal.tags),
                    ],
                    const SizedBox(height: 16),
                    _LatestRecipesStrip(
                      recipes: seasonalRecipes,
                      onRecipeTap: _openRecipeDetail,
                      favoriteIds: context.watch<FavoriteState>().ids,
                      onToggleFavorite: _handleFavoriteToggle,
                      favoriteBusy: _favoriteBusy,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  ],
                  if (creators.isNotEmpty) ...[
                    Text(
                      'Đầu bếp yêu thích',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _CreatorStrip(
                      creators: creators,
                      onTap: _openChefProfile,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Helper for refresh indicator
  Future<void> _refreshHomeFeed() => _fetchHomeFeed();

  void _openCollection(RecipeCollectionConfig config) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => RecipeCollectionScreen(config: config),
      ),
    );
  }

  void _openCreateRecipe() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
    );
  }

  void _openChefProfile(_AuthorProfile profile) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChefProfileScreen(
          userId: profile.id,
          initialName: profile.name,
          initialAvatar: profile.avatar,
        ),
      ),
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
                'Hé lô, $displayName 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hôm nay ăn gì?',
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
            color:
                const Color.fromARGB(255, 71, 186, 232).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppTheme.primaryOrange,
                  onPressed: () async {
                    await Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                    if (!mounted) return;
                    await _loadNotificationSummary();
                  },
                ),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(231, 248, 41, 41),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _unreadNotificationCount > 9
                          ? '9+'
                          : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeOfTheDayCarousel(RecipeOfDaySection section) {
    final recipes = section.recipes;
    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }
    final subtitle = _formatRecipeOfDaySubtitle(section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Công thức trong ngày',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4, // Responsive height
          child: PageView.builder(
            controller: _recipeOfTheDayController,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: recipes.length,
            onPageChanged: (index) =>
                setState(() => _recipeOfTheDayIndex = index),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: EdgeInsets.only(
                    right: index == recipes.length - 1 ? 0 : 16),
                child: _FeaturedRecipeBanner(
                  recipe: recipe,
                  label: 'Công thức trong ngày',
                  onTap: () => _openRecipeDetail(recipe),
                  isFavorite: context.watch<FavoriteState>().isFavorite(recipe.id),
                  onToggleFavorite: () => _handleFavoriteToggle(recipe),
                  isFavoriteBusy: _favoriteBusy.contains(recipe.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _DotsIndicator(
          count: recipes.length,
          index: _recipeOfTheDayIndex.clamp(0, recipes.length - 1),
        ),
      ],
    );
  }

  String? _formatRecipeOfDaySubtitle(RecipeOfDaySection section) {
    final parsed = section.parsedDate;
    if (parsed == null) {
      return section.date.isEmpty ? null : 'Lựa chọn hàng ngày • ${section.date}';
    }
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const months = [
      'Th1',
      'Th2',
      'Th3',
      'Th4',
      'Th5',
      'Th6',
      'Th7',
      'Th8',
      'Th9',
      'Th10',
      'Th11',
      'Th12'
    ];
    final weekday = weekdays[parsed.weekday - 1];
    final month = months[parsed.month - 1];
    final day = parsed.day.toString().padLeft(2, '0');
    return 'Lựa chọn hàng ngày • $weekday, $day $month';
  }

  List<_AuthorProfile> _collectCreators(List<Recipe> recipes) {
    final seen = <String>{};
    final result = <_AuthorProfile>[];
    for (final recipe in recipes) {
      final id = (recipe.authorId ?? recipe.userId ?? '').trim();
      final name = (recipe.authorName ?? '').trim();
      if (id.isEmpty || name.isEmpty) continue;
      if (seen.add(id)) {
        result.add(
          _AuthorProfile(
            id: id,
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
  const _FeaturedRecipeBanner({
    required this.recipe,
    required this.onTap,
    this.label = "Công thức hôm nay",
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.isFavoriteBusy,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final String label;
  final bool isFavorite;
  final Future<void> Function() onToggleFavorite;
  final bool isFavoriteBusy;

  @override
  Widget build(BuildContext context) {
    final authorName =
        (recipe.authorName ?? '').isEmpty ? 'Đầu bếp ẩn danh' : recipe.authorName!;
    int likes = recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;
    if (isFavorite && !recipe.isFavorite) {
      likes++;
    } else if (!isFavorite && recipe.isFavorite) {
      likes = (likes > 0) ? likes - 1 : 0;
    }

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
                      CachedNetworkImage(
                        imageUrl: recipe.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) =>
                            const _ImageFallback(),
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
                      label,
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
                        _HomeFavoritePill(
                          count: likes,
                          isFavorite: isFavorite,
                          isBusy: isFavoriteBusy,
                          onPressed: onToggleFavorite,
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
}

class _LatestRecipesStrip extends StatelessWidget {
  const _LatestRecipesStrip({
    required this.recipes,
    required this.onRecipeTap,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.favoriteBusy,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;
  final Set<String> favoriteIds;
  final Future<void> Function(Recipe) onToggleFavorite;
  final Set<String> favoriteBusy;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Text(
        'Thêm công thức để giữ nguồn cảm hứng.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35, // Responsive height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _LatestRecipeCard(
            recipe: recipe,
            onTap: () => onRecipeTap(recipe),
            isFavorite: favoriteIds.contains(recipe.id),
            onToggleFavorite: () => onToggleFavorite(recipe),
            isFavoriteBusy: favoriteBusy.contains(recipe.id),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemCount: recipes.length,
      ),
    );
  }
}

class _LatestRecipeCard extends StatelessWidget {
  const _LatestRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.isFavoriteBusy,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final bool isFavorite;
  final Future<void> Function() onToggleFavorite;
  final bool isFavoriteBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTime = recipe.prepTime + recipe.cookTime;
    int likes = recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;
    if (isFavorite && !recipe.isFavorite) {
      likes++;
    } else if (!isFavorite && recipe.isFavorite) {
      likes = (likes > 0) ? likes - 1 : 0;
    }

    final chips = <_RecipeChip>[];
    void addChip(_RecipeChip chip) {
      if (chips.length < 3) {
        chips.add(chip);
      }
    }

    if (recipe.avgRating > 0) {
      addChip(
        _RecipeChip(
          label: '${recipe.avgRating.toStringAsFixed(1)} ★',
          background: const Color(0xFFFFF4E5),
          foreground: AppTheme.primaryOrange,
        ),
      );
    }
    if (totalTime > 0) {
      addChip(
        _RecipeChip(
          label: '$totalTime min',
          background: const Color(0xFFFFEDCF),
          foreground: AppTheme.textDark,
        ),
      );
    }
    // if (recipe.viewCount > 0) {
    //   addChip(
    //     _RecipeChip(
    //       label: '${recipe.viewCount} views',
    //       background: const Color(0xFFE6F0FF),
    //       foreground: const Color(0xFF1B74E4),
    //     ),
    //   );
    // }
    final tag = recipe.tags.isNotEmpty ? recipe.tags.first.trim() : '';
    if (tag.isNotEmpty) {
      addChip(
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
        width: MediaQuery.of(context).size.width * 0.6, // Responsive width
        constraints: const BoxConstraints(maxWidth: 260, minWidth: 200),
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
              height: 180,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration:
                          const BoxDecoration(color: AppTheme.secondaryYellow),
                      child: recipe.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (_, __, ___) =>
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
                    child: _HomeFavoritePill(
                      count: likes,
                      isFavorite: isFavorite,
                      isBusy: isFavoriteBusy,
                      onPressed: onToggleFavorite,
                    ),
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
                            authorName.isEmpty ? 'Ẩn danh' : authorName,
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
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final normalized = trimmed.replaceAll(RegExp(r'\s+'), '_');
    return '#$normalized';
  }
}

class _HomeFavoritePill extends StatelessWidget {
  const _HomeFavoritePill({
    required this.count,
    required this.isFavorite,
    required this.isBusy,
    required this.onPressed,
  });

  final int count;
  final bool isFavorite;
  final bool isBusy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final iconData = isFavorite ? Icons.favorite : Icons.favorite_border;
    final iconColor = isFavorite ? Colors.red : AppTheme.primaryOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isBusy
            ? null
            : () async {
                try {
                  await onPressed.call();
                } catch (_) {
                  // Feedback handled upstream.
                }
              },
        child: Container(
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: isBusy
                ? const SizedBox(
                    key: ValueKey('home-favorite-loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                    ),
                  )
                : Row(
                    key: ValueKey<bool>(isFavorite),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 16, color: iconColor),
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
          ),
        ),
      ),
    );
  }
}

class _CreatorStrip extends StatelessWidget {
  const _CreatorStrip({required this.creators, this.onTap});

  final List<_AuthorProfile> creators;
  final ValueChanged<_AuthorProfile>? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final profile = creators[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap == null ? null : () => onTap!(profile),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
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
                ),
              ),
            ),
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

class _SeasonalTagRow extends StatelessWidget {
  const _SeasonalTagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    final displayTags = tags
        .take(6)
        .map((tag) {
          final clean = tag.trim();
          if (clean.isEmpty) return '';
          final normalized =
              clean.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
          return '#$normalized';
        })
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (displayTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 16 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryOrange
                : AppTheme.primaryOrange.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onActionTap != null;
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
        if (hasAction)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
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
              'Đã xảy ra lỗi',
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
              child: const Text('Thử lại'),
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
              'Hãy cùng nấu nướng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo công thức đầu tiên của bạn để xem nó được giới thiệu ở đây.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Thêm công thức'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorProfile {
  const _AuthorProfile({required this.id, required this.name, this.avatar});

  final String id;
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
