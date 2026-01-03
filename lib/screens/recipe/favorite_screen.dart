// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:test_ui_app/model/user.dart';
// import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/services/favorite_state.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'package:test_ui_app/widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _recipes = const <Recipe>[];
  bool _loading = true;
  String? _error;
  final Set<String> _favoriteLoading = <String>{};
  late final FavoriteState _favoriteState;
  VoidCallback? _favoriteListener;

  @override
  void initState() {
    super.initState();
    _favoriteState = context.read<FavoriteState>();
    _favoriteListener = () {
      if (!mounted) return;
      final favoriteIds = _favoriteState.ids;
      setState(() {
        _recipes = _recipes.where((recipe) => favoriteIds.contains(recipe.id)).toList();
      });
    };
    _favoriteState.addListener(_favoriteListener!);
    _loadFavorites();
  }

  @override
  void dispose() {
    if (_favoriteListener != null) {
      _favoriteState.removeListener(_favoriteListener!);
    }
    super.dispose();
  }

  Future<void> _loadFavorites({bool showSpinner = true}) async {
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
      final data = await RecipeApiService.getFavorites();
      if (!mounted) return;
      _favoriteState.absorbRecipes(data);
      setState(() {
        _recipes = data;
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
          SnackBar(content: Text('Không thể làm mới danh sách: $e')),
        );
      }
    }
  }

  Future<void> _openRecipeDetail(Recipe recipe) async {
    final changed =
        await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
    if (changed == true && mounted) {
      await _loadFavorites(showSpinner: false);
    }
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final recipeId = recipe.id;
    if (_favoriteLoading.contains(recipeId)) return;
    setState(() {
      _favoriteLoading.add(recipeId);
    });

    try {
      final stillFavorite = await _favoriteState.toggleFavorite(recipeId);
      if (!mounted) return;
      setState(() {
        _favoriteLoading.remove(recipeId);
        if (!stillFavorite) {
          _recipes = _recipes.where((r) => r.id != recipeId).toList();
        }
      });
      if (!stillFavorite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa khỏi danh sách yêu thích')),
        );
      }
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
                  'Không thể tải danh sách yêu thích.\n$_error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _loadFavorites(),
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
                const Icon(Icons.favorite_border,
                    size: 52, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'Bạn chưa có món nào trong danh sách yêu thích.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy khám phá và thêm những công thức bạn thích.',
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
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return RecipeCard(
          key: ValueKey(recipe.id),
          recipe: recipe,
          onTap: () => _openRecipeDetail(recipe),
          isFavorite: true,
          isFavoriteBusy: _favoriteLoading.contains(recipe.id),
          onToggleFavorite: () => _toggleFavorite(recipe),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Công thức yêu thích'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () => _loadFavorites(showSpinner: false),
        child: _buildBody(),
      ),
    );
  }
}

