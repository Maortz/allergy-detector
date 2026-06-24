import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PhotoUploadCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;
  final String? imagePath;

  /// When true the tile renders the upload-error state (spec §5 "Upload error"):
  /// an error icon, Hebrew failure copy, and a retry button wired to [onRetry].
  /// Takes precedence over the thumbnail/empty states so a failed upload is
  /// always surfaced even if a local image path is present.
  final bool isError;

  /// Invoked when the user taps the retry affordance in the error state.
  final VoidCallback? onRetry;

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
    this.isError = false,
    this.onRetry,
    this.thumbnailBuilder,
  });

  static const double _tileHeight = 140;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isError) {
      // Upload-error state (spec §5): the failure takes precedence over the
      // captured thumbnail so the user can't mistake a failed upload for a
      // successful one.
      return Container(
        constraints: const BoxConstraints(minHeight: _tileHeight),
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.error, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.errorContainer,
        ),
        child: _buildErrorState(context),
      );
    }

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
                _buildThumbnail(context),
                // Solid primary border drawn on top of the image. Ignores
                // pointers so the whole tile stays a single tap target.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16)),
                      border: Border.fromBorderSide(
                        BorderSide(color: colorScheme.primary, width: 1.5),
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
            color: colorScheme.outline,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surfaceContainerLow,
        ),
        child: _buildUploadPrompt(context),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = imagePath!;
    if (thumbnailBuilder != null) return thumbnailBuilder!(path);
    // image_picker on web yields blob/network paths that Image.file can't read;
    // fall back to a neutral captured-state fill there rather than crashing.
    if (kIsWeb) {
      return ColoredBox(color: colorScheme.primaryContainer);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          ColoredBox(color: colorScheme.primaryContainer),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: colorScheme.error,
          size: 28,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'העלאת התמונה נכשלה',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(
            color: colorScheme.onErrorContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('נסה שוב'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPrompt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.camera_alt,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label ?? 'העלה תמונה',
          style: AppTypography.bodyMd.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'תמונה של המוצר או המרכיבים',
          style: AppTypography.labelSm.copyWith(
            color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'החלף תמונה',
      button: true,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.photo_camera,
          color: colorScheme.onPrimary,
          size: 18,
        ),
      ),
    );
  }
}
