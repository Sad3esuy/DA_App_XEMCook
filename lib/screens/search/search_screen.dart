import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/recipe_api_service.dart';
import '../../services/search_history_service.dart';
import '../../theme/app_theme.dart';
import 'result_recipes_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _pendingSuggestionQuery = '';
  List<String> _history = <String>[];
  List<String> _remoteSuggestions = <String>[];
  bool _isLoadingSuggestions = false;

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
    _searchFocusNode.addListener(_handleFocusChange);
    _loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _debounce?.cancel();
    await SearchHistoryService.addQuery(query);
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
    await _loadHistory();
    if (!mounted) return;
    setState(() {
      _searchController.clear();
      _remoteSuggestions = <String>[];
      _isLoadingSuggestions = false;
      _pendingSuggestionQuery = '';
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _pendingSuggestionQuery = '';
      setState(() {
        _remoteSuggestions = <String>[];
        _isLoadingSuggestions = false;
      });
      return;
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _fetchSuggestions(trimmed);
    });
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final hasFocus = _searchFocusNode.hasFocus;
    final shouldResetSuggestions =
        hasFocus && _searchController.text.trim().isEmpty;
    if (hasFocus) {
      _loadHistory();
    }
    if (shouldResetSuggestions) {
      _debounce?.cancel();
    }
    setState(() {
      if (shouldResetSuggestions) {
        _remoteSuggestions = <String>[];
        _isLoadingSuggestions = false;
      }
    });
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryService.loadHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    _pendingSuggestionQuery = query;
    setState(() {
      _isLoadingSuggestions = true;
    });
    List<String> remote = <String>[];
    try {
      remote = await RecipeApiService.getSearchSuggestions(query);
    } catch (_) {
      remote = <String>[];
    }
    if (!mounted || _pendingSuggestionQuery != query) {
      return;
    }
    setState(() {
      _remoteSuggestions = remote;
      _isLoadingSuggestions = false;
    });
  }

  void _selectSuggestion(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    _pendingSuggestionQuery = trimmed;
    _searchController.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    _submitSearch();
  }

  Future<void> _removeHistoryItem(String value) async {
    await SearchHistoryService.removeQuery(value);
    await _loadHistory();
  }

  List<String> get _mergedSuggestions {
    final query = _searchController.text.trim();
    final results = <String>[];
    final seen = <String>{};
    void addValue(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty) return;
      final key = normalized.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      results.add(normalized);
    }

    if (query.isEmpty) {
      for (final item in _history) {
        addValue(item);
        if (results.length >= 10) break;
      }
      return results;
    }

    final normalizedQuery = query.toLowerCase();
    for (final item in _history) {
      if (item.toLowerCase().contains(normalizedQuery)) {
        addValue(item);
        if (results.length >= 10) break;
      }
    }
    for (final item in _remoteSuggestions) {
      if (results.length >= 10) break;
      addValue(item);
    }
    return results;
  }

  bool get _shouldShowSuggestionPanel {
    if (!_searchFocusNode.hasFocus) return false;
    if (_searchController.text.trim().isNotEmpty) return true;
    return _history.isNotEmpty || _isLoadingSuggestions;
  }

  Widget _buildSuggestionContent(
    List<String> suggestions,
    Set<String> historyKeys,
  ) {
    if (_isLoadingSuggestions && suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryOrange.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đang tìm kiếm...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có gợi ý phù hợp',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Thử tìm kiếm với từ khóa khác',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        final isHistory = historyKeys.contains(suggestion.toLowerCase());

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectSuggestion(suggestion),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHistory
                            ? AppTheme.primaryOrange.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHistory
                            ? Icons.history_rounded
                            : Icons.search_rounded,
                        size: 18,
                        color: isHistory
                            ? AppTheme.primaryOrange
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Trailing
                    if (isHistory) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await _removeHistoryItem(suggestion);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.north_west_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
        titleTextStyle: TextStyle(
            fontSize: 24,
            color: AppTheme.textDark,
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
    final suggestions = _mergedSuggestions;
    final showPanel = _shouldShowSuggestionPanel;
    final historyKeys = _history.map((item) => item.toLowerCase()).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onSubmitted: (_) => _submitSearch(),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          decoration: InputDecoration(
            hintText: 'Bạn muốn nấu món gì hôm nay?',
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _debounce?.cancel();
                      setState(() {
                        _searchController.clear();
                        _remoteSuggestions = <String>[];
                        _isLoadingSuggestions = false;
                        _pendingSuggestionQuery = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
        if (showPanel) const SizedBox(height: 8),
        if (showPanel)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingSuggestions && suggestions.isNotEmpty)
                  const LinearProgressIndicator(minHeight: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: _buildSuggestionContent(suggestions, historyKeys),
                ),
              ],
            ),
          ),
      ],
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
          backgroundColor: const Color.fromARGB(208, 221, 240, 232),
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
      color: const Color.fromARGB(208, 221, 240, 232),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                category.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,                 
                ),
              ),
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
