import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allergen.dart';
import '../models/pending_review.dart';
import 'auth_service.dart';

/// Backs [CommunityReviewScreen] with the Supabase `pending_reviews` table
/// (issue #54 / CR11). Fetches the pending review queue and routes the
/// reviewer's approve / reject decisions back to the table.
///
/// Not a singleton — instantiated inline in screens with an injected
/// [SupabaseClient], matching the other services in `lib/services/`.
class CommunityReviewController {
  final SupabaseClient _client;
  final AuthService _authService;

  /// Production constructor: builds the [AuthService] pre-flight from the same
  /// [client] used for the REST calls, so [MainContainer] keeps constructing
  /// `CommunityReviewController(Supabase.instance.client)` unchanged.
  CommunityReviewController(SupabaseClient client)
      : _client = client,
        _authService = AuthService(client);

  /// Test seam: inject a fake [AuthService] so unit tests can exercise the
  /// pre-flight without a live anonymous sign-in (issue #175).
  @visibleForTesting
  CommunityReviewController.withAuth(this._client, this._authService);

  /// Fetches every `pending` review oldest-first, hydrated with its product /
  /// brand fields and allergen breakdown.
  ///
  /// [allergens] is the catalog used to resolve each report's `allergen_id`
  /// into a full [Allergen] (the screen renders names + icons). Pass the same
  /// catalog `AppShell` already loads.
  Future<List<PendingReview>> fetchPending(List<Allergen> allergens) async {
    final rows = await _client
        .from('pending_reviews')
        .select(
          'id, product_id, contributor_note, allergen_reports, '
          'products(name_he, category, image_url, brands(name_he))',
        )
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    final allergensById = {for (final a in allergens) a.id: a};
    return rows
        .map((row) =>
            PendingReview.fromJson(row, allergensById: allergensById))
        .toList(growable: false);
  }

  /// Live community counters for the hub stat cards (issue #263):
  /// - `verified`: number of peer-reviews approved
  ///   (`pending_reviews.status = 'approved'`).
  /// - `added`: total products in the catalog — the MVP "products added" metric
  ///   (no per-user attribution until auth lands).
  ///
  /// Uses PostgREST exact-count HEAD requests (`count(CountOption.exact)`) rather
  /// than fetching rows and counting client-side: a row-fetch silently caps at
  /// PostgREST's default 1000-row ceiling, undercounting once either table grows,
  /// and also wastes bandwidth pulling ids we never read.
  Future<({int verified, int added})> fetchStats() async {
    // The two reads are independent — run them concurrently to halve the
    // round-trip latency on every Community tab open.
    final (verified, added) = await (
      _client
          .from('pending_reviews')
          .count(CountOption.exact)
          .eq('status', 'approved'),
      _client.from('products').count(CountOption.exact),
    ).wait;
    return (verified: verified, added: added);
  }

  /// Marks [reviewId] approved and flips the linked [productId] to
  /// `verified = true` (issue #263; MVP threshold = a single approval).
  ///
  /// Pre-flights [AuthService.ensureSession] (issue #175): if the startup
  /// bootstrap silently failed offline, this re-attempts it at the point of
  /// need so the RLS-scoped write has a live `auth.uid()`. A no-op when a
  /// session already exists; rethrows if the session still can't be
  /// established (the caller surfaces its own error + keeps the item for retry).
  Future<void> approve(String reviewId, String productId) async {
    await _authService.ensureSession();
    await _client.from('pending_reviews').update({
      'status': 'approved',
      'rejection_reason': null,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reviewId);
    // The two writes can't share a client-side transaction. If the review row
    // is now `approved` but this PATCH throws, the product is left unverified —
    // a recoverable partial state. Log it structured so it's observable in logs
    // (and retryable by a background job) before rethrowing so the caller still
    // surfaces the error and keeps the item for retry.
    try {
      await _client
          .from('products')
          .update({'verified': true}).eq('id', productId);
    } catch (e) {
      debugPrint(
          'products.verified PATCH failed for $productId after review '
          '$reviewId was approved: $e');
      rethrow;
    }
  }

  /// Marks [reviewId] rejected with the reviewer's [reason] (required, non-empty
  /// — the screen gates submission on it).
  ///
  /// Pre-flights [AuthService.ensureSession] before the write, mirroring
  /// [approve] (issue #175).
  Future<void> reject(String reviewId, String reason) async {
    await _authService.ensureSession();
    await _client.from('pending_reviews').update({
      'status': 'rejected',
      'rejection_reason': reason,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reviewId);
  }
}
