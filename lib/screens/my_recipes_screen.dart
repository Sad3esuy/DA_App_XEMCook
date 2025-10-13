import 'package:flutter/material.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:test_ui_app/model/recipe.dart';
import 'recipe_form_screen.dart';
import 'recipe_detail_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  late Future<List<Recipe>> _future;

  @override
  void initState() {
    super.initState();
    _future = RecipeApiService.getMyRecipes();
  }

  Future<void> _reload() async {
    setState(() => _future = RecipeApiService.getMyRecipes());
    await _future.catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Công thức của tôi'), backgroundColor: Colors.white, surfaceTintColor: Colors.white,
        actions: [
          IconButton(onPressed: () async {
            final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen()));
            if (created == true) _reload();
          }, icon: const Icon(Icons.add))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Recipe>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Lỗi: ${snap.error}'));
            }
            final items = snap.data ?? const <Recipe>[];
            if (items.isEmpty) {
              return const Center(child: Text('Chưa có công thức'));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: r.imageUrl.isEmpty
                        ? Container(width: 56, height: 56, color: AppTheme.secondaryYellow, child: const Icon(Icons.image))
                        : Image.network(r.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                  ),
                  title: Text(r.title),
                  subtitle: Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeFormScreen(recipeId: r.id)));
                        if (updated == true) _reload();
                      } else if (value == 'view') {
                        await Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id)),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                      PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    ],
                  ),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id)),
                      ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
