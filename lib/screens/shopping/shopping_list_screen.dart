import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../model/shopping_item.dart';
import '../../model/shopping_list.dart';
import '../../services/shopping_list_service.dart';
import '../../services/shopping_list_remote.dart';
import '../../theme/app_theme.dart';

enum ShoppingItemFilter { all, unchecked, checked }

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _service = ShoppingListService.instance;
  final TextEditingController _searchController = TextEditingController();
  ShoppingItemFilter _filter = ShoppingItemFilter.all;
  bool _groupByRecipe = false;

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    _service.syncPending();
    // Fetch latest data from server when screen opens
    _service.refreshFromServer();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightCream,
      appBar: AppBar(
        title: const Text('Danh sách mua sắm'),
        titleTextStyle: TextStyle(
            fontSize: 24,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins'),
        backgroundColor: AppTheme.lightCream,
        actions: [
          ValueListenableBuilder<ShoppingListState>(
            valueListenable: _service.stateNotifier,
            builder: (context, state, _) {
              final selected = state.selectedList;
              final hasCheckedItems =
                  selected?.items.any((item) => item.checked) ?? false;

              if (hasCheckedItems) {
                return IconButton(
                  onPressed: () => _service.clearChecked(selected!.id),
                  icon: const Icon(Icons.delete_forever_outlined),
                  color: const Color.fromARGB(255, 189, 3, 3),
                  tooltip: 'Xoá đã mua',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            onPressed: _showCreateListDialog,
            icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
            tooltip: 'Thêm',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<ShoppingListState>(
        valueListenable: _service.stateNotifier,
        builder: (context, state, _) {
          if (state.isLoading && state.lists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.lists.isEmpty) {
            return _buildEmptyState(context);
          }

          final selected = state.selectedList;
          final items = _filterItems(selected?.items ?? const [], state);

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryOrange,
            child: CustomScrollView(
              slivers: [
                // Sync Banner
                if (state.hasPendingSync)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildSyncBanner(
                          context, state.pendingOperationCount),
                    ),
                  ),

                // List Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildListSelector(state),
                  ),
                ),

                // Search and Filters
                if (selected != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildSearchAndFilters(state),
                    ),
                  ),

                // Content
                if (selected == null)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildEmptyListMessage(),
                    ),
                  )
                else if (_groupByRecipe)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildGroupedItems(selected, items),
                      ]),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildItemTile(selected, items[index]),
                        childCount: items.length,
                      ),
                    ),
                  ),

                // List Actions
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncBanner(BuildContext context, int pending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.cloud_sync_rounded,
                color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang chờ đồng bộ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$pending thay đổi chưa được đồng bộ',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleRefresh,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Đồng bộ',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_basket_rounded,
                size: 64,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có danh sách nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo danh sách đầu tiên để bắt đầu\nquản lý mua sắm của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateListDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo danh sách mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSelector(ShoppingListState state) {
    // Create a list of colors for shopping lists
    final colors = [
      const Color.fromARGB(208, 238, 240, 221), // Green tint
      const Color.fromARGB(208, 232, 240, 221), // Light green
      const Color.fromARGB(208, 240, 221, 232), // Pink tint
      const Color.fromARGB(208, 221, 232, 240), // Blue tint
      const Color.fromARGB(208, 240, 232, 221), // Orange tint
      const Color.fromARGB(208, 232, 221, 240), // Purple tint
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.lists.length,
        itemBuilder: (context, index) {
          final list = state.lists[index];
          final selected = list.id == state.selectedListId;
          final isComplete = list.uncheckedCount == 0 && list.items.isNotEmpty;
          final color = colors[index % colors.length];

          return Padding(
            padding: EdgeInsets.only(
              right: 12,
              left: index == 0 ? 0 : 0,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: selected ? AppTheme.primaryOrange : color,
                  borderRadius: BorderRadius.circular(16),
                  elevation: selected ? 2 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _service.setSelectedList(list.id),
                    child: Container(
                      width: 190,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.shopping_basket_rounded,
                              color: selected
                                  ? AppTheme.primaryOrange
                                  : (isComplete
                                      ? Colors.green.shade600
                                      : AppTheme.accentGreen),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  list.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.textDark,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badge positioned at top-right
                Positioned(
                  top: 6,
                  right: 6,
                  child: list.uncheckedCount > 0
                      ? Container(
                          constraints: const BoxConstraints(minWidth: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primaryOrange.withOpacity(0.1)
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${list.uncheckedCount}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.primaryOrange
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        )
                      : Container(
                          constraints: const BoxConstraints(minWidth: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.white : Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? Colors.green.shade100
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: selected
                                    ? Colors.green.shade700
                                    : Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${list.items.length}',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.green.shade700
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // Menu button positioned at bottom-right
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _showListOptionsBottomSheet(list),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 16,
                        color: selected ? Colors.white : Colors.grey.shade700,
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

  Widget _buildSearchAndFilters(ShoppingListState state) {
    final selected = state.selectedList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.search_rounded, color: Colors.grey.shade400),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () => _searchController.clear(),
                      icon: Icon(Icons.close_rounded,
                          color: Colors.grey.shade400),
                    )
                  : null,
              hintText: 'Tìm nguyên liệu...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Tất cả',
                selected: _filter == ShoppingItemFilter.all,
                onTap: () => setState(() => _filter = ShoppingItemFilter.all),
              ),
              _buildFilterChip(
                label: 'Chưa mua',
                selected: _filter == ShoppingItemFilter.unchecked,
                onTap: () =>
                    setState(() => _filter = ShoppingItemFilter.unchecked),
              ),
              _buildFilterChip(
                label: 'Đã mua',
                selected: _filter == ShoppingItemFilter.checked,
                onTap: () =>
                    setState(() => _filter = ShoppingItemFilter.checked),
              ),
              _buildFilterChip(
                label: 'Nhóm',
                icon: Icons.restaurant_menu_rounded,
                selected: _groupByRecipe,
                onTap: () => setState(() => _groupByRecipe = !_groupByRecipe),
              ),
              _buildActionChip(
                label: 'Gộp trùng',
                icon: Icons.merge_type_rounded,
                onTap: selected != null
                    ? () => _service.mergeDuplicates(selected.id)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryOrange
                : const Color.fromARGB(208, 221, 240, 232),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryOrange
                  : const Color.fromARGB(0, 33, 33, 33),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey.shade200
                : AppTheme.primaryOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.shade300
                  : AppTheme.primaryOrange.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isDisabled ? Colors.grey.shade400 : AppTheme.primaryOrange,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled
                      ? Colors.grey.shade400
                      : AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyListMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Danh sách trống',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm nguyên liệu để bắt đầu',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedItems(ShoppingList list, List<ShoppingItem> items) {
    final groups = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final key = item.recipeTitle?.trim().isNotEmpty == true
          ? item.recipeTitle!
          : 'Khác';
      groups.putIfAbsent(key, () => <ShoppingItem>[]).add(item);
    }

    return Column(
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.length}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((item) => _buildItemTile(list, item)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildItemTile(ShoppingList list, ShoppingItem item) {
    final subtitle = <String>[];
    if (item.quantity != null && item.quantity!.isNotEmpty) {
      final buffer = StringBuffer(item.quantity!);
      if (item.unit != null && item.unit!.isNotEmpty) {
        buffer.write(' ${item.unit}');
      }
      subtitle.add(buffer.toString());
    } else if (item.unit != null && item.unit!.isNotEmpty) {
      subtitle.add(item.unit!);
    }
    if (item.note != null && item.note!.isNotEmpty) {
      subtitle.add(item.note!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.checked ? Colors.grey.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: item.checked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _service.toggleChecked(list.id, item.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Custom Checkbox với animation
                GestureDetector(
                  onTap: () => _service.toggleChecked(list.id, item.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: item.checked
                          ? AppTheme.primaryOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.checked
                            ? AppTheme.primaryOrange
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: item.checked
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryOrange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: item.checked
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên nguyên liệu - CHỈ CÓ GẠCh KHI CHECKED
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: item.checked
                              ? Colors.grey.shade400
                              : const Color(0xFF1A1A1A),
                          decoration:
                              item.checked ? TextDecoration.lineThrough : null,
                          decorationThickness: 2,
                          height: 1.3,
                        ),
                      ),
                      // Subtitle - KHÔNG BỊ GẠCH
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle.join(' • '),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: item.checked
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                            // KHÔNG có decoration ở đây
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Drag indicator (optional)
                if (!item.checked) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.grey.shade300,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ShoppingItem> _filterItems(
    List<ShoppingItem> source,
    ShoppingListState state,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((item) {
      if (_filter == ShoppingItemFilter.unchecked && item.checked) {
        return false;
      }
      if (_filter == ShoppingItemFilter.checked && !item.checked) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        item.name,
        item.quantity,
        item.unit,
        item.note,
        item.recipeTitle,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _handleRefresh() async {
    try {
      await _service.refreshFromServer();
    } catch (e) {
      if (!mounted) return;
      _showSyncError(e);
    }
  }

  void _showSyncError(Object error) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    String message;
    if (error is SocketException ||
        (error is http.ClientException &&
            error.message.toLowerCase().contains('connection failed')) ||
        error.toString().contains('SocketException')) {
      message = 'Không thể kết nối tới máy chủ. Kiểm tra mạng và thử lại.';
    } else if (error is ShoppingListRemoteException) {
      final remoteMessage = error.message.trim();
      message = remoteMessage.isNotEmpty
          ? remoteMessage
          : 'Không thể đồng bộ dữ liệu lúc này.';
    } else {
      message = 'Không thể đồng bộ dữ liệu. Vui lòng thử lại sau.';
    }

    if (_service.state.pendingOperationCount > 0) {
      message += ' Thay đổi của bạn đã được lưu và sẽ tự đồng bộ khi có mạng.';
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade900,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.orange.shade200,
          onPressed: () {
            _handleRefresh();
          },
        ),
      ),
    );
  }

  Future<void> _showListOptionsBottomSheet(ShoppingList list) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Tuỳ chỉnh danh sách',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Divider mỏng hơn
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade200,
              ),

              const SizedBox(height: 8),

              // Edit option với hover effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 250), () {
                      _showRenameListDialog(list);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryOrange.withOpacity(0.15),
                                AppTheme.primaryOrange.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppTheme.primaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đổi tên danh sách',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chỉnh sửa tên danh sách của bạn',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Divider giữa các option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade100,
                ),
              ),

              // Delete option với hover effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 250), () {
                      _confirmDeleteList(list);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.errorRed.withOpacity(0.15),
                                AppTheme.errorRed.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: AppTheme.errorRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xoá danh sách',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorRed,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Xoá vĩnh viễn danh sách này',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Huỷ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateListDialog() async {
    final controller = TextEditingController();
    final created = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Danh sách mới',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tên danh sách',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
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
                    child: const Text(
                      'Huỷ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tạo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (created != null && created.isNotEmpty) {
      await _service.createList(created);
    }
  }

  Future<void> _showRenameListDialog(ShoppingList list) async {
    final controller = TextEditingController(text: list.name);
    final renamed = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Đổi tên danh sách',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tên danh sách',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
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
                    child: const Text(
                      'Huỷ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (renamed != null && renamed.isNotEmpty) {
      await _service.renameList(list.id, renamed);
    }
  }

  Future<void> _confirmDeleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xoá danh sách',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn chắc chắn muốn xoá danh sách "${list.name}"? Thao tác này không thể hoàn tác.',
        ),
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
                  child: const Text(
                    'Huỷ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xoá',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteList(list.id);
    }
  }
}
