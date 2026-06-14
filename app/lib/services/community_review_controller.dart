import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allergen.dart';
import '../models/pending_review.dart';

/// Backs [CommunityReviewScreen] with the Supabase `pending_reviews` table
/// (issue #54 / CR11). Fetches the pending review queue and routes the
/// reviewer's approve / reject decisions back to the table.
///
/// Not a singleton — instantiated inline in screens with an injected
/// [SupabaseClient], matching the other services in `lib/services/`.
class CommunityReviewController {
  final SupabaseClient _client;

  CommunityReviewController(this._client);

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

  /// Marks [reviewId] approved.
  Future<void> approve(String reviewId) async {
    await _client.from('pending_reviews').update({
      'status': 'approved',
      'rejection_reason': null,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reviewId);
  }

  /// Marks [reviewId] rejected with the reviewer's [reason] (required, non-empty
  /// — the screen gates submission on it).
  Future<void> reject(String reviewId, String reason) async {
    await _client.from('pending_reviews').update({
      'status': 'rejected',
      'rejection_reason': reason,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reviewId);
  }
}
