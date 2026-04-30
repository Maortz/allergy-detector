import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AllergenCard extends StatelessWidget {
  final Allergen allergen;
  final bool isSelected;
  final VoidCallback? onTap;

  const AllergenCard({
    super.key,
    required this.allergen,
    this.isSelected = false,
    this.onTap,
  });

  IconData _getIcon() {
    final id = allergen.id.toLowerCase();
    if (id.contains('milk') || id.contains('dairy') || id.contains('milk')) {
      return Icons.water_drop;
    } else if (id.contains('egg')) {
      return Icons.egg;
    } else if (id.contains('wheat') || id.contains('gluten')) {
      return Icons.grass;
    } else if (id.contains('soy')) {
      return Icons.eco;
    } else if (id.contains('nut') || id.contains('peanut')) {
      return Icons.spa;
    } else if (id.contains('fish')) {
      return Icons.set_meal;
    } else if (id.contains('shellfish') || id.contains('crustacean')) {
      return Icons.pool;
    } else if (id.contains('sesame')) {
      return Icons.grain;
    }
    return Icons.warning_amber;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryFixed : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                color: isSelected ? AppColors.onPrimaryFixed : AppColors.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              allergen.nameHe,
              style: AppTypography.labelBold.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}