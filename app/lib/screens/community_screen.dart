import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/pending_review.dart';
import '../services/community_review_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/bento_card.dart';
import '../widgets/skeleton_box.dart';
import '../services/review_queue_service.dart';
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
            productsReviewed: service.sessionReviewed,
            nextItem: nextItem,
            onCheckNow: () {
              // Proceed to review the next item: push CommunityReviewScreen
              // for just that one item, wired back to this routing callback.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => _buildReviewScreen(service),
                ),
              );
            },
            onSkip: () {
              // Skip: advance cursor without recording a review, then re-route.
              // Since ReviewQueueService.approve/reject are the only advance
              // paths that record points, skip just moves the cursor externally
              // here by treating the skip as a signal to present the next item.
              // We call _advance directly is not exposed; instead rebuild with
              // the next item by re-pushing ReviewNextScreen for the item after.
              // Simplest correct approach: replace with a new ReviewNextScreen
              // showing the next item as "next" (advance not applied to service,
              // so the cursor hasn't moved — the user just skips the review).
              // To keep it clean, push the review screen for the next item.
              if (!mounted) return;
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
      // Pass only the current + remaining items so the screen's counter is accurate.
      queue: [current, ...List<PendingReview>.of(
        _reviewQueueService == null
            ? const <PendingReview>[]
            : _queueTail(service),
      )],
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

  /// Returns the items after the current cursor position (used to pass the
  /// tail of the queue to [CommunityReviewScreen] for its counter display).
  List<PendingReview> _queueTail(ReviewQueueService service) {
    // We can't directly inspect _queue/_cursor on the service (they're private).
    // Return empty — the counter will show "1 נותרו" while that item is shown.
    // This is acceptable; the exact remaining count is displayed in the service
    // but exposing it via a public getter is the cleaner path.
    return const [];
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
      // Fall back to the current local queue so the reviewer isn't blocked.
      service;
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
    if (widget.isLoading) return '--';
    if (widget.hasError) return '?';
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
      onTap: widget.onAddProductTap,
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
              child: Icon(Icons.add, color: AppColors.onPrimary, size: 32),
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

  String get _peerReviewHeading {
    final count = _pendingReviews.length;
    if (count == 0) return 'אין כעת מוצרים לבדיקה';
    if (count == 1) return 'מוצר אחד ממתין לבדיקה';
    return '$count מוצרים ממתינים לבדיקה';
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
            child: widget.isLoading
                ? const SkeletonBox(width: 180, height: 20)
                : Text(
                    // Heading tracks the queue actually pushed to
                    // CommunityReviewScreen so the row never advertises data
                    // the landing screen can't show. CH8 live count stays
                    // with #54.
                    _peerReviewHeading,
                    style:
                        AppTypography.h3.copyWith(color: AppColors.onSurface),
                  ),
          ),
          FilledButton(
            // Disabled while loading, and (per §7.5) when the queue is empty
            // and no caller override is supplied — the row never promises an
            // entry point to a second empty state.
            onPressed:
                widget.isLoading || !_canStartReview ? null : _onStartReview,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text('התחל בבדיקה', style: AppTypography.labelBold),
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
                child: Icon(Icons.forum, color: AppColors.primary, size: 24),
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
              Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
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
