import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/bento_card.dart';
import '../widgets/skeleton_box.dart';

/// Community Hub — tab 2 root.
///
/// Currently the screen has no live data source; stats and the peer-review
/// count are placeholders. The `isLoading` and `hasError` parameters let the
/// host (`MainContainer` / future `CommunityService`) drive the spec'd
/// loading / error variants (`community-hub.md §5.2`, §5.3).
class CommunityScreen extends StatelessWidget {
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;

  /// When `true`, the stats and peer-review row render placeholders ("--"
  /// digits / skeleton) per `community-hub.md §5.2`.
  final bool isLoading;

  /// When `true`, the stats fall back to "?" and a non-blocking error banner
  /// is shown above the bento per `community-hub.md §5.3`.
  final bool hasError;

  /// Tapped when the user taps "נסה שוב" on the error banner.
  final VoidCallback? onRetry;

  const CommunityScreen({
    super.key,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: AppSpacing.lg),
            if (hasError) ...[
              _ErrorBanner(onRetry: onRetry),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildStatsBento(),
            const SizedBox(height: AppSpacing.lg),
            _buildHelpCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildPeerReviewCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildTipsSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הכוח שלנו הוא בידע',
          style: AppTypography.h1.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'יחד אנחנו בונים מאגר מזון בטוח לכולם',
          style:
              AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  String _statValue(String loaded) {
    if (isLoading) return '--';
    if (hasError) return '?';
    return loaded;
  }

  Widget _buildStatsBento() {
    return Row(
      children: [
        Expanded(
          child: BentoCard(
            label: 'אומתו בהצלחה',
            value: _statValue('5'),
            icon: Icons.verified,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: BentoCard(
            label: 'מוצרים נוספו',
            value: _statValue('2'),
            icon: Icons.add_shopping_cart,
          ),
        ),
      ],
    );
  }

  Widget _buildHelpCard() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                color: AppColors.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'הוספת מוצר חדש',
                style: AppTypography.h3.copyWith(
                  color: AppColors.onPrimaryFixed,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.onPrimaryFixedVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerReviewCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: isLoading
                ? const SkeletonBox(width: 180, height: 20)
                : Text(
                    hasError
                        ? '? מוצרים ממתינים לבדיקה'
                        : '12 מוצרים ממתינים לבדיקה',
                    style:
                        AppTypography.h3.copyWith(color: AppColors.onSurface),
                  ),
          ),
          FilledButton(
            onPressed: isLoading ? null : () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(
              'התחל בבדיקה',
              style: AppTypography.labelBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'טיפ השבוע',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'בדוק את הרכיבים הפעילים',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'לפעמים אלרגנים מסתתרים בשמות לא צפויים',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.forum,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'דיון פעיל',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'האם "סירופ תירס" מכיל גלוטן?',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Non-blocking error banner shown above the stats when the Supabase fetch
/// fails. Spec ref: `community-hub.md §5.3`.
class _ErrorBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorBanner({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: AppColors.onErrorContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'לא ניתן לטעון נתונים — בדוק חיבור לאינטרנט.',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onErrorContainer,
              ),
              child: Text(
                'נסה שוב',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
