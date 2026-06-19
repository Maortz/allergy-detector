import 'package:flutter/material.dart';

import '../models/pending_review.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/skeleton_box.dart';

/// Post-review success screen shown after each approved or rejected item in the
/// community review session (spec: `review-next-item.md`).
///
/// Flow: `CommunityReviewScreen → ReviewNextScreen → [repeat] or → ReviewAllClearScreen`.
///
/// The bottom navigation bar is **suppressed** on this screen (RN10): it is
/// always pushed as a `Navigator.push` destination outside `MainContainer`'s
/// `IndexedStack`, never embedded in a tab.
///
/// When [nextItem] is null the queue is exhausted — the product card section
/// is hidden and a message is shown in its place (RN12 / §5.7).
class ReviewNextScreen extends StatelessWidget {
  /// Points credited this session so far (displayed as "+N").
  final int pointsEarned;

  /// Products reviewed this session (displayed as "N מוצרים נסקרו").
  final int productsReviewed;

  /// The next item in the queue. Null when the queue is exhausted (§5.7).
  final PendingReview? nextItem;

  /// Called when the reviewer taps "בדוק עכשיו" (RN8).
  final VoidCallback? onCheckNow;

  /// Called when the reviewer taps the "דלג" skip link (RN4).
  final VoidCallback? onSkip;

  /// Called when the reviewer taps "חזרה לדף הבית" (RN9).
  final VoidCallback? onGoHome;

  /// When true the product card area renders shimmer skeletons and action
  /// buttons are disabled (§5.2).
  final bool isLoading;

  const ReviewNextScreen({
    super.key,
    required this.pointsEarned,
    required this.productsReviewed,
    this.nextItem,
    this.onCheckNow,
    this.onSkip,
    this.onGoHome,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        // RN10: no BottomNavBar — this screen is a pushed route outside
        // MainContainer's IndexedStack.
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildGamificationBento(),
                  const SizedBox(height: AppSpacing.xl),
                  if (isLoading)
                    const _ProductCardSkeleton()
                  else if (nextItem != null)
                    _buildNextProductSection(context)
                  else
                    _buildExhaustedMessage(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildGoHomeButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero (RN1) ─────────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Column(
      children: [
        _buildHeroCircle(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'תודה על תרומתך!',
          style: AppTypography.h1.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            'הביקורת שלך עוזרת לאלפי משתמשים לבחור מוצרים בבטחה ובביטחון.',
            style:
                AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCircle() {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle,
        color: AppColors.onSecondaryContainer,
        size: 48,
      ),
    );
  }

  // ─── Gamification bento (RN2/RN3) ───────────────────────────────────────────

  Widget _buildGamificationBento() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '+$pointsEarned',
            label: 'נקודות קהילה',
            valueColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            value: '$productsReviewed',
            label: 'מוצרים נסקרו',
            valueColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ─── Next product section (RN4–RN8) ─────────────────────────────────────────

  Widget _buildNextProductSection(BuildContext context) {
    final item = nextItem!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // RN4: section header row — "המוצר הבא לבדיקה" + "דלג" skip link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'המוצר הבא לבדיקה',
              style: AppTypography.h2.copyWith(color: AppColors.onSurface),
            ),
            TextButton(
              onPressed: isLoading ? null : onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.labelBold,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('דלג'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Product card
        _buildProductCard(context, item),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, PendingReview item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RN5: product image hero with RN6 overlay badge
          Stack(
            children: [
              _buildProductImage(item),
              const _AllergenSuspicionBadge(), // RN6
            ],
          ),
          // RN7: product meta + RN8: action row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category label (uppercase per spec)
                Text(
                  item.categoryLabel.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.outline,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.productName,
                  style:
                      AppTypography.h3.copyWith(color: AppColors.onSurface),
                ),
                if (item.contributorNote != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.contributorNote!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                // RN8: action row — "בדוק עכשיו" + favourite
                _buildActionRow(context, item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(PendingReview item) {
    return SizedBox(
      height: 192,
      width: double.infinity,
      child: item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imageErrorPlaceholder(),
            )
          : _imageErrorPlaceholder(),
    );
  }

  Widget _imageErrorPlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Icon(
        Icons.shopping_basket,
        color: AppColors.outline,
        size: 64,
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, PendingReview item) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isLoading ? null : onCheckNow,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // chevron_left = RTL forward arrow per canonical button spec
            icon: const Icon(Icons.chevron_left, size: 20),
            label: const Text('בדוק עכשיו'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // RN8: favourite icon button (stateful toggle)
        _FavouriteButton(allergenReports: item.allergenReports),
      ],
    );
  }

  // ─── Queue exhausted message (§5.7) ─────────────────────────────────────────

  Widget _buildExhaustedMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'אין מוצרים נוספים לסקירה כרגע',
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Ghost home button (RN9) ─────────────────────────────────────────────────

  Widget _buildGoHomeButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onGoHome,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelBold,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.home, size: 24),
        label: const Text('חזרה לדף הבית'),
      ),
    );
  }
}

// ─── Stat card (RN2) ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.h3.copyWith(color: valueColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── "חשד לאלרגנים" overlay badge (RN6) ──────────────────────────────────────

class _AllergenSuspicionBadge extends StatelessWidget {
  const _AllergenSuspicionBadge();

  static const Color _amber = Color(0xFFB05B00);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.md,
      right: AppSpacing.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 16, color: _amber),
            const SizedBox(width: 4),
            Text(
              'חשד לאלרגנים',
              style: AppTypography.labelSm.copyWith(
                color: _amber,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Favourite icon button (RN8) ─────────────────────────────────────────────

/// A stateful toggle heart button for the next-product card.
/// Toggles between [Icons.favorite_border] (default) and
/// [Icons.favorite] (favourited), local to this session only.
class _FavouriteButton extends StatefulWidget {
  final List<AllergenReport> allergenReports;

  const _FavouriteButton({required this.allergenReports});

  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton> {
  bool _isFavourited = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: () => setState(() => _isFavourited = !_isFavourited),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.surfaceContainerHigh,
            width: 2,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Icon(
          _isFavourited ? Icons.favorite : Icons.favorite_border,
          size: 24,
          color: _isFavourited ? AppColors.primary : AppColors.iconMuted,
        ),
      ),
    );
  }
}

// ─── Loading skeleton (RN12) ─────────────────────────────────────────────────

/// Shimmer skeleton for the product card while the next queued item is being
/// fetched (§5.2).
class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: double.infinity,
            height: 192,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 80, height: 12),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 220, height: 20),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: AppSpacing.lg),
                SkeletonBox(width: double.infinity, height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
