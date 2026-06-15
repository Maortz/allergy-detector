# Implementation Plan: issue #164 — clarify ensureSession() error contract

**Branch:** `agent/issue-164-ensure-session-contract` (already created — execution starts at Task 1)
**Issue:** https://github.com/Maortz/allergy-detector/issues/164
**Area:** fix(auth) — Dart only. Touches `app/lib/services/auth_service.dart`,
`app/lib/main.dart` (comment/log only), and `app/test/unit/services/auth_service_test.dart`.

## Goal

`AuthService.ensureSession()` currently has two distinct failure modes:

1. `signInAnonymously()` **throws** (network / provider error) → caught by the
   `try/catch` in `main.dart`, logged.
2. `signInAnonymously()` **returns** `AuthResponse(user: null)` → `ensureSession()`
   returns `null` silently; the catch block never fires, nothing is logged.

Unify these into a **single failure path** (Option 1 from the issue): when anonymous
sign-in completes but yields a null user, throw a specific, typed exception
(`AuthSessionException`). After this change, every bootstrap failure surfaces through
the existing `catch` in `main.dart`, so callers handle exactly one failure mode and the
silent null-user gap is logged.

This is pre-emptive correctness hardening (the issue notes there is no *active* bug
because the only current caller — `main.dart` — discards the return value). No behaviour
change in the happy path.

## Critical context (read before editing)

- `app/lib/services/auth_service.dart`:
  - `Future<User?> ensureSession()` (line 79): returns `Future.value(existing.user)`
    when a session already exists; otherwise memoizes `_signInAnonymously()` in
    `_ensureSessionInFlight` and clears it on completion (line 83-84).
  - `Future<User?> _signInAnonymously()` (line 87): `final response = await
    _auth.signInAnonymously(); return response.user;` — this is where a null user
    currently leaks out.
- **Only caller** of `ensureSession()` is `app/lib/main.dart:26`, inside a
  `try/catch` that `debugPrint`s on failure (line 25-29). `my_reviews_service.dart`
  only *mentions* it in a doc comment (line 27) — it does not call it. Verified via
  repo-wide grep (`ensureSession` appears only in `auth_service.dart`, `main.dart`
  doc/usage, and one doc comment).
- `gotrue` `AuthResponse` (`auth_response.dart`) is a plain class:
  `AuthResponse({Session? session, User? user})` with `user = user ?? session?.user`.
  It is freely constructible in tests — no client mock needed.
- **No mockito mocks exist for `SupabaseClient`/`GoTrueClient`** in the test suite
  (no `*.mocks.dart`, no `@GenerateMocks`). Mocking the live client is out of scope and
  brittle. Therefore the testable seam is a **pure static helper** that decides
  user-or-throw from an `AuthResponse`, mirroring the existing pure-static
  `authSessionStateFor` pattern already in this file. The helper is what the unit tests
  exercise.
- Baseline on this branch: `flutter analyze lib test` → **0 issues**;
  `flutter test` → all green. (The stale `main.dart` analyze caveat in the #174 plan no
  longer applies — `main.dart` analyzes clean now.)

## Design

1. New typed exception at top of `auth_service.dart`:

```dart
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
```

2. Pure static helper that converts an `AuthResponse` into a non-null user or throws —
   unit-testable without a live client, matching `authSessionStateFor`:

```dart
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
```

3. `_signInAnonymously()` returns a non-null `User` and routes through the helper:

```dart
  Future<User> _signInAnonymously() async {
    final response = await _auth.signInAnonymously();
    return requireUser(response);
  }
```

4. `ensureSession()` return type **stays `Future<User?>`** (the early "session already
   exists" branch returns `existing.user`, which gotrue types as `User?`). Its doc is
   rewritten so the contract is explicit: returns a non-null user on success **or
   throws** `AuthSessionException` / a gotrue error on failure — it no longer signals
   failure by returning null. The `_ensureSessionInFlight` field type stays
   `Future<User?>?` to match `ensureSession()`'s signature; `_signInAnonymously()` now
   returns `Future<User>` which is assignable to it.

5. `main.dart`: no logic change — the existing `try/catch` already catches and logs.
   Update the comment + log string to reflect that a null-user provider response now
   also lands here (so the silent gap the issue describes is gone). Keep it best-effort:
   startup must not block on auth.

## Tasks

### Task 1 — TDD: write the helper tests first (red)

Edit `app/test/unit/services/auth_service_test.dart`.

Add `package:flutter_test`/`supabase_flutter` are already imported. Add a new group after
the existing `authSessionStateFor` group, inside `main()`:

```dart
  group('AuthService.requireUser', () {
    test('returns the user when the response carries one', () {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: true,
      );
      final response = AuthResponse(user: user);

      expect(AuthService.requireUser(response).id, 'user-1');
    });

    test('throws AuthSessionException when the response has no user', () {
      final response = AuthResponse();

      expect(
        () => AuthService.requireUser(response),
        throwsA(isA<AuthSessionException>()),
      );
    });
  });
```

Run `flutter test test/unit/services/auth_service_test.dart` — fails to compile
(`requireUser` / `AuthSessionException` don't exist yet). Expected red.

### Task 2 — Implement exception + helper + wiring (green)

Edit `app/lib/services/auth_service.dart`:

1. Add the `AuthSessionException` class (see Design §1) directly above the
   `enum AuthSessionState` declaration (keep imports unchanged — `User`/`AuthResponse`
   come from the existing `supabase_flutter` import).

2. Rewrite the `ensureSession()` doc comment (lines 67-78) so the contract is explicit:

```dart
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
```

   Leave the `ensureSession()` body unchanged (still returns `Future<User?>` because the
   early branch yields `existing.user`).

3. Replace `_signInAnonymously()` (lines 87-90) with the helper-routed version and add
   the static `requireUser` helper (see Design §2 and §3):

```dart
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
```

Run `flutter test test/unit/services/auth_service_test.dart` — now green.

### Task 3 — Update the main.dart comment + log (no logic change)

Edit `app/lib/main.dart` (lines 21-29). Replace the comment + catch log so it reflects
that a null-user provider response now also throws and lands here:

```dart
  // Bootstrap an anonymous session (issue #79) so every install has a stable
  // auth.uid() for the RLS-protected user tables. Best-effort: any failure —
  // a thrown gotrue/network error OR an AuthSessionException when the provider
  // returns no user (issue #164) — must NOT block startup. The app still runs
  // in the no-auth MVP path, which reads/writes only local storage.
  try {
    await AuthService(Supabase.instance.client).ensureSession();
  } catch (e, st) {
    debugPrint('Anonymous session bootstrap failed; continuing no-auth: $e\n$st');
  }
```

(`ensureSession()`'s return value is still discarded — `await`ed for its side effect.
No new import needed; `AuthSessionException` is caught polymorphically as `Object`.)

### Task 4 — Verify

Run from `app/`, one command at a time (no `&&`), flutter on PATH
(`export PATH="$PATH:/sdks/flutter/bin"`):

1. `flutter pub get` — succeeds.
2. `flutter analyze lib test` — **0 issues** (baseline was 0; this change must not add any).
3. `flutter test` — all green (baseline green + 2 new `requireUser` cases).

### Task 5 — A6 spec-table update — N/A

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` tracks **screen**
implementations. This is a service-layer correctness fix touching no screen and changing
no screen's Code/V-Spec/V-Art status — skip A6 explicitly.

### Task 6 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Only this branch's commit(s) should appear. Foreign commits → STOP.

### Task 7 — A8 commit + PR

```
git add app/lib/services/auth_service.dart app/lib/main.dart app/test/unit/services/auth_service_test.dart docs/superpowers/plans/2026-06-15-issue-164-ensure-session-contract.md
git commit -m "<message>"
```

Commit message:

```
fix(auth): throw AuthSessionException on null-user sign-in (#164)

ensureSession() had an ambiguous contract: it could throw (network /
provider error) OR return null (signInAnonymously returned a null user),
and the null-user path fell through main.dart's try/catch silently with
no log. Collapse both failure modes into one: a new typed
AuthSessionException is thrown when anonymous sign-in completes without a
user, so every bootstrap failure surfaces through the existing catch and
is logged. A pure static requireUser(AuthResponse) helper makes the
null-user contract unit-testable without mocking the Supabase client.
No happy-path behaviour change.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push and open the PR:

```
git push -u origin agent/issue-164-ensure-session-contract
gh pr create --repo Maortz/allergy-detector --base master --title "fix(auth): clarify ensureSession() error contract — distinguish null-user from exception (#164)" --body "<body>"
```

PR body: `Closes #164`, the problem (silent null-user fallthrough), the fix (typed
`AuthSessionException` + pure `requireUser` helper unifying the failure path), note that
the only consumer is `main.dart` (return value discarded, so no behaviour change) plus
the new unit tests, and `flutter analyze`/`flutter test` results.

### Task 8 — A9 comment + release claim

```
gh issue comment 164 --repo Maortz/allergy-detector --body "Opened PR <url> — <one-line summary>."
gh issue edit 164 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
