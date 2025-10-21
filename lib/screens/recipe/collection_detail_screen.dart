import 'package:flutter/material.dart';
import 'package:test_ui_app/model/collection.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'create_collection_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;
  final String? collectionName;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    this.collectionName,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  Collection? _collection;
  List<Recipe> _recipes = const <Recipe>[];
  List<Recipe> _filteredRecipes = const <Recipe>[];
  bool _loading = true;
  String? _error;
  final Set<String> _favoriteLoading = <String>{};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCollection();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes = _recipes;
      } else {
        _filteredRecipes = _recipes.where((recipe) {
          return recipe.title.toLowerCase().contains(query) ||
              recipe.description.toLowerCase().contains(query) ||
              recipe.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  Future<void> _loadCollection({bool showSpinner = true}) async {
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
      final collection =
          await RecipeApiService.getCollectionById(widget.collectionId);
      if (!mounted) return;

      setState(() {
        _collection = collection;
        // Get recipes from collection if available
        _recipes = collection.recipes ?? [];
        _filteredRecipes = _recipes;
        _loading = false;
        _favoriteLoading.clear();
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
          SnackBar(content: Text('Không thể làm mới: $e')),
        );
      }
    }
  }

  Future<void> _openRecipeDetail(Recipe recipe) async {
    final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
    if (changed == true && mounted) {
      await _loadCollection(showSpinner: false);
    }
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final recipeId = recipe.id;
    if (_favoriteLoading.contains(recipeId)) return;
    setState(() {
      _favoriteLoading.add(recipeId);
    });

    try {
      await RecipeApiService.toggleFavorite(recipeId);
      if (!mounted) return;
      setState(() {
        _favoriteLoading.remove(recipeId);
      });
      // Reload collection to get updated data
      await _loadCollection(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _favoriteLoading.remove(recipeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
      );
    }
  }

  Future<void> _editCollection() async {
    if (_collection == null) return;

    final result = await Navigator.push<Collection>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCollectionScreen(collection: _collection),
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật bộ sưu tập')),
      );
      await _loadCollection(showSpinner: false);
    }
  }

  Future<void> _deleteCollection() async {
    if (_collection == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá bộ sưu tập?'),
        content:
            Text('Bạn có chắc muốn xoá bộ sưu tập "${_collection!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await RecipeApiService.deleteCollection(widget.collectionId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá bộ sưu tập')),
        );
        Navigator.pop(
            context, true); // Return true to indicate collection was deleted
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xoá: $e')),
        );
      }
    }
  }

  Future<void> _removeRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá ra khỏi bộ sưu tập?'),
        content:
            Text('Bạn có chắc muốn xoá "${recipe.title}" khỏi bộ sưu tập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await RecipeApiService.removeRecipeFromCollection(
          widget.collectionId,
          recipe.id,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá công thức khỏi bộ sưu tập')),
        );
        await _loadCollection(showSpinner: false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xoá: $e')),
        );
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredRecipes = _recipes;
      }
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
                  'Không thể tải bộ sưu tập.\n$_error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _loadCollection(),
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
                const Icon(Icons.folder_open,
                    size: 52, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'Bộ sưu tập này chưa có công thức nào.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy thêm công thức vào bộ sưu tập này.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // If search has no results
    if (_filteredRecipes.isEmpty && _searchController.text.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off,
                    size: 52, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy kết quả',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Thử tìm kiếm với từ khoá khác.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.70,
      ),
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        return Stack(
          children: [
            RecipeCard(
              key: ValueKey(recipe.id),
              recipe: recipe,
              onTap: () => _openRecipeDetail(recipe),
              isFavorite: recipe.isFavorite,
              isFavoriteBusy: _favoriteLoading.contains(recipe.id),
              onToggleFavorite: () => _toggleFavorite(recipe),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove_circle,
                      color: AppTheme.errorRed, size: 24),
                  onPressed: () => _removeRecipe(recipe),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Xoá khỏi bộ sưu tập',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _collection?.name ?? widget.collectionName ?? 'Bộ sưu tập';
    final recipeCount = _collection?.recipeCount ?? _recipes.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: _isSearching
            ? Container(
                height: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    hintText: 'Tìm kiếm...',
                    hintStyle: TextStyle(
                      color: AppTheme.textLight.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: Colors.grey[500],
                            splashRadius: 18,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (recipeCount > 0)
                          Text(
                            '$recipeCount công thức',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search_rounded,
              size: 24,
            ),
            onPressed: _toggleSearch,
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.textDark,
            ),
          ),

          // Edit button (visible when not searching)
          if (!_isSearching)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 23,
              ),
              onPressed: _editCollection,
              tooltip: 'Chỉnh sửa',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.textDark,
              ),
            ),

          // Delete button (visible when not searching)
          if (!_isSearching)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 23,
              ),
              onPressed: _deleteCollection,
              tooltip: 'Xóa',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
              ),
            ),

          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () => _loadCollection(showSpinner: false),
        child: _buildBody(),
      ),
    );
  }
}
