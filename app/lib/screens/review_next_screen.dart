import 'package:flutter/material.dart';
import '../models/review_queue_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/skeleton_box.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Post-review success + next-item funnel screen.
///
/// Spec: `review-next-item.md`. Stitch art: `2d3d5126490f4c5496fc194b35a865a7`.
///
/// This is a **push destination** — no [BottomNavigationBar] is rendered
/// (spec §7.1). The caller pops this screen or replaces it; it is not a tab.
///
/// All business-logic actions are exposed as nullable callbacks so the screen
/// is fully testable without navigation infrastructure.
class ReviewNextScreen extends StatefulWidget {
  /// Points earned for the just-completed review.
  final int pointsEarned;

  /// User's updated weekly community rank.
  final int newWeeklyRank;

  /// The next product queued for review. When `null`, an empty-queue message
  /// is shown instead of the product card (spec §5.7).
  final ReviewQueueItem? nextItem;

  /// When `true` the product card shows a shimmer skeleton and the primary
  /// action button is disabled (spec §5.2).
  final bool isLoading;

  /// Fired when the user taps "בדוק עכשיו".
  final VoidCallback? onCheckNow;

  /// Fired when the user taps "דלג" (inline skip link).
  final VoidCallback? onSkip;

  /// Fired when the user taps "חזרה לדף הבית".
  final VoidCallback? onGoHome;

  const ReviewNextScreen({
    super.key,
    this.pointsEarned = 0,
    this.newWeeklyRank = 0,
    this.nextItem,
    this.isLoading = false,
    this.onCheckNow,
    this.onSkip,
    this.onGoHome,
  });

  @override
  State<ReviewNextScreen> createState() => _ReviewNextScreenState();
}

class _ReviewNextScreenState extends State<ReviewNextScreen> {
  // Local-only favourite toggle state. [ReviewQueueItem] is owned by the parent
  // and never mutated from here; persisting a favourite is out of scope until a
  // backing store / callback exists (spec §6.2, #56 deferred).
  bool _isFavourited = false;

  @override
  void didUpdateWidget(ReviewNextScreen old) {
    super.didUpdateWidget(old);
    // A new product reaching the slot resets the local toggle.
    if (widget.nextItem?.id != old.nextItem?.id) {
      _isFavourited = false;
    }
  }

  void _toggleFavourite() {
    setState(() => _isFavourited = !_isFavourited);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surfaceContainerLowest,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'בטוח לאכול',
            style: AppTypography.labelBold.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        // No bottomNavigationBar — spec §7.1.
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSuccessHero(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildGamificationBento(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildNextProductSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildHomeButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // §4.2 — Success hero
  // ---------------------------------------------------------------------------

  Widget _buildSuccessHero() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Column(
      children: [
        // 96 pt success-tint circle + filled check_circle (spec §4.2 / DD-10).
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: appColors.success.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle,
            color: appColors.success,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'תודה על תרומתך!',
          style: AppTypography.h1.copyWith(color: colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'הביקורת שלך עוזרת לאלפי משתמשים לבחור מוצרים בבטחה ובביטחון.',
          style:
              AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // §4.3 — Gamification bento grid
  // ---------------------------------------------------------------------------

  Widget _buildGamificationBento() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _GamificationCard(
            value: '+${widget.pointsEarned}',
            label: 'נקודות קהילה',
            valueColor: context.colors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _GamificationCard(
            // Rank 0 means "unknown" (no rank-query API wired yet) — show an
            // em-dash placeholder rather than a misleading "#0".
            value: widget.newWeeklyRank > 0 ? '#${widget.newWeeklyRank}' : '#—',
            label: 'דירוג שבועי',
            valueColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // §4.4 — Next product section (header + card)
  // ---------------------------------------------------------------------------

  Widget _buildNextProductSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header row: "המוצר הבא לבדיקה" (leading) + "דלג" (trailing).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'המוצר הבא לבדיקה',
              style: AppTypography.h2.copyWith(color: colorScheme.onSurface),
            ),
            if (!widget.isLoading)
              TextButton(
                onPressed: widget.onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  textStyle: AppTypography.labelBold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('דלג'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Product card or skeleton.
        if (widget.isLoading) ...[
          const _ProductCardSkeleton(),
          const SizedBox(height: AppSpacing.md),
          _buildActionRow(),
        ] else
          _buildProductCard(),
      ],
    );
  }

  Widget _buildProductCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    final item = widget.nextItem;

    // §5.7 — empty-queue state.
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          'אין מוצרים נוספים לסקירה כרגע',
          style:
              AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image hero (192 pt, BoxFit.cover) with overlay badge.
          _buildProductImageHero(item),
          // Card body: meta + action row.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductMeta(item),
                const SizedBox(height: AppSpacing.lg),
                _buildActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Product image hero with "חשד לאלרגנים" frosted overlay badge (spec §4.4 / RN6).
  Widget _buildProductImageHero(ReviewQueueItem item) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 192,
          child: item.imageUrl.isNotEmpty
              ? Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        // Overlay badge pinned to the leading edge (visual top-right in RTL).
        // PositionedDirectional resolves `start` against the ambient text
        // direction, so it follows RTL instead of a fixed physical edge.
        PositionedDirectional(
          top: AppSpacing.md,
          start: AppSpacing.md,
          child: _AlertBadge(label: item.alertLabel),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.shopping_basket,
        color: colorScheme.outline,
        size: 64,
      ),
    );
  }

  /// Category, name, description meta column (spec §4.4 body).
  Widget _buildProductMeta(ReviewQueueItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.categoryLabel.toUpperCase(),
          style: AppTypography.labelSm.copyWith(
            color: colorScheme.outline,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.name,
          style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          style:
              AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// "בדוק עכשיו" (flex-1) + favourite icon button (48×48) row (spec §4.4 RN8).
  Widget _buildActionRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: widget.isLoading ? null : widget.onCheckNow,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.surfaceContainerHigh,
              disabledForegroundColor: colorScheme.outline,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'בדוק עכשיו',
                  style: AppTypography.labelBold
                      .copyWith(color: colorScheme.onPrimary),
                ),
                const SizedBox(width: AppSpacing.xs),
                // §7.3: canonical primary-button forward arrow in RTL.
                const Icon(Icons.chevron_left, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Favourite icon button — 48×48 pt (spec §4.4 RN8 / §5.5).
        SizedBox(
          width: 48,
          height: 48,
          child: OutlinedButton(
            onPressed: _toggleFavourite,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(color: appColors.borderSubtle, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Icon(
              _isFavourited ? Icons.favorite : Icons.favorite_border,
              color: _isFavourited ? colorScheme.primary : appColors.iconMuted,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // §4.5 — "חזרה לדף הבית" ghost button (RN9)
  // ---------------------------------------------------------------------------

  Widget _buildHomeButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: widget.onGoHome,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.labelBold,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.home, size: 24),
      label: const Text('חזרה לדף הבית'),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Gamification stat card per spec §4.3.
class _GamificationCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _GamificationCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              value,
              style: AppTypography.h3.copyWith(color: valueColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// "חשד לאלרגנים" frosted-pill overlay badge (spec §4.4 RN6 / §7.5).
class _AlertBadge extends StatelessWidget {
  final String label;

  const _AlertBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.frostedSurface,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, size: 16, color: appColors.cautionText),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmBold
                .copyWith(color: appColors.cautionText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the product card while the next item is loading.
/// Spec ref: `review-next-item.md §5.2`.
class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 100, height: 12),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 220, height: 18),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: double.infinity, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
