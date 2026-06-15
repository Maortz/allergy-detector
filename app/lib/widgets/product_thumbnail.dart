import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared 56×56 rounded product thumbnail used by the favorites flows
/// ([FavoritesScreen] and [SavedProductsScreen]).
///
/// Renders the network image when [imageUrl] is non-null, falling back to a
/// neutral placeholder when the URL is missing or the image fails to load.
/// Keeping sizing/styling in one place means future tweaks (corner radius,
/// error icon) only need to be made once.
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;

  const ProductThumbnail({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl == null
            ? const _ThumbnailPlaceholder()
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
              ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: AppColors.outline,
      ),
    );
  }
}
