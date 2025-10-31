import 'package:flutter/material.dart';

import '../../../model/collection.dart';
import '../../../services/recipe_api_service.dart';
import '../../../theme/app_theme.dart';
import 'create_collection_screen.dart';

class AddRecipeToCollectionSheet extends StatefulWidget {
  const AddRecipeToCollectionSheet({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
  });

  final String recipeId;
  final String recipeTitle;

  @override
  State<AddRecipeToCollectionSheet> createState() =>
      _AddRecipeToCollectionSheetState();
}

class _AddRecipeToCollectionSheetState
    extends State<AddRecipeToCollectionSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<Collection> _collections = const <Collection>[];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _addingCollectionId;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _fetchCollections() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await RecipeApiService.getMyCollections(limit: 100);
      if (!mounted) return;
      setState(() {
        _collections = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleCreateNew() async {
    if (_saving) return;
    final created = await Navigator.of(context).push<Collection>(
      MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
    );
    if (created == null || !mounted) {
      return;
    }

    setState(() {
      _collections = <Collection>[created, ..._collections];
      _searchController.clear();
    });
    await _handleSelect(created);
  }

  Future<void> _handleSelect(Collection collection) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _addingCollectionId = collection.id;
      _error = null;
    });
    try {
      await RecipeApiService.addRecipeToCollection(
        collection.id,
        widget.recipeId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _addingCollectionId = null;
        _error = e.toString();
      });
    }
  }

  List<Collection> get _filteredCollections {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _collections;
    }
    return _collections
        .where(
          (collection) =>
              collection.name.toLowerCase().contains(query) ||
              collection.description.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filteredCollections;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 480),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                  'Thêm vào bộ sưu tập',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: 'Tìm kiếm bộ sưu tập...',
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                )
              else if (_error != null && _collections.isEmpty)
                Expanded(
                  child: _ErrorState(
                    message: _error!,
                    onRetry: _fetchCollections,
                  ),
                )
              else if (filtered.isEmpty)
                Expanded(
                  child: _EmptyState(
                    onCreatePressed: _handleCreateNew,
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final collection = filtered[index];
                      final isBusy =
                          _saving && _addingCollectionId == collection.id;
                      return _CollectionTile(
                        collection: collection,
                        busy: isBusy,
                        enabled: !_saving,
                        onTap: () => _handleSelect(collection),
                      );
                    },
                  ),
                ),
              if (_error != null && _collections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorRed,
                        ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _handleCreateNew,
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                    color: AppTheme.primaryOrange,
                  ),
                  label: const Text(
                    'Tạo bộ sưu tập mới',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                        color: AppTheme.primaryOrange, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ).copyWith(
                    shadowColor: WidgetStateProperty.all(
                      AppTheme.primaryOrange,
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
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.collection,
    required this.onTap,
    required this.busy,
    required this.enabled,
  });

  final Collection collection;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final subtitle = collection.recipeCount > 0
        ? '${collection.recipeCount} công thức'
        : 'Chưa có công thức';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(208, 221, 240, 232),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.collections_bookmark_outlined,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections_bookmark_outlined,
              size: 48, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            'Chưa có bộ sưu tập phù hợp',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 220,
            child: Text(
              'Tạo bộ sưu tập mới để lưu công thức này.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onCreatePressed,
            child: const Text('Tạo bộ sưu tập'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 12),
            Text(
              'Không thể tải danh sách bộ sưu tập',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
