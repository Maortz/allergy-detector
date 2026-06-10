import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PhotoUploadCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;
  final String? imagePath;

  /// Optional override for rendering the captured image. Production leaves this
  /// null and the card uses [Image.file]; widget tests inject a decode-free
  /// builder so they don't depend on a real file on disk.
  @visibleForTesting
  final Widget Function(String path)? thumbnailBuilder;

  const PhotoUploadCard({
    super.key,
    this.onTap,
    this.label,
    this.imagePath,
    this.thumbnailBuilder,
  });

  static const double _tileHeight = 140;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      // Thumbnail state (spec §4): the image fills the tile; the upload prompt
      // copy is hidden; a solid primary border + re-shoot badge signal capture.
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: _tileHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(),
                // Solid primary border drawn on top of the image. Ignores
                // pointers so the whole tile stays a single tap target.
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: IgnorePointer(child: _ReshootBadge()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: _tileHeight),
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.outline,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfaceContainerLow,
        ),
        child: _buildUploadPrompt(),
      ),
    );
  }

  Widget _buildThumbnail() {
    final path = imagePath!;
    if (thumbnailBuilder != null) return thumbnailBuilder!(path);
    // image_picker on web yields blob/network paths that Image.file can't read;
    // fall back to a neutral captured-state fill there rather than crashing.
    if (kIsWeb) {
      return const ColoredBox(color: AppColors.primaryContainer);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const ColoredBox(color: AppColors.primaryContainer),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt,
            color: AppColors.onPrimaryFixed,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label ?? 'העלה תמונה',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'תמונה של המוצר או המרכיבים',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

}

/// Re-shoot / replace affordance overlaid on a captured thumbnail (spec §4):
/// a white camera glyph on a primary circular background. Tapping the tile
/// re-opens the picker, so this badge is a visual cue (the whole tile is the
/// hit target) — its semantics label keeps it accessible.
class _ReshootBadge extends StatelessWidget {
  const _ReshootBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'החלף תמונה',
      button: true,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.photo_camera,
          color: AppColors.onPrimary,
          size: 18,
        ),
      ),
    );
  }
}
