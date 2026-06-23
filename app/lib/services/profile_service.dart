import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the server-trusted user profile claims that the client must not be
/// allowed to forge — currently just `is_admin` (issue #47).
///
/// `is_admin` lives in the `profiles` table (`supabase/schema.sql`), is RLS-
/// scoped so a client can only read its own row, and is frozen against client
/// self-escalation by the `guard_profiles_is_admin` trigger. This service is
/// the read path: the app sources the admin gate from here on session load
/// instead of the old client-mutable `is_admin` SharedPreferences flag.
///
/// Not a singleton — instantiated inline with an injected [SupabaseClient],
/// matching the other services in `app/lib/services/`.
class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  /// Reads `profiles.is_admin` for the current session user. Returns `false`
  /// when there is no session, no profile row, or the read fails — admin is a
  /// privilege that must default closed, never open, on any uncertainty.
  ///
  /// RLS restricts the select to `auth.uid() = id`, so this can only ever read
  /// the caller's own row.
  Future<bool> fetchIsAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final row = await _client
        .from('profiles')
        .select('is_admin')
        .eq('id', userId)
        .maybeSingle();

    return parseIsAdmin(row);
  }

  /// Pure extraction of the admin flag from a `profiles` [row]. Static + pure
  /// so the default-closed contract is unit-testable without a live client.
  /// Anything other than a literal `true` bool — null row, missing key, or a
  /// non-bool value — resolves to `false`.
  static bool parseIsAdmin(Map<String, dynamic>? row) {
    return row?['is_admin'] == true;
  }
}
