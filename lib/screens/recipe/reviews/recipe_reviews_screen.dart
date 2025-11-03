import 'package:flutter/material.dart';
import 'package:test_ui_app/screens/recipe/reviews/widgets/rating_comment_tile.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';

class RecipeReviewsScreen extends StatefulWidget {
  final String recipeId;
  final String? recipeTitle;
  final double initialAvg;
  final int initialTotal;
  final int initialTotalImages;
  final List<Map<String, dynamic>> initialRatings;
  final List<Map<String, dynamic>> initialImagesPreview;

  const RecipeReviewsScreen({
    super.key,
    required this.recipeId,
    this.recipeTitle,
    this.initialAvg = 0,
    this.initialTotal = 0,
    this.initialTotalImages = 0,
    this.initialRatings = const <Map<String, dynamic>>[],
    this.initialImagesPreview = const <Map<String, dynamic>>[],
  });

  @override
  State<RecipeReviewsScreen> createState() => _RecipeReviewsScreenState();
}

class _RecipeReviewsScreenState extends State<RecipeReviewsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _ratings = const [];
  List<Map<String, dynamic>> _imagesPreview = const [];
  double _avg = 0;
  int _total = 0;
  int _totalImages = 0;
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _ratings = List<Map<String, dynamic>>.from(widget.initialRatings);
    _imagesPreview =
        List<Map<String, dynamic>>.from(widget.initialImagesPreview);
    _avg = widget.initialAvg;
    _total = widget.initialTotal;
    _totalImages = widget.initialTotalImages;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReviews();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews({bool loadMore = false}) async {
    if (loadMore) {
      if (_loadingMore || (_page >= _totalPages && _totalPages != 0)) return;
    } else if (_loading) {
      return;
    }
    final targetPage = loadMore ? _page + 1 : 1;
    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });
    try {
      final result = await RecipeApiService.getRecipeRatings(
        widget.recipeId,
        page: targetPage,
        limit: 10,
      );
      if (!mounted) return;
      final ratings = (result['ratings'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final imagePreview =
          (result['imagesPreview'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      setState(() {
        _avg = (result['avgRating'] is num)
            ? (result['avgRating'] as num).toDouble()
            : _avg;
        _total = result['totalRatings'] ?? _total;
        _totalImages = result['totalImages'] ?? _totalImages;
        _page = result['page'] ?? targetPage;
        _totalPages = result['totalPages'] ?? _totalPages;
        if (loadMore) {
          _ratings = [..._ratings, ...ratings];
          if (imagePreview.isNotEmpty) {
            _imagesPreview = [..._imagesPreview, ...imagePreview];
          }
        } else {
          _ratings = ratings;
          if (imagePreview.isNotEmpty) {
            _imagesPreview = imagePreview;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải đánh giá: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _loadingMore = false;
        } else {
          _loading = false;
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore) {
      _fetchReviews(loadMore: true);
    }
  }

  List<String> _resolvePreviewUrls() {
    final urls = <String>[];
    for (final item in _imagesPreview) {
      final raw = item['url']?.toString();
      if (raw == null || raw.trim().isEmpty) continue;
      final resolved = RecipeApiService.resolveImageUrl(raw);
      if (resolved.isNotEmpty) {
        urls.add(resolved);
      }
    }
    return urls;
  }

  String _summaryText() {
    final parts = <String>['$_total đánh giá'];
    if (_totalImages > 0) {
      parts.add('$_totalImages ảnh');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final previewUrls = _resolvePreviewUrls();
    final extraCount =
        (_totalImages - previewUrls.length).clamp(0, _totalImages);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá'),
        titleTextStyle: TextStyle(
            fontSize: 24,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchReviews(loadMore: false),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.recipeTitle != null &&
                widget.recipeTitle!.trim().isNotEmpty) ...[
              Text(
                widget.recipeTitle!.trim(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text(
                  _avg.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final ratingValue = index + 1;
                        final full = _avg.floor();
                        final hasHalf = (_avg - full) >= 0.5;
                        if (ratingValue <= full) {
                          return const Icon(Icons.star,
                              size: 18, color: AppTheme.primaryOrange);
                        }
                        if (ratingValue == full + 1 && hasHalf) {
                          return const Icon(Icons.star_half,
                              size: 18, color: AppTheme.primaryOrange);
                        }
                        return const Icon(Icons.star_border,
                            size: 18, color: AppTheme.primaryOrange);
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summaryText(),
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
            if (previewUrls.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: previewUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = previewUrls[index];
                    final isLast =
                        index == previewUrls.length - 1 && extraCount > 0;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        if (isLast)
                          Container(
                            width: 100,
                            height: 100,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+$extraCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_ratings.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.reviews_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có đánh giá nào.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            ..._ratings
                .map((data) => RatingCommentTile(
                      data: data,
                      expanded: true,
                      recipeId: widget.recipeId,
                      onDeleted: () => _fetchReviews(),
                    ))
                .toList(),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
