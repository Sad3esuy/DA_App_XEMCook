import 'package:flutter/material.dart';

import '../../model/recipe.dart';
import '../../services/recipe_api_service.dart';
import '../../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

enum RecipeCollectionSort {
  defaultSort,
  ratings,
  views,
  createdAt,
  totalTime,
}

extension RecipeCollectionSortX on RecipeCollectionSort {
  String get apiValue {
    switch (this) {
      case RecipeCollectionSort.ratings:
        return 'ratings';
      case RecipeCollectionSort.views:
        return 'views';
      case RecipeCollectionSort.createdAt:
        return 'createdAt';
      case RecipeCollectionSort.totalTime:
        return 'totalTime';
      case RecipeCollectionSort.defaultSort:
      default:
        return 'default';
    }
  }

  String get label {
    switch (this) {
      case RecipeCollectionSort.ratings:
        return 'Đánh giá';
      case RecipeCollectionSort.views:
        return 'Lượt xem';
      case RecipeCollectionSort.createdAt:
        return 'Mới nhất';
      case RecipeCollectionSort.totalTime:
        return 'Thời gian';
      case RecipeCollectionSort.defaultSort:
      default:
        return 'Đề xuất';
    }
  }

  IconData get icon {
    switch (this) {
      case RecipeCollectionSort.ratings:
        return Icons.star_rounded;
      case RecipeCollectionSort.views:
        return Icons.visibility_rounded;
      case RecipeCollectionSort.createdAt:
        return Icons.new_releases_rounded;
      case RecipeCollectionSort.totalTime:
        return Icons.schedule_rounded;
      case RecipeCollectionSort.defaultSort:
      default:
        return Icons.recommend_rounded;
    }
  }
}

class RecipeCollectionConfig {
  const RecipeCollectionConfig({
    required this.title,
    this.subtitle,
    this.initialCategory,
    this.initialDifficulty,
    this.initialDietTags = const <String>[],
    this.initialTags = const <String>[],
    this.initialMaxTotalTime,
    this.initialTimeframe = 'all',
    this.timeframeTarget,
    this.initialSort = RecipeCollectionSort.defaultSort,
  });

  final String title;
  final String? subtitle;
  final String? initialCategory;
  final String? initialDifficulty;
  final List<String> initialDietTags;
  final List<String> initialTags;
  final int? initialMaxTotalTime;
  final String initialTimeframe;
  final String? timeframeTarget;
  final RecipeCollectionSort initialSort;
}

class RecipeCollectionScreen extends StatefulWidget {
  const RecipeCollectionScreen({
    super.key,
    required this.config,
  });

  final RecipeCollectionConfig config;

  @override
  State<RecipeCollectionScreen> createState() => _RecipeCollectionScreenState();
}

class _RecipeCollectionScreenState extends State<RecipeCollectionScreen> {
  static const _categoryOptions = <_FilterOption>[
    _FilterOption(value: 'breakfast', label: 'Bữa sáng', icon: Icons.free_breakfast_rounded),
    _FilterOption(value: 'lunch', label: 'Bữa trưa', icon: Icons.lunch_dining_rounded),
    _FilterOption(value: 'dinner', label: 'Bữa tối', icon: Icons.dinner_dining_rounded),
    _FilterOption(value: 'dessert', label: 'Tráng miệng', icon: Icons.cake_rounded),
    _FilterOption(value: 'snack', label: 'Ăn vặt', icon: Icons.fastfood_rounded),
    _FilterOption(value: 'beverage', label: 'Đồ uống', icon: Icons.local_cafe_rounded),
    _FilterOption(value: 'other', label: 'Khác', icon: Icons.restaurant_rounded),
  ];

  static const _difficultyOptions = <_FilterOption>[
    _FilterOption(value: 'easy', label: 'Dễ', icon: Icons.sentiment_satisfied_rounded),
    _FilterOption(value: 'medium', label: 'Trung bình', icon: Icons.sentiment_neutral_rounded),
    _FilterOption(value: 'hard', label: 'Khó', icon: Icons.sentiment_very_dissatisfied_rounded),
  ];

  static const _defaultDietOptions = <String>{
    'vegan',
    'vegetarian',
    'keto',
    'gluten-free',
    'paleo',
    'dairy-free',
    'low-carb',
  };

  static const _totalTimeOptions = <_TimeOption>[
    _TimeOption(value: 15, label: '≤ 15 phút', icon: Icons.bolt_rounded),
    _TimeOption(value: 30, label: '≤ 30 phút', icon: Icons.schedule_rounded),
    _TimeOption(value: 60, label: '≤ 60 phút', icon: Icons.access_time_rounded),
  ];

  static const _timeframeOptions = <_FilterOption>[
    _FilterOption(value: 'week', label: 'Tuần này', icon: Icons.today_rounded),
    _FilterOption(value: 'month', label: 'Tháng này', icon: Icons.calendar_month_rounded),
    _FilterOption(value: 'all', label: 'Tất cả', icon: Icons.all_inclusive_rounded),
  ];

  final List<Recipe> _recipes = <Recipe>[];
  final ScrollController _scrollController = ScrollController();

  late String? _selectedCategory;
  late String? _selectedDifficulty;
  late Set<String> _selectedDietTags;
  late Set<String> _availableDietTags;
  int? _selectedMaxTotalTime;
  late _FilterOption _selectedTimeframe;
  late RecipeCollectionSort _selectedSort;

  bool _isFetching = false;
  bool _isInitialLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.config.initialCategory;
    _selectedDifficulty = widget.config.initialDifficulty;
    _selectedMaxTotalTime = widget.config.initialMaxTotalTime;
    _selectedSort = widget.config.initialSort;

    final initialDietTags = <String>{
      ...widget.config.initialDietTags.map((e) => e.toLowerCase()),
      ...widget.config.initialTags.map((e) => e.toLowerCase()),
    };
    _selectedDietTags = initialDietTags;
    _availableDietTags = {
      ..._defaultDietOptions,
      ...initialDietTags,
    };

    _selectedTimeframe = _timeframeOptions.firstWhere(
      (option) => option.value == widget.config.initialTimeframe.toLowerCase(),
      orElse: () => _timeframeOptions.last,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecipes(initial: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecipes({bool initial = false}) async {
    if (!mounted) return;
    setState(() {
      _isFetching = true;
      if (initial) {
        _isInitialLoad = true;
        _error = null;
      }
    });

    try {
      final recipes = await RecipeApiService.getAllRecipes(
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        dietTags: _selectedDietTags.isEmpty ? null : _selectedDietTags.toList(),
        maxTotalTime: _selectedMaxTotalTime,
        timeframe: _selectedTimeframe.value,
        timeframeTarget: widget.config.timeframeTarget,
        sort: _selectedSort.apiValue,
        limit: 40,
      );
      if (!mounted) return;
      setState(() {
        _recipes
          ..clear()
          ..addAll(recipes);
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _mapErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  String _mapErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.isEmpty) {
      return 'Không thể tải công thức. Vui lòng thử lại.';
    }
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      final message = raw.substring(prefix.length).trim();
      if (message.isNotEmpty) return message;
    }
    return raw;
  }

  void _showFilterBottomSheet() {
    // Temporary states for the bottom sheet
    String? tempCategory = _selectedCategory;
    String? tempDifficulty = _selectedDifficulty;
    Set<String> tempDietTags = Set.from(_selectedDietTags);
    int? tempMaxTotalTime = _selectedMaxTotalTime;
    _FilterOption tempTimeframe = _selectedTimeframe;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppTheme.primaryOrange),
                      const SizedBox(width: 12),
                      const Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCategory = null;
                            tempDifficulty = null;
                            tempDietTags.clear();
                            tempMaxTotalTime = null;
                            tempTimeframe = _timeframeOptions.last;
                          });
                        },
                        child: const Text('Xóa tất cả'),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: AppTheme.primaryOrange,
                  height: 0.5),
                // Filters content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _BottomSheetFilterSection(
                        title: 'Loại món',
                        icon: Icons.restaurant_menu_rounded,
                        options: _categoryOptions,
                        selectedValue: tempCategory,
                        onChanged: (value) {
                          setModalState(() {
                            tempCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _BottomSheetFilterSection(
                        title: 'Độ khó',
                        icon: Icons.speed_rounded,
                        options: _difficultyOptions,
                        selectedValue: tempDifficulty,
                        onChanged: (value) {
                          setModalState(() {
                            tempDifficulty = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _BottomSheetDietFilterSection(
                        title: 'Chế độ ăn',
                        icon: Icons.spa_rounded,
                        options: _availableDietTags.toList()..sort(),
                        selectedValues: tempDietTags,
                        onToggle: (value) {
                          setModalState(() {
                            if (tempDietTags.contains(value)) {
                              tempDietTags.remove(value);
                            } else {
                              tempDietTags.add(value);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _BottomSheetTimeFilterSection(
                        title: 'Thời gian nấu',
                        icon: Icons.timer_rounded,
                        options: _totalTimeOptions,
                        selectedMinutes: tempMaxTotalTime,
                        onChanged: (value) {
                          setModalState(() {
                            tempMaxTotalTime = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _BottomSheetFilterSection(
                        title: 'Khoảng thời gian',
                        icon: Icons.date_range_rounded,
                        options: _timeframeOptions,
                        selectedValue: tempTimeframe.value,
                        onChanged: (value) {
                          setModalState(() {
                            tempTimeframe = _timeframeOptions.firstWhere(
                              (item) => item.value == value,
                              orElse: () => _timeframeOptions.last,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Apply button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedDifficulty = tempDifficulty;
                            _selectedDietTags = tempDietTags;
                            _selectedMaxTotalTime = tempMaxTotalTime;
                            _selectedTimeframe = tempTimeframe;
                          });
                          Navigator.pop(context);
                          _fetchRecipes();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onCategorySelected(String? value) {
    if (_selectedCategory == value) return;
    setState(() {
      _selectedCategory = value;
    });
    _fetchRecipes();
  }

  void _onTimeSelected(int? minutes) {
    if (_selectedMaxTotalTime == minutes) return;
    setState(() {
      _selectedMaxTotalTime = minutes;
    });
    _fetchRecipes();
  }

  void _onSortSelected(RecipeCollectionSort sort) {
    if (_selectedSort == sort) return;
    setState(() {
      _selectedSort = sort;
    });
    _fetchRecipes();
  }

  Future<void> _onRefresh() async {
    await _fetchRecipes(initial: _recipes.isEmpty);
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedDifficulty != null) count++;
    if (_selectedDietTags.isNotEmpty) count++;
    if (_selectedMaxTotalTime != null) count++;
    if (_selectedTimeframe.value != 'all') count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
      _selectedDietTags.clear();
      _selectedMaxTotalTime = null;
      _selectedTimeframe = _timeframeOptions.last;
    });
    _fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRecipes = _recipes.isNotEmpty;
    final isLoading = _isInitialLoad && _isFetching;
    final activeFilters = _activeFiltersCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern App Bar
            SliverAppBar(
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      widget.config.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Filter Button with Badge
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primaryOrange,
                      ),
                      onPressed: _showFilterBottomSheet,
                    ),
                    if (activeFilters > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$activeFilters',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Subtitle
            if (widget.config.subtitle != null && widget.config.subtitle!.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    widget.config.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ),

            // Quick Filters Row
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active filters chips
                    if (activeFilters > 0) ...[
                      Row(
                        children: [
                          const Text(
                            'Bộ lọc:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_selectedCategory != null)
                                    _ActiveFilterChip(
                                      label: _categoryOptions
                                          .firstWhere((o) => o.value == _selectedCategory)
                                          .label,
                                      onRemove: () => _onCategorySelected(null),
                                    ),
                                  if (_selectedDifficulty != null)
                                    _ActiveFilterChip(
                                      label: _difficultyOptions
                                          .firstWhere((o) => o.value == _selectedDifficulty)
                                          .label,
                                      onRemove: () {
                                        setState(() => _selectedDifficulty = null);
                                        _fetchRecipes();
                                      },
                                    ),
                                  if (_selectedMaxTotalTime != null)
                                    _ActiveFilterChip(
                                      label: _totalTimeOptions
                                          .firstWhere((o) => o.value == _selectedMaxTotalTime)
                                          .label,
                                      onRemove: () => _onTimeSelected(null),
                                    ),
                                  if (_selectedDietTags.isNotEmpty)
                                    _ActiveFilterChip(
                                      label: '${_selectedDietTags.length} chế độ ăn',
                                      onRemove: () {
                                        setState(() => _selectedDietTags.clear());
                                        _fetchRecipes();
                                      },
                                    ),
                                  if (_selectedTimeframe.value != 'all')
                                    _ActiveFilterChip(
                                      label: _selectedTimeframe.label,
                                      onRemove: () {
                                        setState(() => _selectedTimeframe = _timeframeOptions.last);
                                        _fetchRecipes();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (activeFilters > 1)
                            TextButton(
                              onPressed: _clearAllFilters,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Xóa tất cả',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Sort Section
                    Row(
                      children: [
                        Icon(_selectedSort.icon, size: 16, color: AppTheme.primaryOrange),
                        const SizedBox(width: 8),
                        const Text(
                          'Sắp xếp:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: RecipeCollectionSort.values.map((sort) {
                                final isSelected = sort == _selectedSort;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _QuickFilterChip(
                                    label: sort.label,
                                    icon: sort.icon,
                                    selected: isSelected,
                                    onTap: () => _onSortSelected(sort),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicator
            if (_isFetching && !_isInitialLoad)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Error Banner
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _ErrorBanner(
                    message: _error!,
                    onRetry: () => _fetchRecipes(initial: _recipes.isEmpty),
                  ),
                ),
              ),

            // Content
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                      ),
                      SizedBox(height: 16),
                      Text('Đang tải công thức...'),
                    ],
                  ),
                ),
              )
            else if (!hasRecipes)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  description: 'Không có món phù hợp. Hãy thử nới lỏng bộ lọc hoặc xem những món mới nhất.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = _recipes[index];
                      return _GridRecipeCard(
                        recipe: recipe,
                        onTap: () => _openRecipeDetail(recipe),
                      );
                    },
                    childCount: _recipes.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openRecipeDetail(Recipe recipe) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final IconData? icon;
}

class _TimeOption {
  const _TimeOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final int value;
  final String label;
  final IconData? icon;
}

// Quick Filter Chip for main screen
class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 12 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryOrange : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppTheme.textDark,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Active Filter Chip (removable)
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet Filter Section
class _BottomSheetFilterSection extends StatelessWidget {
  const _BottomSheetFilterSection({
    required this.title,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.selectedValue,
  });

  final String title;
  final IconData icon;
  final List<_FilterOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryOrange),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final selected = selectedValue == option.value;
            return _BottomSheetChip(
              label: option.label,
              icon: option.icon,
              selected: selected,
              onTap: () => onChanged(selected ? null : option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BottomSheetDietFilterSection extends StatelessWidget {
  const _BottomSheetDietFilterSection({
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final String title;
  final IconData icon;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryOrange),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Chọn nhiều',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final lower = option.toLowerCase();
            final selected = selectedValues.contains(lower);
            return _BottomSheetChip(
              label: _titleCase(option),
              selected: selected,
              onTap: () => onToggle(lower),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    final parts = value.split(RegExp(r'[\s_-]+'));
    return parts
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _BottomSheetTimeFilterSection extends StatelessWidget {
  const _BottomSheetTimeFilterSection({
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedMinutes,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final List<_TimeOption> options;
  final int? selectedMinutes;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryOrange),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _BottomSheetChip(
              label: 'Tất cả',
              icon: Icons.all_inclusive_rounded,
              selected: selectedMinutes == null,
              onTap: () => onChanged(null),
            ),
            ...options.map((option) {
              final selected = selectedMinutes == option.value;
              return _BottomSheetChip(
                label: option.label,
                icon: option.icon,
                selected: selected,
                onTap: () => onChanged(selected ? null : option.value),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _BottomSheetChip extends StatelessWidget {
  const _BottomSheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 14 : 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryOrange : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppTheme.primaryOrange : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppTheme.textDark,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textDark,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridRecipeCard extends StatelessWidget {
  const _GridRecipeCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totalTime = recipe.prepTime + recipe.cookTime;
    final likes =
        recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;
    final tag = recipe.tags.isNotEmpty ? recipe.tags.first.trim() : '';
    final authorName = (recipe.authorName ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.04),
          //     blurRadius: 10,
          //     offset: const Offset(0, 6),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: recipe.imageUrl.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const _ImagePlaceholder(),
                          )
                        : const _ImagePlaceholder(),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (totalTime > 0)
                          _Badge(label: '${totalTime} min'),
                        if (tag.isNotEmpty) _Badge(label: _formatTag(tag),
                            foreground: AppTheme.accentGreen,
                            background: const Color(0xFFE7F8ED)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _LikePill(count: likes),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              AppTheme.secondaryYellow.withOpacity(0.6),
                          backgroundImage: (recipe.authorAvatar != null &&
                                  recipe.authorAvatar!.isNotEmpty)
                              ? NetworkImage(recipe.authorAvatar!)
                              : null,
                          child: (recipe.authorAvatar == null ||
                                  recipe.authorAvatar!.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 16, color: AppTheme.primaryOrange)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authorName.isEmpty ? 'Anonymous' : authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(255, 239, 10, 10),
                                fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.background, this.foreground});

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFFFEDCF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground ?? AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LikePill extends StatelessWidget {
  const _LikePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border,
              size: 16, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatTag(String value) {
  if (value.isEmpty) return value;
  final lower = value.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        Column(
          children: [
            const Icon(Icons.no_food, size: 42, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'Chua co cong thuc nao trong muc nay.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.errorRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Có lỗi xảy ra',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: AppTheme.primaryOrange,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.secondaryYellow.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Không tìm thấy công thức',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}