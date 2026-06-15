import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_contribution.dart';

/// Reads the current user's own `pending_reviews` rows (issue #185), hydrated
/// with the product/brand each row targets.
///
/// Backs both `MyReviewsScreen` (the free-text reviews view) and
/// `ContributionHistoryScreen` (the submitted-products view) — both surface the
/// same `pending_reviews` rows the user contributed, scoped by
/// `contributor_id = auth.uid()`.
///
/// Not a singleton — instantiated inline in screens with an injected
/// [SupabaseClient], matching the other services in `lib/services/`.
class MyReviewsService {
  final SupabaseClient _client;

  MyReviewsService(this._client);

  /// Columns shared by both views: the row's status/note/date plus the joined
  /// product identity and brand name.
  static const String _columns =
      'id, contributor_note, status, created_at, '
      'products(name_he, image_url, brands(name_he))';

  /// The current session's user id, used to scope rows to the caller. `null`
  /// before [AuthService.ensureSession] resolves (no session yet).
  String? get _contributorId => _client.auth.currentUser?.id;

  /// Fetches the user's reviews newest-first.
  ///
  /// Returns an empty list when there is no session yet (nothing to scope to),
  /// so callers render the empty state rather than every contributor's rows.
  Future<List<MyReview>> fetchMyReviews() async {
    final rows = await _fetchRows();
    return rows
        .map(MyReview.fromJson)
        .toList(growable: false);
  }

  /// Fetches the user's submitted products newest-first.
  Future<List<ProductContribution>> fetchContributions() async {
    final rows = await _fetchRows();
    return rows
        .map(ProductContribution.fromJson)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchRows() async {
    final contributorId = _contributorId;
    if (contributorId == null) return const [];

    final rows = await _client
        .from('pending_reviews')
        .select(_columns)
        .eq('contributor_id', contributorId)
        .order('created_at', ascending: false);

    return rows.cast<Map<String, dynamic>>();
  }
}
