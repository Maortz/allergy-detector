import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown by [AuthService.ensureSession] when anonymous sign-in completes
/// without an error but yields no user (e.g. anonymous sign-ins are disabled
/// server-side, so the provider returns an empty `AuthResponse` instead of
/// throwing). Collapses the old ambiguous "returns null OR throws" contract
/// into a single failure path so callers only handle the thrown case.
class AuthSessionException implements Exception {
  const AuthSessionException(this.message);

  final String message;

  @override
  String toString() => 'AuthSessionException: $message';
}

/// Coarse auth state the app reasons about. The MVP has no login UI, so the
/// only states that matter are "we have a session" vs "we don't (yet)" — but
/// [anonymous] is split out from [authenticated] now (issue #174) so the auth
/// UI to come (login / signup / upgrade-account prompts) can distinguish a
/// guest from a fully-upgraded account without churning callers later.
///
/// Callers that only care about "logged in vs not" should treat [anonymous]
/// the same as [authenticated]; both carry a live session.
///
/// [signedOut] is also the transient pre-bootstrap state before
/// [AuthService.ensureSession] has run.
enum AuthSessionState { authenticated, anonymous, signedOut }

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
  /// from local storage this is a no-op that resolves to the existing user.
  ///
  /// On a fresh sign-in it resolves to the new (anonymous) user, or **throws**:
  /// a gotrue error when the provider/network fails, or [AuthSessionException]
  /// when sign-in completes but returns no user (e.g. anonymous sign-ins are
  /// disabled server-side). It never signals failure by returning null — that
  /// old ambiguity is gone, so callers handle exactly one failure path: the
  /// thrown case. Startup callers must keep working when it throws (the no-auth
  /// MVP path reads/writes only local storage) and never block the UI on it.
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

  Future<User> _signInAnonymously() async {
    final response = await _auth.signInAnonymously();
    return requireUser(response);
  }

  /// Pure extraction of the user from an anonymous-sign-in [response], throwing
  /// [AuthSessionException] when the provider returned no user. Static + pure so
  /// the null-user contract is unit-testable without a live Supabase client.
  static User requireUser(AuthResponse response) {
    final user = response.user;
    if (user == null) {
      throw const AuthSessionException(
        'anonymous sign-in returned no user (provider disabled?)',
      );
    }
    return user;
  }

  /// Pure mapping from a gotrue [AuthState] to the app's coarse state. Extracted
  /// so the session→UI-state logic is unit-testable without a live client.
  ///
  /// A session whose user is anonymous maps to [AuthSessionState.anonymous]; any
  /// other live session maps to [authenticated]; no session maps to [signedOut].
  static AuthSessionState authSessionStateFor(AuthState state) {
    final session = state.session;
    if (session == null) return AuthSessionState.signedOut;
    return session.user.isAnonymous
        ? AuthSessionState.anonymous
        : AuthSessionState.authenticated;
  }
}
