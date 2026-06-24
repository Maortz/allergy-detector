import 'package:flutter/material.dart';

/// Shared 48×48 rounded product thumbnail used by the community review flows
/// ([MyReviewsScreen] and [ContributionHistoryScreen]).
///
/// Renders the network image when [imageUrl] is non-null, falling back to
/// [fallbackIcon] when the URL is missing or the image fails to load. Each
/// caller supplies its own [fallbackIcon] so screen-specific placeholders are
/// preserved while sizing/styling stays defined in one place.
class ProductThumb extends StatelessWidget {
  /// The product image URL, or null to show [fallbackIcon].
  final String? imageUrl;

  /// Placeholder icon shown when [imageUrl] is null or fails to load.
  final IconData fallbackIcon;

  const ProductThumb({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallback = Icon(fallbackIcon, color: colorScheme.onSurfaceVariant);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}
