import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/allergen.dart';
import '../models/pending_review.dart';
import 'community_review_controller.dart';

/// Stateful queue service for a community review session.
///
/// Wraps [CommunityReviewController] with per-session point / scanned
/// accumulators and queue-advance logic, driving the
/// [ReviewNextScreen] → [ReviewAllClearScreen] routing decision
/// (spec: `review-next-item.md §6.4`).
///
/// Not a singleton — instantiated once per review session in
/// [CommunityScreen._onStartReview]. The in-memory queue approach mirrors
/// [CommunityScreen._localQueue] but lives here so the routing decision
/// (more items? → ReviewNextScreen; exhausted? → ReviewAllClearScreen) is
/// business logic, not widget logic.
class ReviewQueueService {
  final CommunityReviewController _controller;
  final List<Allergen> _allergens;

  List<PendingReview> _queue = const [];
  int _cursor = 0;

  /// Community points credited per successfully reviewed item this session.
  static const int _pointsPerReview = 10;

  int _sessionPoints = 0;
  int _sessionReviewed = 0;

  /// Production constructor: backed by [controller] which owns the Supabase
  /// round-trip. [allergens] is the catalog used to hydrate each
  /// [PendingReview]'s allergen names and icons — pass the same list
  /// `AppShell` loads.
  ReviewQueueService({
    required CommunityReviewController controller,
    required List<Allergen> allergens,
  })  : _controller = controller,
        _allergens = allergens;

  /// Test seam: inject a pre-built [queue] so unit tests can exercise the
  /// advance / accumulate logic without a live Supabase connection.
  @visibleForTesting
  ReviewQueueService.withQueue(
    CommunityReviewController controller,
    List<Allergen> allergens,
    List<PendingReview> queue,
  )   : _controller = controller,
        _allergens = allergens,
        _queue = List<PendingReview>.from(queue),
        _cursor = 0;

  // ─── Queue state ────────────────────────────────────────────────────────────

  /// The item currently at the front of the queue. Null when exhausted.
  PendingReview? get currentItem =>
      _cursor < _queue.length ? _queue[_cursor] : null;

  /// Number of items remaining, including [currentItem].
  int get remaining => (_queue.length - _cursor).clamp(0, _queue.length);

  // ─── Session accumulators ───────────────────────────────────────────────────

  /// Cumulative community points earned this session.
  int get sessionPoints => _sessionPoints;

  /// Number of products reviewed (approved or rejected) this session.
  int get sessionReviewed => _sessionReviewed;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  /// Fetches the pending queue from Supabase and resets all session state.
  /// Must be called before the first [currentItem] access in a new session.
  Future<void> loadQueue() async {
    _queue = await _controller.fetchPending(_allergens);
    _cursor = 0;
    _sessionPoints = 0;
    _sessionReviewed = 0;
  }

  // ─── Review actions ─────────────────────────────────────────────────────────

  /// Persists an approval for [review] via the controller, records the session
  /// accumulator increment, and advances the cursor.
  ///
  /// Returns `true` if at least one item remains after advancing (i.e. the
  /// caller should route to [ReviewNextScreen]); returns `false` if the queue
  /// is now exhausted (route to [ReviewAllClearScreen]).
  Future<bool> approve(PendingReview review) async {
    await _controller.approve(review.id);
    _record();
    return _advance();
  }

  /// Persists a rejection with [reason] via the controller, records the
  /// session accumulator increment, and advances the cursor.
  ///
  /// Returns `true` if items remain; `false` if exhausted.
  Future<bool> reject(PendingReview review, String reason) async {
    await _controller.reject(review.id, reason);
    _record();
    return _advance();
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  void _record() {
    _sessionReviewed++;
    _sessionPoints += _pointsPerReview;
  }

  /// Advances the cursor and returns whether more items remain.
  bool _advance() {
    _cursor++;
    return _cursor < _queue.length;
  }
}
