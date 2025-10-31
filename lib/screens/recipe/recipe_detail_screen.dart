import 'package:flutter/material.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/screens/recipe/collection/add_recipe_to_collection_sheet.dart';
import 'package:test_ui_app/screens/recipe/recipe_form_screen.dart';
import 'package:test_ui_app/screens/shopping/add_to_list_bottom_sheet.dart';
import 'package:test_ui_app/screens/recipe/reviews/recipe_review_form_screen.dart';
import 'package:test_ui_app/screens/recipe/reviews/recipe_reviews_screen.dart';
import 'package:test_ui_app/screens/recipe/reviews/widgets/rating_comment_tile.dart';
import 'package:share_plus/share_plus.dart';

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
      return AppTheme.secondaryYellow;
    case 'hard':
    case 'kho':
    case 'khó':
      return AppTheme.errorRed;
    default:
      return AppTheme.primaryOrange;
  }
}

String _categoryLabel(String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'dinner':
      return 'Món chính';
    case 'lunch':
      return 'Ăn trưa';
    case 'breakfast':
      return 'Ăn sáng';
    case 'dessert':
      return 'Tráng miệng';
    case 'beverage':
      return 'Đồ uống';
    case 'snack':
      return 'Ăn vặt';
    case 'vegan':
      return 'Thuần chay';
    case 'other':
      return 'Khác';
    default:
      return value;
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
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getUser();
    if (!mounted) return;
    setState(() => _currentUserId = user?.id);
  }

  Future<void> _shareRecipe(Recipe recipe) async {
    final buffer = StringBuffer('Khám phá công thức ${recipe.title}');
    final description = recipe.description.trim();
    if (description.isNotEmpty) {
      buffer
        ..write('\n\n')
        ..write(description);
    }
    await Share.share(buffer.toString());
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
      builder: (_) => AddToShoppingListSheet(recipe: recipe),
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

  /// Kiểm tra xem user hiện tại đã đánh giá công thức này chưa
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

    // Kiểm tra xem user đã đánh giá chưa
    final existingRating = _getUserRating(recipe);
    
    if (existingRating != null) {
      // Đã đánh giá → chuyển đến màn hình reviews
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

  List<String> _ratingPreviewUrls(Recipe recipe) {
    final urls = <String>[];

    for (final item in recipe.ratingImagesPreview) {
      final raw = item['url']?.toString();

      if (raw == null || raw.trim().isEmpty) continue;

      final resolved = RecipeApiService.resolveImageUrl(raw);

      if (resolved.isNotEmpty) {
        urls.add(resolved);
      }
    }

    return urls;
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
                    backgroundColor: const Color.fromARGB(95, 220, 220, 220),
                    foregroundColor: Colors.black87,
                    overlayColor: Colors.grey.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Recipe>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryOrange));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 48),
                      const SizedBox(height: 16),
                      Text('Có lỗi xảy ra',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
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
            _favorite = recipe.isFavorite;
            _avg = recipe.avgRating;
            _total = recipe.totalRatings;

            final totalTime = recipe.prepTime + recipe.cookTime;
            final difficultyColor = _difficultyColor(recipe.difficulty);
            final difficultyLabel = _difficultyLabel(recipe.difficulty);
            final categoryLabel = _categoryLabel(recipe.category);
            final canManage = _currentUserId != null &&
                (recipe.userId ?? '').isNotEmpty &&
                recipe.userId == _currentUserId;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header với ảnh
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 300,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_outlined,
                          color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Chia sẻ',
                        onPressed: () => _shareRecipe(recipe),
                        icon: const Icon(Icons.share_outlined,
                            color: AppTheme.primaryOrange),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Thêm vào bộ sưu tập',
                        onPressed: () => _openAddToCollectionSheet(recipe),
                        icon: const Icon(Icons.bookmark_add_outlined,
                            color: AppTheme.primaryOrange),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: _favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  final isFav =
                                      await RecipeApiService.toggleFavorite(
                                          recipe.id);
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
                        icon: Icon(
                            _favorite ? Icons.favorite : Icons.favorite_border,
                            color: AppTheme.primaryOrange),
                      ),
                    ),
                    if (canManage)
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeFormScreen(recipeId: recipe.id)),
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
                              child: Text('Xoá',
                                  style: TextStyle(color: AppTheme.errorRed)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'recipe_${recipe.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryYellow.withOpacity(0.2),
                        ),
                        child: recipe.imageUrl.isEmpty
                            ? const Center(
                                child: Icon(Icons.restaurant_menu,
                                    size: 80, color: AppTheme.textLight))
                            : Image.network(
                                recipe.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 80, color: AppTheme.textLight),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                // Nội dung chính
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề
                          Text(
                            recipe.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 12),

                          // Thông tin tác giả
                          _AuthorBanner(recipe: recipe),
                          const SizedBox(height: 20),

                          // Thông tin cơ bản
                          _InfoCard(
                            recipe: recipe,
                            totalTime: totalTime,
                            categoryLabel: categoryLabel,
                            difficultyLabel: difficultyLabel,
                            difficultyColor: difficultyColor,
                          ),
                          const SizedBox(height: 20),

                          // Rating summary - Chỉ hiển thị nếu không phải công thức của user
                          if (!canManage) ...[
                            if (_avg > 0 || _total > 0)
                              _RatingCard(
                                avg: _avg,
                                total: _total,
                                onRate: () => _openRateForm(recipe),
                                busy: _busy,
                              )
                            else
                              // Hiển thị nút đánh giá khi chưa có đánh giá nào
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryOrange.withOpacity(0.1),
                                      AppTheme.secondaryYellow.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          AppTheme.primaryOrange.withOpacity(0.2)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.star_outline,
                                      color: AppTheme.primaryOrange,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Chưa có đánh giá nào',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Hãy là người đầu tiên đánh giá công thức này',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.textLight),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _busy
                                            ? null
                                            : () => _openRateForm(recipe),
                                        icon: const Icon(Icons.star_rate_rounded),
                                        label: const Text('Viết đánh giá đầu tiên'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],

                          // Tags
                          if (recipe.tags.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: recipe.tags.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '#$t',
                                    style: const TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Mô tả
                          _SectionCard(
                            icon: Icons.description_outlined,
                            title: 'Mô tả',
                            child: Text(
                              recipe.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dinh dưỡng
                          if (recipe.nutrition.isNotEmpty) ...[
                            _SectionCard(
                              icon: Icons.health_and_safety_outlined,
                              title: 'Giá trị dinh dưỡng',
                              child:
                                  _NutritionGrid(nutrition: recipe.nutrition),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Nguyên liệu
                          _SectionCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Nguyên liệu (${recipe.ingredients.length})',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: (recipe.ingredients.isEmpty ||
                                            _addingToShoppingList)
                                        ? null
                                        : () => _addIngredientsToShoppingList(
                                            recipe),
                                    icon: Icon(
                                      _addingToShoppingList
                                          ? Icons.hourglass_empty
                                          : Icons.add_shopping_cart_outlined,
                                      size: 20,
                                    ),
                                    label: Text(_addingToShoppingList
                                        ? 'Đang thêm...'
                                        : 'Thêm vào danh sách mua sắm'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...recipe.ingredients.map((i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(
                                                top: 8, right: 12),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryOrange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${i.quantity} ${i.unit} - ${i.name}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(height: 1.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Các bước
                          _SectionCard(
                            icon: Icons.format_list_numbered,
                            title: 'Cách thực hiện',
                            child: Column(
                              children: recipe.instructions
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final step = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryOrange,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            step.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(height: 1.6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Đánh giá - Luôn hiển thị
                          Builder(
                            builder: (context) {
                              final previewImages = _ratingPreviewUrls(recipe);

                              final extraCount =
                                  (recipe.totalRatingImages - previewImages.length)
                                      .clamp(0, 999);

                              // Logic cho nút trailing
                              final showRateButton = recipe.ratings.isEmpty && !canManage;
                              final buttonText = showRateButton ? 'Đánh giá' : 'Xem tất cả';
                              final buttonAction = showRateButton
                                  ? () => _openRateForm(recipe)
                                  : () => _openReviewsScreen(recipe);

                              return _SectionCard(
                                icon: Icons.chat_bubble_outline,
                                title: 'Đánh giá gần đây',
                                trailing: TextButton(
                                  onPressed: buttonAction,
                                  child: Text(buttonText),
                                ),
                                child: recipe.ratings.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24.0),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.rate_review_outlined,
                                                size: 48,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Chưa có đánh giá nào',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      color: AppTheme.textLight,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _reviewSummaryText(recipe),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color: AppTheme.textLight),
                                          ),
                                          if (previewImages.isNotEmpty) ...[
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              height: 88,
                                              child: ListView.separated(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: previewImages.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(width: 8),
                                                itemBuilder: (context, index) {
                                                  final url =
                                                      previewImages[index];

                                                  final isLast = index ==
                                                          previewImages.length -
                                                              1 &&
                                                      extraCount > 0;

                                                  return Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                12),
                                                        child: Image.network(
                                                          url,
                                                          width: 88,
                                                          height: 88,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (_, __, ___) =>
                                                                  Container(
                                                            width: 88,
                                                            height: 88,
                                                            alignment: Alignment
                                                                .center,
                                                            color: Colors
                                                                .grey.shade200,
                                                            child: const Icon(Icons
                                                                .broken_image_outlined),
                                                          ),
                                                        ),
                                                      ),
                                                      if (isLast)
                                                        Container(
                                                          width: 88,
                                                          height: 88,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.4),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            '+$extraCount',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          ...recipe.ratings
                                              .take(2)
                                              .map((data) => RatingCommentTile(
                                                    data: data,
                                                    recipeId: recipe.id,
                                                    onDeleted: _reload,
                                                  ))
                                              .toList(),
                                          if (recipe.ratings.length > 2 ||
                                              recipe.totalRatings >
                                                  recipe.ratings.length)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _openReviewsScreen(recipe),
                                                child: const Text(
                                                    'Xem tất cả đánh giá'),
                                              ),
                                            ),
                                        ],
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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
}

// Widget tác giả
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
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
          backgroundImage: (avatar != null && avatar.isNotEmpty)
              ? NetworkImage(avatar)
              : null,
          child: (avatar == null || avatar.isEmpty)
              ? Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                      fontSize: 18),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Người tạo công thức',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Card thông tin cơ bản
class _InfoCard extends StatelessWidget {
  final Recipe recipe;
  final int totalTime;
  final String categoryLabel;
  final String difficultyLabel;
  final Color difficultyColor;

  const _InfoCard({
    required this.recipe,
    required this.totalTime,
    required this.categoryLabel,
    required this.difficultyLabel,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.access_time_outlined,
              label: '$totalTime phút',
              subtitle: 'Thời gian',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _InfoItem(
              icon: Icons.restaurant_outlined,
              label: '${recipe.servings}',
              subtitle: 'Khẩu phần',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _InfoItem(
              icon: Icons.leaderboard,
              label: difficultyLabel,
              subtitle: 'Độ khó',
              color: difficultyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.primaryOrange;
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Card đánh giá
class _RatingCard extends StatelessWidget {
  final double avg;
  final int total;
  final VoidCallback onRate;
  final bool busy;

  const _RatingCard({
    required this.avg,
    required this.total,
    required this.onRate,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.secondaryYellow.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final full = avg.floor();
                      final hasHalf = (avg - full) >= 0.5;
                      if (i < full) {
                        return const Icon(Icons.star,
                            color: AppTheme.primaryOrange, size: 18);
                      }
                      if (i == full && hasHalf) {
                        return const Icon(Icons.star_half,
                            color: AppTheme.primaryOrange, size: 18);
                      }
                      return const Icon(Icons.star_border,
                          color: AppTheme.primaryOrange, size: 18);
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total đánh giá',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onRate,
              icon: const Icon(Icons.star_rate_rounded),
              label: const Text('Viết đánh giá'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section card wrapper
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// Grid dinh dưỡng
class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.nutrition});

  final Map<String, dynamic> nutrition;

  @override
  Widget build(BuildContext context) {
    final entries = nutrition.entries
        .where((entry) =>
            entry.value != null && entry.value.toString().trim().isNotEmpty)
        .toList();
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((entry) {
        final key = entry.key.toString();
        final value = entry.value.toString();
        return Container(
          width: (MediaQuery.of(context).size.width - 84) / 2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textLight),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGreen,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Tile đánh giá
