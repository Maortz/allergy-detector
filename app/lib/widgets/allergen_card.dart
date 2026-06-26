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
    // DD-13: unselected and selected both use white bg; only border changes.
    // Icon and label colours are IDENTICAL in both states (spec §4 / S3-6).
    final unselectedBorderColor = context.colors.borderSubtle;
    const selectedBorderColor = AppColors.primary;

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest, // white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? selectedBorderColor : unselectedBorderColor,
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(),
            size: 24,
            color: AppColors.outline, // unchanged across states
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            allergen.nameHe,
            style: AppTypography.labelBold.copyWith(
              color: AppColors.onSurfaceVariant, // unchanged across states
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

    // Wrap selected card in Stack to add the check_circle badge (DD-13).
    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            card,
            const PositionedDirectional(
              top: 6,
              start: 6,
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
