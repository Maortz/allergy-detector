import 'package:supabase_flutter/supabase_flutter.dart';

/// Coarse auth state the app reasons about. The MVP has no login UI, so the
/// only states that matter are "we have a session" vs "we don't (yet)".
///
/// [signedOut] is also the transient pre-bootstrap state before
/// [AuthService.ensureSession] has run.
enum AuthSessionState { authenticated, signedOut }

/// Backend foundation for Supabase auth (issue #79) — **session + RLS only, no
/// auth UI**.
///
/// The MVP keeps working without a logged-in user by bootstrapping an anonymous
/// Supabase session on startup ([ensureSession]). That gives every install a
/// stable `auth.uid()` so the RLS-protected `profiles` / `favorites` / `reviews`
/// tables (see `supabase/schema.sql`) are writable without forcing a login.
///
/// ## Migration path from the SharedPreferences-only profile
/// Today the user profile (selected allergens, display name, filter level,
/// onboarding flag) lives only in SharedPreferences (`AppShell`). This service
/// is the seam to move it server-side incrementally, with **no breaking step**:
///   1. (this issue) Stand up the session + `profiles` table + RLS. The local
///      profile remains the source of truth; nothing reads from `profiles` yet.
///   2. (follow-up) On first run with a session, upsert the local profile into
///      `profiles` keyed on [currentUserId], then read-through on later runs —
///      SharedPreferences becomes an offline cache.
///   3. (follow-up, needs UI) Offer email/OTP upgrade. Because Supabase upgrades
///      an anonymous user **in place** (same `auth.users.id`), every row written
///      while anonymous survives the upgrade with no data migration.
/// `is_admin` also moves here (server-trusted), replacing the client-mutable
/// SharedPreferences flag flagged in `models/user_profile.dart`.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  /// In-flight [ensureSession] call, memoized so concurrent callers during
  /// startup share a single anonymous sign-in instead of each firing their own
  /// (which would trigger duplicate auth-state transitions). Cleared once the
  /// request settles so a later call can retry if it failed.
  Future<User?>? _ensureSessionInFlight;

  GoTrueClient get _auth => _client.auth;

  /// The signed-in user, or null before [ensureSession] resolves / if auth is
  /// unavailable.
  User? get currentUser => _auth.currentUser;

  /// Stable id for the current session's user, used to scope user-owned rows.
  String? get currentUserId => _auth.currentUser?.id;

  /// True once a (anonymous or real) session exists.
  bool get isAuthenticated => _auth.currentSession != null;

  /// Broadcasts a coarse [AuthSessionState] on every auth change. Backed by the
  /// gotrue `BehaviorSubject`, so a new listener immediately gets the current
  /// state.
  Stream<AuthSessionState> get sessionState =>
      _auth.onAuthStateChange.map(authSessionStateFor);

  /// Idempotently guarantees a session exists, signing in anonymously if not.
  ///
  /// Safe to call unconditionally on startup: if a session is already restored
  /// from local storage this is a no-op. Returns the resulting user, or null if
  /// anonymous sign-in failed (e.g. the provider is disabled or the device is
  /// offline) — callers must treat a null session as the no-auth MVP path and
  /// keep working, never block the UI on it.
  ///
  /// Concurrent calls during startup share a single in-flight sign-in: the first
  /// caller starts it, the rest await the same future, avoiding duplicate
  /// anonymous sign-in attempts. The memoized future is cleared once it settles,
  /// so a later call can retry after a failure.
  Future<User?> ensureSession() {
    final existing = _auth.currentSession;
    if (existing != null) return Future.value(existing.user);

    return _ensureSessionInFlight ??= _signInAnonymously()
        .whenComplete(() => _ensureSessionInFlight = null);
  }

  Future<User?> _signInAnonymously() async {
    final response = await _auth.signInAnonymously();
    return response.user;
  }

  /// Pure mapping from a gotrue [AuthState] to the app's coarse state. Extracted
  /// so the session→UI-state logic is unit-testable without a live client.
  static AuthSessionState authSessionStateFor(AuthState state) {
    return state.session != null
        ? AuthSessionState.authenticated
        : AuthSessionState.signedOut;
  }
}
