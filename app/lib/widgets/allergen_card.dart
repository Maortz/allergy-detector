import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AllergenCard extends StatelessWidget {
  final Allergen allergen;
  final bool isSelected;

  /// When `true` the card renders as a disabled chip (40% opacity icon+label,
  /// `lock` badge, no taps), per spec
  /// `add-product-step-4-may-contain.md §7.2` — used on step 4 for allergens
  /// already selected as "contains" in step 3.
  final bool locked;
  final VoidCallback? onTap;

  const AllergenCard({
    super.key,
    required this.allergen,
    this.isSelected = false,
    this.locked = false,
    this.onTap,
  });

  IconData _getIcon() {
    // Catalog IDs are UUIDs, so match on the English name first (populated for
    // every seeded allergen) and fall back to the id for any legacy slug usage.
    final key = '${allergen.nameEn ?? ''} ${allergen.id}'.toLowerCase();
    if (key.contains('shellfish') || key.contains('crustacean')) {
      return Icons.pool;
    } else if (key.contains('peanut')) {
      // DD-9 / spec S4-6: peanut → `park`.
      return Icons.park;
    } else if (key.contains('nut')) {
      return Icons.spa;
    } else if (key.contains('milk') || key.contains('dairy')) {
      return Icons.water_drop;
    } else if (key.contains('egg')) {
      return Icons.egg;
    } else if (key.contains('wheat') || key.contains('gluten')) {
      return Icons.grass;
    } else if (key.contains('soy')) {
      return Icons.eco;
    } else if (key.contains('fish')) {
      return Icons.set_meal;
    } else if (key.contains('sesame')) {
      return Icons.grain;
    }
    return Icons.warning_amber;
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
              color: isSelected
                  ? AppColors.primaryFixed
                  : AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              color: isSelected
                  ? AppColors.onPrimaryFixed
                  : AppColors.onPrimary,
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
    );

    if (locked) {
      // Disabled-chip variant per `add-product-step-4-may-contain §7.2`:
      // 40% opacity icon+label, lock badge top-start, no taps.
      return IgnorePointer(
        ignoring: true,
        child: Tooltip(
          message: 'כבר סומן בשלב 3',
          child: Stack(
            children: [
              Opacity(opacity: 0.4, child: card),
              const PositionedDirectional(
                top: 6,
                start: 6,
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
