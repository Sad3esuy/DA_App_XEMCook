import 'package:flutter/material.dart';

import '../model/recipe.dart';
import '../theme/app_theme.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onToggleFavorite,
    this.isFavorite = false,
    this.isFavoriteBusy = false,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final Future<void> Function()? onToggleFavorite;
  final bool isFavorite;
  final bool isFavoriteBusy;

  @override
  Widget build(BuildContext context) {
    final totalTime = recipe.prepTime + recipe.cookTime;
    final likes =
        recipe.totalRatings > 0 ? recipe.totalRatings : recipe.ratings.length;
    final tag = recipe.tags.isNotEmpty ? recipe.tags.first.trim() : '';
    final authorName = (recipe.authorName ?? '').trim();
    final hasAvatar =
        recipe.authorAvatar != null && recipe.authorAvatar!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                        if (totalTime > 0) _Badge(label: '${totalTime} min'),
                        if (tag.isNotEmpty)
                          _Badge(
                            label: _formatTag(tag),
                            foreground: AppTheme.accentGreen,
                            background: const Color(0xFFE7F8ED),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _FavoritePill(
                      count: likes,
                      isFavorite: isFavorite,
                      isBusy: isFavoriteBusy,
                      onPressed: onToggleFavorite,
                    ),
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
                          backgroundImage: hasAvatar
                              ? NetworkImage(recipe.authorAvatar!)
                              : null,
                          child: hasAvatar
                              ? null
                              : const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppTheme.primaryOrange,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authorName.isEmpty ? 'Anonymous' : authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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

class _FavoritePill extends StatelessWidget {
  const _FavoritePill({
    required this.count,
    required this.isFavorite,
    required this.isBusy,
    this.onPressed,
  });

  final int count;
  final bool isFavorite;
  final bool isBusy;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconData = isFavorite ? Icons.favorite : Icons.favorite_border;
    final iconColor = isFavorite ? Colors.red : AppTheme.primaryOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: (isBusy || onPressed == null)
            ? null
            : () async {
                try {
                  await onPressed!.call();
                } catch (_) {
                  // Parent handles error surface, ignore here
                }
              },
        child: Container(
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: isBusy
                ? const SizedBox(
                    key: ValueKey('favorite-loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                    ),
                  )
                : Row(
                    key: ValueKey<bool>(isFavorite),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 16, color: iconColor),
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
          ),
        ),
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

String _formatTag(String value) {
  if (value.isEmpty) return value;
  final trimmed = value.trim();
  if (trimmed.length <= 1) {
    return trimmed.toUpperCase();
  }
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}
