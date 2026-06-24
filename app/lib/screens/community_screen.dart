import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/pending_review.dart';
import '../models/review_queue_item.dart';
import '../services/community_review_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/skeleton_box.dart';
import '../services/review_queue_service.dart';
import '../widgets/stat_card.dart';
import 'community_review_screen.dart';
import 'review_all_clear_screen.dart';
import 'review_next_screen.dart';

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

  /// Verified-products contribution count (community-hub.md §6, CH5). Injected
  /// live from the host via `CommunityReviewController.fetchStats()` (issue
  /// #263). Null means "unknown" → the stat card renders `--` (no fabricated
  /// number); use [isLoading]/[hasError] to drive the loading/error glyphs.
  final int? verifiedCount;

  /// Added-products contribution count (CH5). Injected live from the host
  /// (issue #263). Null → `--` (unknown).
  final int? addedCount;

  /// Live data source for the peer-review queue (issue #54 / CR11). When
  /// provided and [pendingReviews] is null, the screen loads the queue from
  /// the `pending_reviews` table on mount and routes approve/reject decisions
  /// back through it. Left null in tests, which inject [pendingReviews]
  /// directly.
  final CommunityReviewController? reviewController;

  /// Invoked after each successful approve/reject so the host can refresh its
  /// live stat counts (issue #278). [MainContainer] wires this to
  /// `_loadCommunityStats()` — the refresh is silent (no spinner flash), so an
  /// approved review's bump to `אומתו בהצלחה` shows without a full reload.
  final VoidCallback? onReviewCompleted;

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
    this.onReviewCompleted,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late List<PendingReview> _localQueue;

  /// Live [ReviewQueueService] instance for the current review session. Created
  /// lazily when a review session starts with a real [reviewController]. Null
  /// when the host injected [pendingReviews] directly (test / override path —
  /// the in-memory fallback accumulator below is used instead).
  ReviewQueueService? _reviewQueueService;

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
      final reviews = await widget.reviewController!.fetchPending(
        widget.allergens,
      );
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
      widget.onStartReview != null ||
      _localQueue.isNotEmpty ||
      // The live-controller path loads its queue asynchronously after mount;
      // keep the button eligible during that window (the host injects
      // `pendingReviews` only on the test / override path). `widget.isLoading`
      // still suppresses the button during explicit load states.
      (widget.reviewController != null && widget.pendingReviews == null);

  /// Community points awarded per completed review this session (in-memory
  /// fallback path — used when [pendingReviews] is injected directly by a host
  /// or test and no [ReviewQueueService] is active).
  static const int _pointsPerReview = 10;

  // Session accumulators used only on the in-memory fallback path.
  int _sessionReviewed = 0;
  int _sessionPoints = 0;

  // ─── In-memory fallback callbacks ──────────────────────────────────────────

  Future<void> _onApprove(PendingReview review) async {
    // Persist first — if it throws, the review screen keeps the item so the
    // reviewer can retry (it surfaces its own error toast). Only drop it from
    // the local queue on success.
    await widget.reviewController?.approve(review.id, review.productId);
    if (!mounted) return;
    setState(() {
      _localQueue.remove(review);
      _sessionReviewed++;
      _sessionPoints += _pointsPerReview;
    });
    // Persisted approval changed the verified-count source of truth; let the
    // host silently re-fetch its stat cards (issue #278).
    widget.onReviewCompleted?.call();
  }

  Future<void> _onReject(PendingReview review, String reason) async {
    await widget.reviewController?.reject(review.id, reason);
    if (!mounted) return;
    setState(() {
      _localQueue.remove(review);
      _sessionReviewed++;
      _sessionPoints += _pointsPerReview;
    });
    // A reject can shrink the catalog/added count; keep the host's stat cards
    // in sync with the latest Supabase truth (issue #278).
    widget.onReviewCompleted?.call();
  }

  /// Spec review-all-clear §6.4 (in-memory fallback path): replaces the
  /// in-review route with the terminal celebration screen once the queue is
  /// drained, passing the session accumulators as arguments.
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

  // ─── ReviewQueueService path ────────────────────────────────────────────────

  /// Called by [CommunityReviewScreen] after each approve / reject when the
  /// session is driven by [ReviewQueueService]. Routes to [ReviewNextScreen]
  /// if items remain, or [ReviewAllClearScreen] when the queue is exhausted
  /// (spec review-all-clear §6.4 / review-next-item §7.1).
  void _onReviewCompleted({required bool moreRemain}) {
    if (!mounted) return;
    final service = _reviewQueueService;
    if (!moreRemain || service == null || service.currentItem == null) {
      // Queue exhausted → celebration screen.
      final points = service?.sessionPoints ?? _sessionPoints;
      final scanned = service?.sessionReviewed ?? _sessionReviewed;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReviewAllClearScreen(
            totalPointsEarned: points,
            productsScanned: scanned,
          ),
        ),
      );
    } else {
      // More items → success state with a peek at the next product.
      final nextItem = service.currentItem!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReviewNextScreen(
            pointsEarned: service.sessionPoints,
            // No rank-query API is wired yet (#56 follow-up): leave at 0 so the
            // screen renders the "#—" unknown-rank placeholder rather than a
            // fabricated "#0".
            nextItem: _toQueueItem(nextItem),
            onSkip: () {
              if (!mounted) return;
              // Skip advances the cursor without recording a review, then
              // re-enters the routing loop (next item or all-clear).
              final moreRemain = service.skip();
              _onReviewCompleted(moreRemain: moreRemain);
            },
            onCheckNow: () {
              // Proceed to review the next item: push CommunityReviewScreen
              // for just that one item, wired back to this routing callback.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => _buildReviewScreen(service),
                ),
              );
            },
            onGoHome: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              widget.onNavIndexChanged(0);
            },
          ),
        ),
      );
    }
  }

  /// Adapts a [PendingReview] (the review-queue data model) to the
  /// display-only [ReviewQueueItem] contract master's [ReviewNextScreen]
  /// renders (`review-next-item.md §6.2`).
  ReviewQueueItem _toQueueItem(PendingReview review) {
    final hasFlags = review.allergenReports
        .any((r) => r.status != AllergenReportStatus.absent);
    return ReviewQueueItem(
      id: review.id,
      name: review.productName,
      categoryLabel: review.categoryLabel,
      description: review.contributorNote ?? '',
      imageUrl: review.imageUrl ?? '',
      alertLabel: hasFlags ? 'חשד לאלרגנים' : 'אין חשד לאלרגנים',
    );
  }

  /// Builds a [CommunityReviewScreen] wired to the [service]-driven approve /
  /// reject callbacks that route through [_onReviewCompleted].
  Widget _buildReviewScreen(ReviewQueueService service) {
    // Snapshot the items remaining (from currentItem onward) so CommunityReviewScreen
    // can display the queue counter.
    final current = service.currentItem;
    if (current == null) {
      // Shouldn't happen but handle defensively.
      return ReviewAllClearScreen(
        totalPointsEarned: service.sessionPoints,
        productsScanned: service.sessionReviewed,
      );
    }
    return CommunityReviewScreen(
      // The service owns the full queue + cursor; hand the screen just the
      // current item so its "N נותרו" counter reflects the live remaining count.
      queue: service.remainingItems,
      onApprove: (review) async {
        final moreRemain = await service.approve(review);
        if (!mounted) return;
        _onReviewCompleted(moreRemain: moreRemain);
      },
      onReject: (review, reason) async {
        final moreRemain = await service.reject(review, reason);
        if (!mounted) return;
        _onReviewCompleted(moreRemain: moreRemain);
      },
      onQueueExhausted: () => _onReviewCompleted(moreRemain: false),
    );
  }

  void _onStartReview() {
    final override = widget.onStartReview;
    if (override != null) {
      override();
      return;
    }

    // If a live controller is available, use ReviewQueueService (spec §6.4).
    final controller = widget.reviewController;
    if (controller != null && widget.pendingReviews == null) {
      _startReviewWithService(controller);
      return;
    }

    // In-memory fallback: tests or hosts that inject [pendingReviews] directly.
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

  /// Starts a service-backed review session: creates a [ReviewQueueService],
  /// loads the queue from Supabase, then pushes the first [CommunityReviewScreen].
  Future<void> _startReviewWithService(
      CommunityReviewController controller) async {
    final service = ReviewQueueService(
      controller: controller,
      allergens: widget.allergens,
    );
    _reviewQueueService = service;
    try {
      await service.loadQueue();
    } catch (e) {
      debugPrint('review-queue: failed to load queue: $e');
      if (!mounted) return;
      // Load failed → surface the celebration/empty fallback below rather than
      // blocking the reviewer; currentItem stays null so we route to the
      // ReviewAllClearScreen guard.
    }
    if (!mounted) return;
    if (service.currentItem == null) {
      // Queue loaded but is empty → go straight to celebration screen (AC6).
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewAllClearScreen(
            totalPointsEarned: 0,
            productsScanned: 0,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _buildReviewScreen(service),
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הכוח שלנו הוא בידע',
          style: AppTypography.h1.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'עזרו לאחרים לגלוש בביטחה ולגלות מוצרים חדשים.',
          style: AppTypography.bodyMd.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Resolves the digit shown on a stat card.
  ///
  /// Loading wins first (`--`). On error we only fall back to `?` when no value
  /// has ever been fetched ([count] is null); a transient re-fetch failure that
  /// still has the last-known good count keeps that stale value visible rather
  /// than wiping it to `?` (see issue #281).
  String _statValue(int? count) {
    if (widget.isLoading) return '--';
    if (count == null) return widget.hasError ? '?' : '--';
    return count.toString();
  }

  Widget _buildStatsRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              value: _statValue(widget.verifiedCount),
              label: 'אומתו בהצלחה',
              icon: Icons.verified,
              accentColor: context.colors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              value: _statValue(widget.addedCount),
              label: 'מוצרים נוספו',
              icon: Icons.add_circle,
              accentColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorScheme.primary,
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
              errorBuilder: (_, e, s) =>
                  ColoredBox(color: colorScheme.primary),
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
                    colorScheme.primary.withValues(alpha: 0.60),
                    colorScheme.primary,
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
                  style: AppTypography.h2.copyWith(color: colorScheme.onPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'מצאתם מוצר חדש? הוסיפו אותו כדי שכולם יוכלו לדעת אם הוא בטוח.',
                  style: AppTypography.bodyMd.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.90),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: widget.onAddProductTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerLowest,
                    foregroundColor: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final count = _pendingReviews.length;
    if (count == 0) {
      return Text(
        'אין כעת מוצרים לבדיקה',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }
    final unit = count == 1 ? 'מוצר אחד' : '$count מוצרים';
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
        children: [
          const TextSpan(text: 'ישנם '),
          TextSpan(
            text: unit,
            style: AppTypography.bodyMdBold.copyWith(color: colorScheme.primary),
          ),
          const TextSpan(text: ' הממתינים לבדיקה שלך'),
        ],
      ),
    );
  }

  Widget _buildPeerReviewCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.surfaceContainerLow),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.rate_review, color: colorScheme.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'בקרת עמיתים',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          widget.isLoading
              ? const SkeletonBox(width: 180, height: 20)
              : _peerReviewBody(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.isLoading || !_canStartReview
                  ? null
                  : _onStartReview,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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

}

/// Non-blocking error banner shown above the stats when the Supabase fetch
/// fails. Spec ref: `community-hub.md §5.3`.
class _ErrorBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorBanner({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'לא ניתן לטעון נתונים — בדוק חיבור לאינטרנט.',
              style: AppTypography.labelSm.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
              ),
              child: Text(
                'נסה שוב',
                style: AppTypography.labelBold.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
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
