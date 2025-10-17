import 'package:flutter/material.dart';
import 'dart:async';

import '../../model/recipe.dart';
import '../../services/recipe_api_service.dart';
import '../../theme/app_theme.dart';
import '../recipe/recipe_detail_screen.dart';
import '../recipe/recipe_form_screen.dart';
import 'category_recipes_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<Recipe>>? _searchFuture;
  bool _searchSubmitted = false;
  Timer? _debounce;

  late Future<List<Recipe>> _pickedFuture;

  static const List<_SearchCategory> _categories = [
    _SearchCategory(
        label: 'Món chính', value: 'dinner', icon: Icons.restaurant_rounded),
    _SearchCategory(
        label: 'Ăn sáng',
        value: 'breakfast',
        icon: Icons.free_breakfast_rounded),
    _SearchCategory(
        label: 'Ăn trưa', value: 'lunch', icon: Icons.lunch_dining_rounded),
    _SearchCategory(
        label: 'Tráng miệng', value: 'dessert', icon: Icons.cake_outlined),
    _SearchCategory(
        label: 'Ăn vặt', value: 'snack', icon: Icons.fastfood_rounded),
    _SearchCategory(
        label: 'Đồ uống', value: 'beverage', icon: Icons.local_cafe_rounded),
  ];

  static const List<_QuickFilter> _quickFilters = [
    _QuickFilter(
      title: 'Mới nhất',
      subtitle: 'Vừa được chia sẻ',
      icon: Icons.auto_awesome_rounded,
      tagHint: 'new',
    ),
    _QuickFilter(
      title: 'Phổ biến tuần này',
      subtitle: 'Xem nhiều nhất',
      icon: Icons.trending_up_rounded,
      tagHint: 'popular',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pickedFuture = RecipeApiService.getAllRecipes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
        _searchSubmitted = false;
      });
      return;
    }
    setState(() {
      _searchSubmitted = true;
      _searchFuture = RecipeApiService.getAllRecipes(
        search: query,
      );
    });
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
        _searchSubmitted = false;
      });
      return;
    }
    if (query.length < 2) return; // avoid noisy calls
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchSubmitted = true;
        _searchFuture = RecipeApiService.getAllRecipes(search: query);
      });
    });
  }

  void _openCategory(_SearchCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          title: category.label,
          category: category.value,
        ),
      ),
    );
  }

  void _openFilter(_QuickFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          title: filter.title,
          tagHint: filter.tagHint,
        ),
      ),
    );
  }

  void _openRecipe(Recipe recipe) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }

  Future<void> _createRecipe() async {
    final created = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _pickedFuture = RecipeApiService.getAllRecipes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: AppTheme.primaryOrange,
        onPressed: _createRecipe,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: const Text('Tìm kiếm công thức'),
        titleTextStyle: TextStyle(fontSize: 24, color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins'),
        backgroundColor: AppTheme.lightCream,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 32),
          children: [
            _buildSearchField(),
            const SizedBox(height: 24),
            Text(
              'Gợi ý nhanh',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ..._quickFilters.map((filter) => _QuickFilterCard(
                  filter: filter,
                  onTap: () => _openFilter(filter),
                )),
            const SizedBox(height: 24),
            Text(
              'Danh mục',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _CategoryCard(
                  category: category,
                  onTap: () => _openCategory(category),
                );
              },
            ),
            const SizedBox(height: 32),
            if (_searchFuture != null || _searchSubmitted)
              Text(
                'Kết quả tìm kiếm',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            if (_searchFuture != null || _searchSubmitted)
              const SizedBox(height: 12),
            if (_searchFuture != null)
              FutureBuilder<List<Recipe>>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _InlineError(message: snapshot.error.toString());
                  }
                  final results =
                      (snapshot.data ?? const <Recipe>[]).take(20).toList();
                  if (results.isEmpty) {
                    return const _PlaceholderMessage(
                        text: 'Không tìm thấy công thức phù hợp.');
                  }
                  return Column(
                    children: results
                        .map((r) => _RecipeListTile(
                            recipe: r, onTap: () => _openRecipe(r)))
                        .toList(),
                  );
                },
              )
            else if (_searchSubmitted)
              const _PlaceholderMessage(text: 'Nhập từ khóa để bắt đầu tìm.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _submitSearch(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Nhập tên công thức hoặc nguyên liệu',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchFuture = null;
                    _searchSubmitted = false;
                  });
                },
                icon: const Icon(Icons.close_rounded),
              )
            : IconButton(
                onPressed: _submitSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
      ),
      onChanged: _onChanged,
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  const _RecipeListTile({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totalTime = recipe.prepTime + recipe.cookTime;
    final timeLabel = totalTime > 0 ? '$totalTime phut' : 'Thoi gian linh hoat';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 64,
            child: recipe.imageUrl.isNotEmpty
                ? Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                  )
                : const _ImagePlaceholder(),
          ),
        ),
        title: Text(
          recipe.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              recipe.description.isNotEmpty
                  ? recipe.description
                  : 'Cong thuc chua co mo ta.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.primaryOrange),
                const SizedBox(width: 4),
                Text(timeLabel),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
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

class _QuickFilterCard extends StatelessWidget {
  const _QuickFilterCard({required this.filter, required this.onTap});

  final _QuickFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.secondaryYellow,
          child: Icon(filter.icon, color: AppTheme.primaryOrange),
        ),
        title: Text(
          filter.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(filter.subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _SearchCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.secondaryYellow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(category.icon, color: AppTheme.primaryOrange),
              ),
              const SizedBox(height: 10),
              Text(
                category.label,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderMessage extends StatelessWidget {
  const _PlaceholderMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppTheme.textLight),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCategory {
  const _SearchCategory({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _QuickFilter {
  const _QuickFilter({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tagHint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? tagHint;
}
