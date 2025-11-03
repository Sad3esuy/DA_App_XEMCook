import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:test_ui_app/model/instruction.dart';
import 'package:test_ui_app/model/ingredient.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/services/favorite_state.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/screens/recipe/collection/add_recipe_to_collection_sheet.dart';
import 'package:test_ui_app/screens/recipe/recipe_form_screen.dart';
import 'package:test_ui_app/screens/shopping/add_to_list_bottom_sheet.dart';
import 'package:test_ui_app/screens/recipe/reviews/recipe_review_form_screen.dart';
import 'package:test_ui_app/screens/recipe/reviews/recipe_reviews_screen.dart';
import 'package:test_ui_app/screens/recipe/reviews/widgets/rating_comment_tile.dart';
import 'package:test_ui_app/screens/profile/chef_profile_screen.dart';

String _difficultyLabel(String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'easy':
    case 'dễ':
    case 'de':
      return 'Dễ dàng';
    case 'medium':
    case 'trung binh':
    case 'trung bình':
      return 'Trung bình';
    case 'hard':
    case 'kho':
    case 'khó':
      return 'Khó';
    default:
      return value;
  }
}

Color _difficultyColor(String value) {
  switch (value.trim().toLowerCase()) {
    case 'easy':
    case 'dễ':
    case 'de':
      return AppTheme.accentGreen;
    case 'medium':
    case 'trung binh':
    case 'trung bình':
      return const Color.fromARGB(255, 230, 194, 51);
    case 'hard':
    case 'kho':
    case 'khó':
      return AppTheme.errorRed;
    default:
      return AppTheme.primaryOrange;
  }
}

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
  bool _addingToShoppingList = false;
  int? _servingsOverride;
  late final FavoriteState _favoriteState;
  VoidCallback? _favoriteListener;

  @override
  void initState() {
    super.initState();
    _favoriteState = FavoriteState.instance;
    _favorite = _favoriteState.isFavorite(widget.recipeId);
    _favoriteListener = () {
      if (!mounted) return;
      final synced = _favoriteState.isFavorite(widget.recipeId);
      if (synced != _favorite) {
        setState(() => _favorite = synced);
      }
    };
    _favoriteState.addListener(_favoriteListener!);
    _future = RecipeApiService.getRecipeById(widget.recipeId);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    if (_favoriteListener != null) {
      _favoriteState.removeListener(_favoriteListener!);
    }
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = RecipeApiService.getRecipeById(widget.recipeId);
    });
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getUser();
    if (!mounted) return;
    setState(() => _currentUserId = user?.id);
  }

  Future<void> _openAddToCollectionSheet(Recipe recipe) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddRecipeToCollectionSheet(
        recipeId: recipe.id,
        recipeTitle: recipe.title,
      ),
    );
    if (!mounted) return;
    if (added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm công thức vào bộ sưu tập'),
        ),
      );
    }
  }

  Future<void> _addIngredientsToShoppingList(Recipe recipe) async {
    if (_addingToShoppingList) return;
    if (recipe.ingredients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có nguyên liệu để thêm vào danh sách mua sắm'),
          ),
        );
      }
      return;
    }

    setState(() => _addingToShoppingList = true);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddToShoppingListSheet(
        recipe: recipe,
        initialServings: _resolveCurrentServings(recipe).toDouble(),
      ),
    );
    if (mounted) {
      setState(() => _addingToShoppingList = false);
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Đã thêm nguyên liệu từ "${recipe.title}" vào danh sách'),
          ),
        );
      }
    }
  }

  int _resolveCurrentServings(Recipe recipe) {
    final base = recipe.servings > 0 ? recipe.servings : 1;
    final override = _servingsOverride;
    if (override == null || override <= 0) return base;
    return override;
  }

  void _changeServings(Recipe recipe, int delta) {
    final base = recipe.servings > 0 ? recipe.servings : 1;
    final current = _resolveCurrentServings(recipe);
    var next = current + delta;
    if (next < 1) next = 1;
    if (next > 200) next = 200;
    if (next == current) return;
    setState(() {
      _servingsOverride = next == base ? null : next;
    });
  }

  double _servingsMultiplier(Recipe recipe) {
    final base = recipe.servings > 0 ? recipe.servings : 1;
    final current = _resolveCurrentServings(recipe);
    if (base <= 0) return 1;
    return current / base;
  }

  double? _parseQuantityValue(String quantity) {
    final raw = quantity.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll(',', '.');

    final mixedMatch =
        RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(normalized);
    if (mixedMatch != null) {
      final whole = double.tryParse(mixedMatch.group(1)!);
      final numerator = double.tryParse(mixedMatch.group(2)!);
      final denominator = double.tryParse(mixedMatch.group(3)!);
      if (whole != null && numerator != null && denominator != null) {
        if (denominator == 0) return whole + numerator;
        return whole + numerator / denominator;
      }
    }

    final fractionMatch = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(normalized);
    if (fractionMatch != null) {
      final numerator = double.tryParse(fractionMatch.group(1)!);
      final denominator = double.tryParse(fractionMatch.group(2)!);
      if (numerator != null && denominator != null) {
        if (denominator == 0) return numerator;
        return numerator / denominator;
      }
    }

    final rangeMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*[-–]\s*(\d+(?:\.\d+)?)$')
        .firstMatch(normalized);
    if (rangeMatch != null) {
      final start = double.tryParse(rangeMatch.group(1)!);
      final end = double.tryParse(rangeMatch.group(2)!);
      if (start != null && end != null) {
        return (start + end) / 2;
      }
    }

    final numericMatch = RegExp(r'^-?\d+(?:\.\d+)?$').firstMatch(normalized);
    if (numericMatch != null) {
      return double.tryParse(numericMatch.group(0)!);
    }

    final leadingMatch = RegExp(r'^-?\d+(?:\.\d+)?').firstMatch(normalized);
    if (leadingMatch != null) {
      return double.tryParse(leadingMatch.group(0)!);
    }

    return null;
  }

  String _formatScaledQuantity(Ingredient ingredient, double multiplier) {
    final value = _parseQuantityValue(ingredient.quantity);
    final unit = ingredient.unit.trim();
    if (value == null) {
      final quantity = ingredient.quantity.trim();
      if (quantity.isEmpty) return unit;
      return unit.isEmpty ? quantity : '$quantity $unit';
    }
    final scaled = value * multiplier;
    final formatted = _formatNumber(scaled);
    return unit.isEmpty ? formatted : '$formatted $unit';
  }

  String _formatNumber(double value) {
    final isInteger = (value - value.round()).abs() < 1e-6;
    if (isInteger) return value.round().toString();
    final precision = value < 1 ? 2 : 1;
    var result = value.toStringAsFixed(precision);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  Map<String, dynamic>? _getUserRating(Recipe recipe) {
    if (_currentUserId == null) return null;

    for (final rating in recipe.ratings) {
      final reviewer = rating['reviewer'];
      String? reviewerId;

      if (reviewer is Map) {
        reviewerId = reviewer['_id']?.toString() ?? reviewer['id']?.toString();
      }

      if (reviewerId == _currentUserId) {
        return rating;
      }
    }

    return null;
  }

  Future<void> _openRateForm(Recipe recipe) async {
    if (_busy) return;

    final existingRating = _getUserRating(recipe);

    if (existingRating != null) {
      await _openReviewsScreen(recipe);
      return;
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => RecipeReviewFormScreen(
          recipeId: recipe.id,
          recipeTitle: recipe.title,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final avg = result['avgRating'];
    final total = result['totalRatings'];

    setState(() {
      if (avg is num) {
        _avg = avg.toDouble();
      }
      if (total is int) {
        _total = total;
      }
    });

    await _reload();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá')));
  }

  Future<void> _openReviewsScreen(Recipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeReviewsScreen(
          recipeId: recipe.id,
          recipeTitle: recipe.title,
          initialAvg: _avg,
          initialTotal: recipe.totalRatings,
          initialTotalImages: recipe.totalRatingImages,
          initialRatings:
              List<Map<String, dynamic>>.from(recipe.ratings, growable: false),
          initialImagesPreview: List<Map<String, dynamic>>.from(
              recipe.ratingImagesPreview,
              growable: false),
        ),
      ),
    );
  }

  String _reviewSummaryText(Recipe recipe) {
    final parts = <String>['${recipe.totalRatings} đánh giá'];
    if (recipe.totalRatingImages > 0) {
      parts.add('${recipe.totalRatingImages} ảnh');
    }
    return parts.join(' • ');
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xoá công thức'),
        content: const Text('Bạn chắc chắn muốn xoá công thức này?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Huỷ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Xoá'),
                ),
              ),
            ],
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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _reload,
        color: AppTheme.primaryOrange,
        child: FutureBuilder<Recipe>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryOrange),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Có lỗi xảy ra',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }

            final recipe = snapshot.data!;
            final apiFavorite = recipe.isFavorite;
            final syncedFavorite = _favoriteState.isFavorite(recipe.id);
            final resolvedFavorite = syncedFavorite || apiFavorite;
            if (_favorite != resolvedFavorite) {
              _favorite = resolvedFavorite;
            }
            _favoriteState.setFavorite(recipe.id, resolvedFavorite);
            _avg = recipe.avgRating;
            _total = recipe.totalRatings;

            final totalTime = recipe.prepTime + recipe.cookTime;
            final difficultyColor = _difficultyColor(recipe.difficulty);
            final difficultyLabel = _difficultyLabel(recipe.difficulty);
            final canManage = _currentUserId != null &&
                (recipe.userId ?? '').isNotEmpty &&
                recipe.userId == _currentUserId;
            final currentServings = _resolveCurrentServings(recipe);
            final servingsMultiplier = _servingsMultiplier(recipe);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Image Header
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 450,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  actions: [
                    // _ActionButton(
                    //   icon: Icons.share_outlined,
                    //   onPressed: () => _shareRecipe(recipe),
                    // ),
                    _ActionButton(
                      icon: Icons.bookmark_add_outlined,
                      onPressed: () => _openAddToCollectionSheet(recipe),
                    ),
                    _ActionButton(
                      icon: _favorite ? Icons.favorite : Icons.favorite_border,
                      color: _favorite ? AppTheme.errorRed : null,
                      onPressed: _busy
                          ? null
                          : () async {
                              final nextValue = !_favorite;
                              setState(() {
                                _busy = true;
                                _favorite = nextValue;
                              });
                              _favoriteState.setFavorite(recipe.id, nextValue);
                              try {
                                final isFav = await _favoriteState
                                    .toggleFavorite(recipe.id);
                                if (!mounted) return;
                                setState(() {
                                  _favorite = isFav;
                                  _busy = false;
                                });
                                if (isFav != nextValue) {
                                  _favoriteState.setFavorite(
                                      recipe.id, isFav);
                                }
                              } catch (e) {
                                if (!mounted) return;
                                setState(() {
                                  _favorite = !nextValue;
                                  _busy = false;
                                });
                                _favoriteState.setFavorite(
                                    recipe.id, !nextValue);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            },
                    ),
                    if (canManage)
                      Container(
                        margin:
                            const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeFormScreen(recipeId: recipe.id),
                                ),
                              );
                              if (updated == true) {
                                _reload();
                              }
                            } else if (value == 'delete') {
                              _delete(recipe.id);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Xoá',
                                style: TextStyle(color: AppTheme.errorRed),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'recipe_${recipe.id}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          recipe.imageUrl.isEmpty
                              ? Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      size: 80,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                )
                              : Image.network(
                                  recipe.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 80,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                          // Subtle overlay for better readability
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          recipe.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Author Info
                        _AuthorBanner(recipe: recipe),
                        const SizedBox(height: 24),

                        // Quick Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: _QuickInfoCard(
                                icon: Icons.schedule_outlined,
                                label: '$totalTime phút',
                                subtitle: 'Thời gian',
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickInfoCard(
                                icon: Icons.restaurant_outlined,
                                label: '${recipe.servings}',
                                subtitle: 'Khẩu phần',
                                color: AppTheme.accentGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickInfoCard(
                                icon: Icons.signal_cellular_alt,
                                label: difficultyLabel,
                                subtitle: 'Độ khó',
                                color: difficultyColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        if (recipe.description.trim().isNotEmpty) ...[
                          _SectionTitle(title: 'Mô tả'),
                          const SizedBox(height: 12),
                          _ExpandableDescription(
                              description: recipe.description),
                          const SizedBox(height: 32),
                        ],

                        // Nutrition
                        if (recipe.nutrition.isNotEmpty) ...[
                          _NutritionSection(nutrition: recipe.nutrition),
                          const SizedBox(height: 32),
                        ],

                        // Rating Section
                        if (!canManage) ...[
                          _RatingSection(
                            avg: _avg,
                            total: _total,
                            busy: _busy,
                            onRate: () => _openRateForm(recipe),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Ingredients
                        _SectionTitle(title: 'Nguyên liệu'),
                        const SizedBox(height: 16),

                        // Servings Adjuster
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Khẩu phần',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          const Color.fromARGB(221, 60, 60, 60),
                                    ),
                              ),
                              Row(
                                children: [
                                  _ServingsButton(
                                    icon: Icons.remove,
                                    enabled: currentServings > 1,
                                    onPressed: currentServings <= 1
                                        ? null
                                        : () => _changeServings(recipe, -1),
                                  ),
                                  Container(
                                    width: 56,
                                    height: 40,
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      '$currentServings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryOrange,
                                          ),
                                    ),
                                  ),
                                  _ServingsButton(
                                    icon: Icons.add,
                                    enabled: true,
                                    onPressed: () => _changeServings(recipe, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Ingredients List
                        if (recipe.ingredients.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Chưa có nguyên liệu',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                            ),
                          )
                        else ...[
                          ...recipe.ingredients.asMap().entries.map((entry) {
                            final ingredient = entry.value;
                            final amount = _formatScaledQuantity(
                              ingredient,
                              servingsMultiplier,
                            );
                            final displayAmount =
                                amount.trim().isEmpty ? '—' : amount;

                            return Container(
                              margin: EdgeInsets.only(
                                  bottom:
                                      entry.key == recipe.ingredients.length - 1
                                          ? 0
                                          : 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ingredient.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      displayAmount,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryOrange,
                                          ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),

                        // Add to Shopping List Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (recipe.ingredients.isEmpty ||
                                    _addingToShoppingList)
                                ? null
                                : () => _addIngredientsToShoppingList(recipe),
                            icon: _addingToShoppingList
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.accentGreen),
                                    ),
                                  )
                                : const Icon(Icons.add_shopping_cart_outlined,
                                    size: 20),
                            label: Text(
                              _addingToShoppingList
                                  ? 'Đang thêm...'
                                  : 'Thêm vào danh sách mua sắm',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _addingToShoppingList
                                    ? Colors.grey.shade500
                                    : AppTheme.accentGreen,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: AppTheme.accentGreen,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.accentGreen,
                              overlayColor:
                                  AppTheme.accentGreen.withOpacity(0.08),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Instructions
                        _SectionTitle(title: 'Cách thực hiện'),
                        const SizedBox(height: 16),
                        ...recipe.instructions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == recipe.instructions.length - 1
                                  ? 0
                                  : 4,
                            ),
                            child: _buildInstructionStepCard(
                              context: context,
                              step: step,
                              index: index,
                              total: recipe.instructions.length,
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 32),

                        // Final Result Image
                        if (recipe.imageUrl.isNotEmpty) ...[
                          _SectionTitle(title: 'Thành phẩm'),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                recipe.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: AppTheme.primaryOrange,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Reviews Section
                        _SectionTitle(
                          title: 'Đánh giá',
                          trailing: !canManage
                              ? TextButton(
                                  onPressed: recipe.ratings.isEmpty
                                      ? () => _openRateForm(recipe)
                                      : () => _openReviewsScreen(recipe),
                                  child: Text(
                                    recipe.ratings.isEmpty
                                        ? 'Đánh giá'
                                        : 'Xem tất cả',
                                  ),
                                )
                              : (recipe.ratings.isNotEmpty
                                  ? TextButton(
                                      onPressed: () =>
                                          _openReviewsScreen(recipe),
                                      child: const Text('Xem tất cả'),
                                    )
                                  : null),
                        ),
                        const SizedBox(height: 16),

                        if (recipe.ratings.isEmpty)
                          _EmptyReviews(
                            canManage: canManage,
                            onRate: () => _openRateForm(recipe),
                          )
                        else ...[
                          Text(
                            _reviewSummaryText(recipe),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...recipe.ratings.take(2).map(
                                (data) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: RatingCommentTile(
                                    data: data,
                                    recipeId: recipe.id,
                                    onDeleted: _reload,
                                  ),
                                ),
                              ),
                        ],
                        const SizedBox(height: 32),

                        // Tags
                        if (recipe.tags.isNotEmpty) ...[
                          _SectionTitle(title: 'Tags'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: recipe.tags.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstructionStepCard({
    required BuildContext context,
    required Instruction step,
    required int index,
    required int total,
  }) {
    final rawInstructionImage = (step.imageUrl ?? '').trim();
    final normalizedInstructionImage =
        rawInstructionImage.startsWith('data:image')
            ? rawInstructionImage
            : RecipeApiService.resolveImageUrl(rawInstructionImage);
    final hasInstructionImage = normalizedInstructionImage.isNotEmpty;
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: index == total - 1 ? 0 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header with highlight background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(208, 221, 240, 232),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bước ${index + 1}/$total',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),

          // Step Image (if available) - Show before description
          if (hasInstructionImage) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildInstructionStepImage(
                  normalizedInstructionImage,
                ),
              ),
            ),
          ],

          // Step Description with time highlighting
          SizedBox(height: hasInstructionImage ? 16 : 12),
          _buildInstructionDescription(context, step.description),
        ],
      ),
    );
  }

  Widget _buildInstructionDescription(BuildContext context, String rawText) {
    final trimmed = rawText.trim();
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
          height: 1.7,
          color: Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ) ??
        const TextStyle(
          height: 1.7,
          color: Colors.black87,
          fontSize: 17,
        );

    if (trimmed.isEmpty) {
      return Text(
        trimmed,
        style: baseStyle,
      );
    }

    // Pattern để match các dạng thời gian
    final timePattern = RegExp(
      r'\b\d+(?:[.,]\d+)?\s*(?:h|hr|hrs|hour|hours|m|min|mins|minute|minutes|phút|giờ)\b',
      caseSensitive: false,
    );
    final matches = timePattern.allMatches(trimmed).toList();

    if (matches.isEmpty) {
      return Text(
        trimmed,
        style: baseStyle,
      );
    }

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in matches) {
      // Text trước time badge
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: trimmed.substring(lastIndex, match.start)));
      }

      final matchText = trimmed.substring(match.start, match.end).trim();

      // Time badge với icon clock và màu cam
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  matchText,
                  style: baseStyle.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Text sau time badge cuối cùng
    if (lastIndex < trimmed.length) {
      spans.add(TextSpan(text: trimmed.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  Widget _buildInstructionStepImage(String source) {
    if (source.startsWith('data:image')) {
      final parts = source.split(',');
      final encoded =
          parts.length > 1 ? parts.sublist(1).join(',') : parts.first;
      try {
        final bytes = base64Decode(encoded);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError();
          },
        );
      } catch (_) {
        return _buildImageError();
      }
    }

    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImageError();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryOrange,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đang tải ảnh...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Không thể tải ảnh',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.black87),
        onPressed: onPressed,
      ),
    );
  }
}

// Author Banner Widget
class _AuthorBanner extends StatelessWidget {
  final Recipe recipe;
  const _AuthorBanner({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final avatar = recipe.authorAvatar;
    final displayName =
        (recipe.authorName != null && recipe.authorName!.trim().isNotEmpty)
            ? recipe.authorName!.trim()
            : 'Ẩn danh';
    final authorId = (recipe.authorId ?? recipe.userId ?? '').trim();
    final canOpenProfile = authorId.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryOrange.withOpacity(0.1),
        highlightColor: AppTheme.primaryOrange.withOpacity(0.05),
        onTap: canOpenProfile
            ? () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ChefProfileScreen(
                      userId: authorId,
                      initialName: displayName,
                      initialAvatar: avatar,
                    ),
                  ),
                );
              }
            : null,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                      ? NetworkImage(avatar)
                      : null,
                  child: (avatar == null || avatar.isEmpty)
                      ? Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Người tạo công thức',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (canOpenProfile)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quick Info Card Widget
class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _QuickInfoCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Servings Button Widget
class _ServingsButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ServingsButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? const Color.fromARGB(208, 221, 240, 232)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }
}

// Nutrition Section Widget
class _NutritionSection extends StatelessWidget {
  final Map<String, dynamic> nutrition;

  const _NutritionSection({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final entries = nutrition.entries
        .where((entry) =>
            entry.value != null && entry.value.toString().trim().isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Dinh dưỡng'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: entries.map((entry) {
            return Container(
              width: (MediaQuery.of(context).size.width - 60) / 2,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.accentGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Rating Section Widget
class _RatingSection extends StatelessWidget {
  final double avg;
  final int total;
  final bool busy;
  final VoidCallback onRate;

  const _RatingSection({
    required this.avg,
    required this.total,
    required this.busy,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (avg <= 0 && total <= 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryOrange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline,
                color: AppTheme.primaryOrange,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy là người đầu tiên đánh giá',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onRate,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Viết đánh giá'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final full = avg.floor();
                      final hasHalf = (avg - full) >= 0.5;
                      if (i < full) {
                        return const Icon(Icons.star,
                            color: AppTheme.primaryOrange, size: 20);
                      }
                      if (i == full && hasHalf) {
                        return const Icon(Icons.star_half,
                            color: AppTheme.primaryOrange, size: 20);
                      }
                      return Icon(Icons.star_border,
                          color: Colors.grey.shade400, size: 20);
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total đánh giá',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onRate,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Viết đánh giá'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Expandable Description Widget
class _ExpandableDescription extends StatefulWidget {
  final String description;

  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;
  bool _showReadMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsReadMore();
    });
  }

  void _checkIfNeedsReadMore() {
    final span = TextSpan(
      text: widget.description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: Colors.grey.shade700,
          ),
    );
    final tp = TextPainter(
      text: span,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: MediaQuery.of(context).size.width - 48);

    if (mounted) {
      setState(() {
        _showReadMore = tp.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: Colors.grey.shade700,
        );

    if (_isExpanded) {
      // Khi đã expand, hiển thị toàn bộ text với nút "Thu gọn" ở cuối
      return RichText(
        text: TextSpan(
          style: textStyle,
          children: [
            TextSpan(text: widget.description),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                child: Text(
                  'Thu gọn',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_showReadMore) {
      // Text ngắn, không cần nút
      return Text(
        widget.description,
        style: textStyle,
      );
    }

    // Text dài, hiển thị 2 dòng với nút "Xem thêm" ở cuối
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: widget.description,
          style: textStyle,
        );

        final tp = TextPainter(
          text: span,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        final endPosition = tp.getPositionForOffset(
          Offset(constraints.maxWidth, tp.size.height),
        );

        final endOffset = endPosition.offset;
        String displayText = widget.description;

        if (endOffset < widget.description.length) {
          displayText = widget.description.substring(0, endOffset - 12);
          if (displayText.endsWith(' ')) {
            displayText = displayText.trimRight();
          }
          displayText += '... ';
        }

        return RichText(
          text: TextSpan(
            style: textStyle,
            children: [
              TextSpan(text: displayText),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  child: Text(
                    'Xem thêm',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Empty Reviews Widget
class _EmptyReviews extends StatelessWidget {
  final bool canManage;
  final VoidCallback onRate;

  const _EmptyReviews({
    required this.canManage,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              Text(
                'Chưa có đánh giá',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                canManage
                    ? 'Công thức của bạn chưa có đánh giá nào'
                    : 'Hãy là người đầu tiên chia sẻ ý kiến của bạn',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ));
  }
}
