import 'package:flutter/material.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/services/favorite_state.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/screens/recipe/recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  late Future<List<Recipe>> _future;
  String _query = '';
  String? _category; // null = tất cả
  bool _showMine = false;
  final FavoriteState _favoriteState = FavoriteState.instance;

  static const List<String> _categories = <String>[
    'Món chính',
    'Khai vị',
    'Tráng miệng',
    'Thức uống',
    'Ăn vặt',
    'Khác'
  ];

  Future<List<Recipe>> _fetch() async {
    final q = _query.trim();
    final mappedCat = _mapVNtoBECategory(_category);
    if (_showMine) {
      final list = await RecipeApiService.getMyRecipes();
      // Lọc client-side theo query/category cho danh sách của tôi
      final filtered = list.where((r) {
        final okQuery = q.isEmpty || r.title.toLowerCase().contains(q.toLowerCase()) || r.description.toLowerCase().contains(q.toLowerCase());
        final okCat = mappedCat == null || r.category == mappedCat;
        return okQuery && okCat;
      }).toList();
      _favoriteState.absorbRecipes(filtered);
      return filtered;
    } else {
      final recipes = await RecipeApiService.getAllRecipes(
        search: q.isNotEmpty ? q : null,
        category: mappedCat,
      );
      _favoriteState.absorbRecipes(recipes);
      return recipes;
    }
  }

  String? _mapVNtoBECategory(String? vn) {
    switch (vn) {
      case 'Món chính':
        return 'dinner';
      case 'Khai vị':
        return 'snack';
      case 'Tráng miệng':
        return 'dessert';
      case 'Thức uống':
        return 'beverage';
      case 'Ăn vặt':
        return 'snack';
      case 'Khác':
        return 'other';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _fetch();
    });
    await _future.catchError((_) => <Recipe>[]);
  }

  void _applyFilters() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công thức'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Recipe>>(
          future: _future,
          builder: (context, snapshot) {
            final slivers = <Widget>[
              SliverToBoxAdapter(child: _Header(
                query: _query,
                category: _category,
                categories: _categories,
                showMine: _showMine,
                onQueryChanged: (v) => setState(() => _query = v),
                onSearch: _applyFilters,
                onClearSearch: () {
                  setState(() => _query = '');
                  _applyFilters();
                },
                onCategorySelected: (cat) {
                  setState(() => _category = cat);
                  _applyFilters();
                },
                onToggleMine: (mine) {
                  setState(() => _showMine = mine);
                  _applyFilters();
                },
              )),
            ];

            if (snapshot.connectionState == ConnectionState.waiting) {
              slivers.add(const SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadingView(),
              ));
            } else if (snapshot.hasError) {
              slivers.add(SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorView(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                ),
              ));
            } else {
              final data = snapshot.data ?? const <Recipe>[];
              if (data.isEmpty) {
                slivers.add(SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(onReload: _reload),
                ));
              } else {
                slivers.add(SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) return const SizedBox(height: 12);
                        final itemIndex = index ~/ 2;
                        return _RecipeItem(recipe: data[itemIndex]);
                      },
                      childCount: data.isEmpty ? 0 : data.length * 2 - 1,
                    ),
                  ),
                ));
              }
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: slivers,
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String query;
  final String? category;
  final List<String> categories;
  final bool showMine;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<bool> onToggleMine;

  const _Header({
    required this.query,
    required this.category,
    required this.categories,
    required this.showMine,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onClearSearch,
    required this.onCategorySelected,
    required this.onToggleMine,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: TextEditingController(text: query)
              ..selection = TextSelection.collapsed(offset: query.length),
            onChanged: onQueryChanged,
            onSubmitted: (_) => onSearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm công thức, nguyên liệu...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Khám phá'),
                selected: !showMine,
                selectedColor: AppTheme.primaryOrange.withOpacity(0.15),
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: !showMine ? AppTheme.primaryOrange : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                onSelected: (_) => onToggleMine(false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Của tôi'),
                selected: showMine,
                selectedColor: AppTheme.primaryOrange.withOpacity(0.15),
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: showMine ? AppTheme.primaryOrange : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                onSelected: (_) => onToggleMine(true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Tất cả',
                  selected: category == null,
                  onSelected: () => onCategorySelected(null),
                ),
                const SizedBox(width: 8),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: c,
                        selected: category == c,
                        onSelected: () => onCategorySelected(c),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _CategoryChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryOrange.withOpacity(0.15),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? AppTheme.primaryOrange : AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
      onSelected: (_) => onSelected(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: selected ? AppTheme.primaryOrange : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryOrange),
            SizedBox(height: 12),
            Text('Đang tải dữ liệu...')
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 40),
            const SizedBox(height: 8),
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onReload;
  const _EmptyView({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 40, color: AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              'Bạn hiện chưa có công thức nào',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Kéo xuống để tải lại hoặc thêm công thức mới.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeItem extends StatefulWidget {
  final Recipe recipe;
  const _RecipeItem({required this.recipe});

  @override
  State<_RecipeItem> createState() => _RecipeItemState();
}

class _RecipeItemState extends State<_RecipeItem> {
  late bool _favorite;
  bool _busy = false;
  late final FavoriteState _favoriteState;
  VoidCallback? _favoriteListener;

  @override
  void initState() {
    super.initState();
    _favoriteState = FavoriteState.instance;
    _favorite = widget.recipe.isFavorite ||
        _favoriteState.isFavorite(widget.recipe.id);
    _favoriteListener = () {
      if (!mounted) return;
      final synced = _favoriteState.isFavorite(widget.recipe.id);
      if (synced != _favorite) {
        setState(() => _favorite = synced);
      }
    };
    _favoriteState.addListener(_favoriteListener!);
  }

  @override
  void dispose() {
    if (_favoriteListener != null) {
      _favoriteState.removeListener(_favoriteListener!);
    }
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_busy) return;
    final nextValue = !_favorite;
    setState(() {
      _busy = true;
      _favorite = nextValue;
    });
    _favoriteState.setFavorite(widget.recipe.id, nextValue);
    try {
      final updated = await _favoriteState.toggleFavorite(widget.recipe.id);
      if (mounted) {
        setState(() {
          // toggleFavorite returns a bool (true if now favorite)
          _favorite = updated;
          _busy = false;
        });
        if (updated != nextValue) {
          _favoriteState.setFavorite(widget.recipe.id, updated);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favorite = !nextValue; // revert
          _busy = false;
        });
        _favoriteState.setFavorite(widget.recipe.id, !nextValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipeId: widget.recipe.id),
            ),
          );
          if (changed == true && mounted) {
            context.findAncestorStateOfType<_RecipesScreenState>()?._reload();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _RecipeImage(imageUrl: widget.recipe.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : _toggleFavorite,
                          iconSize: 22,
                          color: AppTheme.primaryOrange,
                          icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
                          tooltip: _favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(icon: Icons.category, label: widget.recipe.category),
                        const SizedBox(width: 8),
                        _Chip(icon: Icons.timer, label: '${widget.recipe.prepTime + widget.recipe.cookTime} phút'),
                        const SizedBox(width: 8),
                        _Chip(icon: Icons.leaderboard, label: widget.recipe.difficulty),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeImage extends StatelessWidget {
  final String imageUrl;
  const _RecipeImage({required this.imageUrl});

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
