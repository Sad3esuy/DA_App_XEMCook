import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'result_recipes_screen.dart';

class SearchScreen extends StatefulWidget {

  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();

}

class _SearchScreenState extends State<SearchScreen> {

  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          title: 'Kết quả tìm kiếm',
          searchKeyword: query,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _searchController.clear();
    });
  }

  void _onChanged(String _) {
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
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
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
      decoration: InputDecoration(
        hintText: 'Bạn muốn nấu món gì hôm nay?',
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
      onChanged: _onChanged,
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
          backgroundColor: const Color.fromARGB(255, 217, 253, 239),
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
      color: const Color.fromARGB(255, 217, 253, 239),
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

