import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/pending_review.dart';
import '../services/community_review_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/stat_card.dart';
import 'community_review_screen.dart';
import 'review_all_clear_screen.dart';

/// Community Hub — tab 2 root.
///
/// Currently the screen has no live data source; stats and the peer-review
/// count are placeholders. The `isLoading` and `hasError` parameters let the
/// host (`MainContainer` / future `CommunityService`) drive the spec'd
/// loading / error variants (`community-hub.md §5.2`, §5.3).
class CommunityScreen extends StatefulWidget {
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

  /// Overrides the default "התחל בבדיקה" handler. When null the screen
  /// pushes [CommunityReviewScreen] itself (with a debug-only stub queue —
  /// release builds get an empty queue and land on the §7.3 empty state until
  /// the live controller from #54 is wired in).
  final VoidCallback? onStartReview;

  /// Injects the pending-review queue. When null the screen falls back to
  /// `kDebugMode ? _debugStubQueue : const []`. #54's controller will pass
  /// the live list through here without touching the heading/CTA logic.
  final List<PendingReview>? pendingReviews;

  /// Allergens catalog — passed through to AddProductWizard when the host
  /// handles add-product navigation (see [onAddProductTap]).
  final List<Allergen> allergens;

  /// Called when the user taps "הוספת מוצר חדש". Host handles navigation so
  /// it has access to allergens + brands from AppShell.
  final VoidCallback? onAddProductTap;

  /// Verified-products contribution count (community-hub.md §6, CH5). Null →
  /// the spec default of 5. No Supabase table backs this yet (§7.6); the host
  /// may inject a real value when one exists.
  final int? verifiedCount;

  /// Added-products contribution count (CH5). Null → the spec default of 2.
  final int? addedCount;

  /// Live data source for the peer-review queue (issue #54 / CR11). When
  /// provided and [pendingReviews] is null, the screen loads the queue from
  /// the `pending_reviews` table on mount and routes approve/reject decisions
  /// back through it. Left null in tests, which inject [pendingReviews]
  /// directly.
  final CommunityReviewController? reviewController;

  const CommunityScreen({
    super.key,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
    this.onStartReview,
    this.pendingReviews,
    this.allergens = const [],
    this.onAddProductTap,
    this.reviewController,
    this.verifiedCount,
    this.addedCount,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late List<PendingReview> _localQueue;

  @override
  void initState() {
    super.initState();
    _localQueue = List<PendingReview>.from(
      widget.pendingReviews ??
          (kDebugMode ? _debugStubQueue : const <PendingReview>[]),
    );
    // No queue injected but a live controller is available → pull the real
    // pending queue from Supabase. Injected `pendingReviews` (tests / hosts
    // that own the data) take precedence and skip the fetch.
    if (widget.pendingReviews == null && widget.reviewController != null) {
      _loadPending();
    }
  }

  Future<void> _loadPending() async {
    try {
      final reviews =
          await widget.reviewController!.fetchPending(widget.allergens);
      if (!mounted) return;
      setState(() => _localQueue = reviews);
    } catch (e) {
      // Leave the existing (debug-stub / empty) queue in place; the queue is a
      // soft surface and the heading/CTA already handle an empty list.
      debugPrint('community-hub: failed to load pending reviews: $e');
    }
  }

  @override
  void didUpdateWidget(CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync on every change of the incoming list identity — including a
    // null reset (e.g. logout / data clear). Resetting to null must empty the
    // local queue, otherwise stale review items linger as phantoms. The
    // debug-stub fallback is intentionally an initial-mount-only convenience,
    // so a deliberate null here clears to empty rather than re-showing stubs.
    if (!identical(oldWidget.pendingReviews, widget.pendingReviews)) {
      _localQueue = List<PendingReview>.from(
        widget.pendingReviews ?? const <PendingReview>[],
      );
    }
  }

  List<PendingReview> get _pendingReviews => _localQueue;

  bool get _canStartReview =>
      widget.onStartReview != null || _localQueue.isNotEmpty;

  /// Community points awarded per completed review this session. The review
  /// flow has no live points service yet, so this is a fixed session accumulator
  /// feeding the terminal celebration screen (spec review-all-clear §6.1/§6.4).
  static const int _pointsPerReview = 10;

  // Session accumulators driving the queue-exhaustion celebration screen.
  int _sessionReviewed = 0;
  int _sessionPoints = 0;

  Future<void> _onApprove(PendingReview review) async {
    // Persist first — if it throws, the review screen keeps the item so the
    // reviewer can retry (it surfaces its own error toast). Only drop it from
    // the local queue on success.
    await widget.reviewController?.approve(review.id);
    if (!mounted) return;
    setState(() {
      _localQueue.remove(review);
      _sessionReviewed++;
      _sessionPoints += _pointsPerReview;
    });
  }

  Future<void> _onReject(PendingReview review, String reason) async {
    await widget.reviewController?.reject(review.id, reason);
    if (!mounted) return;
    setState(() {
      _localQueue.remove(review);
      _sessionReviewed++;
      _sessionPoints += _pointsPerReview;
    });
  }

  /// Spec review-all-clear §6.4: replaces the in-review route with the terminal
  /// celebration screen once the queue is drained by completed reviews, passing
  /// the session accumulators as arguments. Guarded against an unmounted host.
  void _onQueueExhausted() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReviewAllClearScreen(
          totalPointsEarned: _sessionPoints,
          productsScanned: _sessionReviewed,
        ),
      ),
    );
  }

  void _onStartReview() {
    final override = widget.onStartReview;
    if (override != null) {
      override();
      return;
    }
    // Fresh review session — reset accumulators so a second pass through the
    // queue does not inherit the previous session's totals.
    _sessionReviewed = 0;
    _sessionPoints = 0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityReviewScreen(
          queue: List<PendingReview>.from(_localQueue),
          onApprove: _onApprove,
          onReject: _onReject,
          onQueueExhausted: _onQueueExhausted,
        ),
      ),
    );
  }

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
            if (widget.hasError) ...[
              _ErrorBanner(onRetry: widget.onRetry),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildStatsRow(),
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
          'עזרו לאחרים לגלוש בביטחה ולגלות מוצרים חדשים.',
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  String _statValue(String loaded) {
    if (widget.isLoading) return '--';
    if (widget.hasError) return '?';
    return loaded;
  }

  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: StatCard(
            value: _statValue('${widget.verifiedCount ?? 5}'),
            label: 'אומתו בהצלחה',
            icon: Icons.verified,
            accentColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            value: _statValue('${widget.addedCount ?? 2}'),
            label: 'מוצרים נוספו',
            icon: Icons.add_circle,
            accentColor: AppColors.primary,
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/community_hero.jpg',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.30),
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.primary),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.60),
                    AppColors.primary,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'עזרו לקהילה',
                  style: AppTypography.h2.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'מצאתם מוצר חדש? הוסיפו אותו כדי שכולם יוכלו לדעת אם הוא בטוח.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.90),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: widget.onAddProductTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLowest,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + AppSpacing.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.labelBold,
                  ),
                  icon: const Icon(Icons.add, size: 24),
                  label: const Text('הוספת מוצר חדש'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The RichText body for the peer-review card (community-hub.md §4.5).
  /// Empty queue collapses to a single muted line; otherwise the count is a
  /// bold primary inline run.
  Widget _peerReviewBody() {
    final count = _pendingReviews.length;
    if (count == 0) {
      return Text(
        'אין כעת מוצרים לבדיקה',
        textAlign: TextAlign.center,
        style:
            AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    final unit = count == 1 ? 'מוצר אחד' : '$count מוצרים';
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style:
            AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        children: [
          const TextSpan(text: 'ישנם '),
          TextSpan(
            text: unit,
            style: AppTypography.bodyMdBold.copyWith(color: AppColors.primary),
          ),
          const TextSpan(text: ' הממתינים לבדיקה שלך'),
        ],
      ),
    );
  }

  Widget _buildPeerReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceContainerLow),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.rate_review,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'בקרת עמיתים',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          widget.isLoading
              ? const SkeletonBox(width: 180, height: 20)
              : _peerReviewBody(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  widget.isLoading || !_canStartReview ? null : _onStartReview,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('התחל בבדיקה', style: AppTypography.labelBold),
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
        _InsightCard(
          icon: Icons.lightbulb_outline,
          accentColor: AppColors.secondary,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.05),
          borderColor: AppColors.secondary.withValues(alpha: 0.10),
          title: 'טיפ השבוע',
          titleColor: AppColors.secondary,
          body: 'איך לקרוא תוויות של יצרנים בינלאומיים בצורה בטוחה ומדויקת.',
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightCard(
          icon: Icons.groups_outlined,
          accentColor: _discussionIconColor,
          backgroundColor: AppColors.surfaceContainerLow,
          borderColor: AppColors.outlineVariant.withValues(alpha: 0.50),
          title: 'דיון פעיל',
          titleColor: AppColors.onSurface,
          body:
              'תחליפי חלב חדשים בשוק - האם הם בטוחים לאלרגיים לחלבון חלב?',
        ),
      ],
    );
  }

  // slate-600 per community-hub.md §4.6 card 2 (no exact theme token exists).
  static const Color _discussionIconColor = Color(0xFF475569);
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

/// A non-tappable editorial insight row (community-hub.md §4.6, §7.2).
/// Leading icon (RTL: visually on the right of the text in the row order) +
/// title + body. Purely presentational — no [InkWell], no navigation.
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final Color titleColor;
  final String body;

  const _InsightCard({
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.titleColor,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelBold.copyWith(color: titleColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Sample queue used only in `kDebugMode` so contributors can exercise the
// Community Review flow end-to-end without #54 (controller + `pending_reviews`
// table) in place. Release builds skip this and land on the §7.3 empty state.
//
// Allergen IDs are the real seed UUIDs from `supabase/seed.sql` (matched by
// nameHe). `product_allergens.allergen_id` is `uuid not null`, so slug IDs
// would crash any live-submit path the moment #54 wires it up — same trap
// flagged on PR #40.
const List<PendingReview> _debugStubQueue = [
  PendingReview(
    id: 'stub-1',
    productId: 'stub-product-1',
    productName: 'משקה שיבולת שועל אורגני',
    brandName: 'EcoNature',
    categoryLabel: 'חלב ומשקאות',
    allergenReports: [
      AllergenReport(
        allergen: Allergen(
          id: 'a0000000-0000-0000-0000-000000000005',
          nameHe: 'גלוטן',
        ),
        status: AllergenReportStatus.contains,
      ),
      AllergenReport(
        allergen: Allergen(
          id: 'a0000000-0000-0000-0000-000000000002',
          nameHe: 'אגוזים',
        ),
        status: AllergenReportStatus.mayContain,
      ),
      AllergenReport(
        allergen: Allergen(
          id: 'a0000000-0000-0000-0000-000000000004',
          nameHe: 'חלב',
        ),
        status: AllergenReportStatus.absent,
      ),
    ],
    contributorNote: 'הסריקה בוצעה במכולת השכונתית, התווית בעברית בלבד.',
  ),
];
