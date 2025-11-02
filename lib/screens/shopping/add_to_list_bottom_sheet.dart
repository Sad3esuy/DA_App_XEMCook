import 'package:flutter/material.dart';
import '../../model/recipe.dart';
import '../../model/shopping_item.dart';
import '../../services/shopping_list_service.dart';
import '../../utils/id_utils.dart';

class AddToShoppingListSheet extends StatefulWidget {
  const AddToShoppingListSheet({
    super.key,
    required this.recipe,
    this.initialServings,
  });

  final Recipe recipe;
  final double? initialServings;

  @override
  State<AddToShoppingListSheet> createState() => _AddToShoppingListSheetState();
}

class _AddToShoppingListSheetState extends State<AddToShoppingListSheet> {
  final ShoppingListService _service = ShoppingListService.instance;
  final TextEditingController _newListController = TextEditingController();
  double _targetServings = 0;
  String? _selectedListId;
  bool _creatingList = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialServings;
    if (initial != null && initial > 0) {
      _targetServings = initial;
    } else {
      _targetServings = widget.recipe.servings.toDouble();
    }
    final state = _service.state;
    if (state.lists.isEmpty) {
      _creatingList = true;
    } else {
      _selectedListId = state.selectedListId ?? state.lists.first.id;
    }
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.state;
    final lists = state.lists;
    final previewItems = _buildPreviewItems();
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.70, // Giới hạn 55% màn hình
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm vào giỏ',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.recipe.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: const Color.fromARGB(255, 238, 238, 238)),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Servings Adjuster
                    _buildServingsSection(theme),
                    const SizedBox(height: 28),

                    // Shopping List Selection
                    _buildListSelectionSection(theme, lists),
                    const SizedBox(height: 28),

                    // Ingredients Preview
                    _buildIngredientsPreview(theme, previewItems),
                    const SizedBox(height: 28),

                    // Submit Button
                    _buildSubmitButton(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_menu, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Số khẩu phần',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildServingButton(
                icon: Icons.remove,
                onPressed: _targetServings > 0.5
                    ? () => setState(() {
                          _targetServings = (_targetServings - 0.5)
                              .clamp(0.5, double.infinity);
                        })
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _targetServings.toStringAsFixed(
                          _targetServings.truncateToDouble() == _targetServings
                              ? 0
                              : 1),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khẩu phần gốc dành cho ${widget.recipe.servings} người',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildServingButton(
                icon: Icons.add,
                onPressed: () => setState(() {
                  _targetServings = (_targetServings + 0.5)
                      .clamp(0.5, widget.recipe.servings * 4.0);
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServingButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed != null ? Colors.white : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onPressed != null
                ? Theme.of(context).primaryColor
                : Colors.grey.shade400,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildListSelectionSection(ThemeData theme, List lists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Chọn danh sách',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (lists.isNotEmpty) ...[
          ...lists.map((list) => _buildListOption(theme, list)),
          const SizedBox(height: 8),
        ],
        _buildListOption(
          theme,
          null,
          isNewList: true,
        ),
        if (_creatingList)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: _newListController,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên danh sách',
                hintText: 'VD: Mua sắm tuần này',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListOption(
    ThemeData theme,
    dynamic list, {
    bool isNewList = false,
  }) {
    final isSelected = isNewList
        ? _creatingList
        : (!_creatingList && list?.id == _selectedListId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isNewList) {
                _creatingList = true;
                _selectedListId = null;
              } else {
                _creatingList = false;
                _selectedListId = list.id;
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.primaryColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isNewList ? Icons.add_circle_outline : Icons.list_rounded,
                  color: isSelected ? theme.primaryColor : Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isNewList ? 'Tạo danh sách mới' : list.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.primaryColor
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.primaryColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsPreview(ThemeData theme, List<ShoppingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Nguyên liệu (${items.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final quantityParts = <String>[];
                if (item.quantity != null && item.quantity!.isNotEmpty) {
                  quantityParts.add(item.quantity!);
                }
                if (item.unit != null && item.unit!.isNotEmpty) {
                  quantityParts.add(item.unit!);
                }
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: quantityParts.isEmpty
                      ? null
                      : Text(
                          quantityParts.join(' '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 40,
                color: Colors.grey.shade100,
              ),
              itemCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Column(
      children: [
        if (_submitting)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_shopping_cart, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thêm vào danh sách',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  List<ShoppingItem> _buildPreviewItems() {
    final ratio = widget.recipe.servings <= 0
        ? 1.0
        : _targetServings / widget.recipe.servings;
    return widget.recipe.ingredients
        .map((ingredient) => ShoppingItem.fromIngredient(
              ingredient,
              shoppingListId: generateId(),
              ratio: ratio,
              recipeTitle: widget.recipe.title,
            ))
        .toList();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    final target = _targetServings.clamp(0.5, 200.0);
    setState(() => _submitting = true);
    try {
      String listId;
      if (_creatingList || _service.state.lists.isEmpty) {
        final name = _newListController.text.trim().isEmpty
            ? 'Danh sách mới'
            : _newListController.text.trim();
        listId = await _service.createList(name);
      } else {
        listId = _selectedListId ?? _service.state.selectedListId!;
      }
      await _service.addRecipeToList(listId, widget.recipe, target);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thêm vào danh sách: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
