import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PhotoUploadCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;
  final String? imagePath;

  const PhotoUploadCard({
    super.key,
    this.onTap,
    this.label,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.outline,
            width: hasImage ? 2 : 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: hasImage ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
        ),
        child: hasImage ? _buildImagePreview() : _buildUploadPrompt(),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
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

  Widget _buildImagePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: AppColors.onPrimary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label ?? 'תמונה נבחרה',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'לחץ להחלפה',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
