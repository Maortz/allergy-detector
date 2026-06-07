import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/status_badge.dart';

class ReviewNextScreen extends StatelessWidget {
  final VoidCallback? onCheckNow;
  final VoidCallback? onSkip;
  final ValueChanged<int>? onNavTap;

  const ReviewNextScreen({
    super.key,
    this.onCheckNow,
    this.onSkip,
    this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _buildBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildProductCard(),
              ),
            ),
            _buildButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: onNavTap ?? (_) {},
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.onPrimaryFixed,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'הכל נבדק!',
            style: AppTypography.h2.copyWith(color: AppColors.onPrimaryFixed),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Icon(Icons.shopping_basket,
                color: AppColors.outline, size: 64),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'חטיף שוקולד חלבי',
                        style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                      ),
                    ),
                    const StatusBadge(
                      status: AllergenStatus.avoid,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.store,
                        size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'שוקולד עלית',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.cautionBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.cautionText.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty,
                          color: AppColors.cautionText, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'ממתין לאימות',
                          style: AppTypography.labelBold
                              .copyWith(color: AppColors.cautionText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: onCheckNow,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('בדוק עכשיו'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              onPressed: onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('דלג'),
            ),
          ),
        ],
      ),
    );
  }
}