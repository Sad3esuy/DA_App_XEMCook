import 'package:flutter/material.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/services/auth_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';

class RatingCommentTile extends StatefulWidget {
  const RatingCommentTile({
    super.key,
    required this.data,
    this.expanded = false,
    this.recipeId,
    this.onDeleted,
  });

  final Map<String, dynamic> data;
  final bool expanded;
  final String? recipeId;
  final VoidCallback? onDeleted;

  @override
  State<RatingCommentTile> createState() => _RatingCommentTileState();
}

class _RatingCommentTileState extends State<RatingCommentTile> {
  bool _deleting = false;

  Future<bool> _isCurrentUserRating() async {
    final user = await AuthService().getUser();
    if (user == null) return false;
    
    final reviewer = widget.data['reviewer'];
    String? reviewerId;
    
    if (reviewer is Map) {
      reviewerId = reviewer['_id']?.toString() ?? reviewer['id']?.toString();
    }
    
    return reviewerId == user.id;
  }

  Future<void> _deleteRating() async {
    if (widget.recipeId == null || _deleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa đánh giá'),
        content: const Text('Bạn chắc chắn muốn xóa đánh giá này?'),
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
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Xóa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);

    try {
      await RecipeApiService.deleteRating(widget.recipeId!);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa đánh giá')),
      );
      
      widget.onDeleted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewer = widget.data['reviewer'] is Map
        ? Map<String, dynamic>.from(widget.data['reviewer'] as Map)
        : const <String, dynamic>{};
    final rawName = reviewer['fullName']?.toString().trim();
    final displayName =
        (rawName != null && rawName.isNotEmpty) ? rawName : 'Người dùng';
    final rawAvatar = reviewer['avatar']?.toString().trim() ?? '';
    final avatarUrl = rawAvatar.isNotEmpty 
        ? RecipeApiService.resolveImageUrl(rawAvatar)
        : '';
    final ratingValue = (widget.data['rating'] is num)
        ? (widget.data['rating'] as num).toInt().clamp(0, 5)
        : 0;
    final comment = (widget.data['comment'] as String?)?.trim();
    final createdAt = _formatDate(
        widget.data['createdAt'] as String? ?? widget.data['updatedAt'] as String?);

    final imageUrlRaw = widget.data['imageUrl']?.toString().trim() ?? '';
    final imageUrl = RecipeApiService.resolveImageUrl(imageUrlRaw);
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.secondaryYellow.withOpacity(0.3),
                backgroundImage: avatarUrl.isNotEmpty 
                    ? NetworkImage(avatarUrl) 
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (createdAt.isNotEmpty)
                      Text(
                        createdAt,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textLight),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  if (index < ratingValue) {
                    return const Icon(Icons.star,
                        size: 16, color: Colors.amber);
                  }
                  return const Icon(Icons.star_border,
                      size: 16, color: Colors.amber);
                }),
              ),
              if (widget.recipeId != null) ...[
                const SizedBox(width: 8),
                FutureBuilder<bool>(
                  future: _isCurrentUserRating(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return IconButton(
                        icon: _deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.errorRed,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                        onPressed: _deleting ? null : _deleteRating,
                        tooltip: 'Xóa đánh giá',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: AppTheme.textDark,
                  ),
            ),
          ],
          if (hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: widget.expanded ? (4 / 3) : (16 / 9),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.grey),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }
}
