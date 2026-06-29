import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bento_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'main_container.dart';

/// Terminal celebration screen shown when the community review queue is
/// exhausted. Stats are passed in from the completing review action.
class ReviewAllClearScreen extends StatelessWidget {
  final int totalPointsEarned;
  final int productsScanned;
  final VoidCallback? onReturnHome;

  /// Optional per-tab routing for the bottom nav. Receives the tapped index.
  /// If null, taps pop back to [MainContainer] and select the tapped tab via
  /// [MainContainer.switchToTab].
  final ValueChanged<int>? onNavTap;

  const ReviewAllClearScreen({
    super.key,
    this.totalPointsEarned = 0,
    this.productsScanned = 0,
    this.onReturnHome,
    this.onNavTap,
  });

  void _goHome() => onReturnHome?.call();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Spec §4.1: brand-bar variant — both page surface and bar are
        // the lowest container surface, not the page-grey background token.
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surfaceContainerLowest,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'בטוח לאכול',
            // Brand-bar variant per spec §4.1 + _components-glossary #app-bar:
            // Inter Medium 16pt in the primary colour, not Public Sans h3 black.
            style: AppTypography.labelBold.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
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
                    _buildHero(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildStats(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildHomeButton(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildSecondaryLine(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildIllustration(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
          onTap: onNavTap ?? (i) => MainContainer.switchToTab(context, i),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildHeroBadge(context),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'כל הכבוד!',
          style: AppTypography.h1.copyWith(color: colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'אין מוצרים נוספים להיום. עזרת לקהילה לדעת במה לסמוך בבחירות המזון שלה.',
          style:
              AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Spec §4.2: the 96 pt primary hero circle plus decorative sparkle glints.
  /// The glints are pure-Flutter [Icon]s positioned at the four diagonal
  /// corners (~45°/135°/225°/315°) around the circle, so no asset dependency.
  Widget _buildHeroBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const double circle = 96;
    const double glint = 14;
    // Padding gives the corner glints room to sit outside the circle without
    // being clipped by the Stack bounds.
    const double pad = 12;
    return SizedBox(
      width: circle + pad * 2,
      height: circle + pad * 2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              // Spec §4.2: primary-tinted shadow lifts the medal off the page.
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium,
              color: colorScheme.onPrimary,
              size: 48,
            ),
          ),
          // Four sparkle glints at the diagonal corners.
          const Positioned(top: 0, right: 0, child: _Glint(size: glint)),
          const Positioned(top: 0, left: 0, child: _Glint(size: glint - 4)),
          const Positioned(bottom: 0, right: 0, child: _Glint(size: glint - 4)),
          const Positioned(bottom: 0, left: 0, child: _Glint(size: glint)),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: BentoCard(
            label: 'נקודות קהילה',
            value: '$totalPointsEarned+',
            valueColor: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: BentoCard(
            label: 'מוצרים שנסרקו',
            value: '$productsScanned',
            valueColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _goHome,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
              style:
                  AppTypography.labelBold.copyWith(color: colorScheme.onPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_left, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryLine(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Spec §4.5 + §7.5 (resolved): informational, non-navigating line. Rendered
    // as a disabled [TextButton] (no tap handler) rather than a bare [Text] so
    // it carries the ghost-link affordance the design calls for while remaining
    // inert. Inter Regular 13 pt, AppColors.outline.
    return TextButton(
      onPressed: null,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.outline,
        textStyle: AppTypography.labelSm,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'תוצאות הסקירה נשמרו בפרופיל שלך',
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Spec §4.6 + §7.6: decorative "Safe Food Lab" illustration, ~180 pt tall,
  /// 12 pt rounded corners. The original art asset
  /// (`assets/images/review_all_clear.jpg`) was a 1×1 placeholder JPEG that,
  /// stretched full-bleed with `BoxFit.cover`, painted a solid black block below
  /// the CTA (#327). Until real art ships, render an on-theme decorative panel
  /// instead. Decorative only — excluded from semantics.
  // TODO(#344): replace with the real 'Safe Food Lab' illustration once the
  // asset ships — tracked in https://github.com/Maortz/allergy-detector/issues/344.
  Widget _buildIllustration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        key: const Key('all_clear_illustration'),
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.spa_outlined,
          size: 64,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// A single decorative sparkle glint (spec §4.2). Pure Flutter — no asset.
class _Glint extends StatelessWidget {
  final double size;

  const _Glint({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star,
      size: size,
      color: context.colors.primaryTintBorder,
    );
  }
}
