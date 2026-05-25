import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bento_card.dart';
import '../widgets/bottom_nav_bar.dart';

/// Terminal celebration screen shown when the community review queue is
/// exhausted. Stats are passed in from the completing review action.
class ReviewAllClearScreen extends StatelessWidget {
  final int totalPointsEarned;
  final int productsScanned;
  final VoidCallback? onReturnHome;

  const ReviewAllClearScreen({
    super.key,
    this.totalPointsEarned = 0,
    this.productsScanned = 0,
    this.onReturnHome,
  });

  void _goHome() => onReturnHome?.call();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'בטוח לאכול',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  children: [
                    _buildHero(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildStats(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildHomeButton(),
                    const SizedBox(height: AppSpacing.md),
                    _buildSecondaryLine(),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
          onTap: (_) => _goHome(),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: AppColors.onPrimary,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'כל הכבוד!',
          style: AppTypography.h1.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'אין מוצרים נוספים להיום. עזרת לקהילה לדעת במה לסמוך בבחירות המזון שלה.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: BentoCard(
            label: 'נקודות קהילה',
            value: '$totalPointsEarned+',
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: BentoCard(
            label: 'מוצרים שנסרקו',
            value: '$productsScanned',
            valueColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _goHome,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'חזרה לבית',
              style: AppTypography.labelBold.copyWith(color: AppColors.onPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_left, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryLine() {
    return Text(
      'תוצאות הסקירה נשמרו בפרופיל שלך',
      style: AppTypography.labelSm.copyWith(color: AppColors.outline),
      textAlign: TextAlign.center,
    );
  }
}
