# Implementation Plan: issue #174 — model anonymous vs authenticated session state

**Branch:** `agent/issue-174-anon-session-state` (already created — execution starts at Task 1)
**Issue:** https://github.com/Maortz/allergy-detector/issues/174
**Area:** feat(auth) — Dart only, single file + its test (`app/lib/services/auth_service.dart`).

## Goal

Add an `anonymous` value to `AuthSessionState` so anonymous sign-ins are distinguishable from
fully-upgraded accounts, sourced from `currentUser?.isAnonymous`. No behaviour change at MVP
scale — existing logic that only cares about "have a session vs not" treats `anonymous` and
`authenticated` the same.

## Critical context (read before editing)

- `AuthSessionState` lives in `app/lib/services/auth_service.dart:8`. Current values:
  `{ authenticated, signedOut }`.
- The pure mapping `static AuthSessionState authSessionStateFor(AuthState state)` (line 88) is the
  single place that derives the enum; `sessionState` stream (line 58) maps `onAuthStateChange`
  through it. These are the only producers.
- **Only caller** of the enum / mapper is the file itself + its unit test
  `app/test/unit/services/auth_service_test.dart`. No screen consumes `sessionState`. So extending
  the enum churns nothing outside these two files (verified via repo-wide grep).
- `gotrue` `User.isAnonymous` is a real `bool` field (default `false`), const-constructable
  (`gotrue-2.20.0/lib/src/types/user.dart:29,53`). `AuthState.session?.user?.isAnonymous` is the
  source signal. It flips to `false` when a guest upgrades in place (same id).
- The existing test "an anonymous-sign-in session still counts as authenticated" actually builds a
  `User` with **no** `isAnonymous` (defaults to `false`) — i.e. a *non-anonymous* session. Its name
  is now misleading. The plan updates this test to genuinely exercise both branches: a real
  anonymous user (`isAnonymous: true`) → `anonymous`, and a non-anonymous session → `authenticated`.

## Design

- `enum AuthSessionState { authenticated, anonymous, signedOut }`.
- `authSessionStateFor`: null session → `signedOut`; session present + `user?.isAnonymous == true`
  → `anonymous`; otherwise → `authenticated`.
- Keep the mapper pure/static (unit-testable without a live client), matching the existing pattern.
- Document on the enum that callers caring only about "logged in vs not" should treat `anonymous`
  the same as `authenticated` (MVP guidance the issue asks for).

## Tasks

### Task 1 — TDD: extend the test first (red)

Edit `app/test/unit/services/auth_service_test.dart`:

1. Change the `_session()` stub helper to accept an `isAnonymous` flag so tests can build both
   kinds of session. Replace the helper with:

```dart
/// Minimal session stub. `authSessionStateFor` inspects whether
/// `AuthState.session` is null and the user's `isAnonymous` flag, so those are
/// the only fields that matter here.
Session _session({bool isAnonymous = false}) => Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: isAnonymous,
      ),
    );
```

(Note: `User` is no longer `const` here because `isAnonymous` is now a variable; keep the inner
maps `const`.)

2. Replace the misnamed "an anonymous-sign-in session still counts as authenticated" test with two
   precise tests:

```dart
    test('maps a non-anonymous session to authenticated', () {
      final state = AuthState(AuthChangeEvent.signedIn, _session());
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.authenticated,
      );
    });

    test('maps an anonymous session to anonymous', () {
      final state = AuthState(
        AuthChangeEvent.initialSession,
        _session(isAnonymous: true),
      );
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.anonymous,
      );
    });
```

Keep the existing "maps a state carrying a session to authenticated", "maps a session-less state to
signedOut", and "a null session on initialSession … is signedOut" tests unchanged (the first now
also covers the non-anonymous path; that's fine).

Run `flutter test test/unit/services/auth_service_test.dart` — the new `anonymous` test fails to
compile/assert (enum value doesn't exist yet). That's the expected red.

### Task 2 — Extend the enum + mapper (green)

Edit `app/lib/services/auth_service.dart`:

1. Extend the enum (line 8) and document the MVP guidance:

```dart
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
```

2. Update the mapper (line 88) to read `isAnonymous`:

```dart
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
```

Leave the `sessionState` stream getter (line 58) unchanged — it already maps through
`authSessionStateFor`, so it now emits `anonymous` automatically.

### Task 3 — Verify

Run from `app/`, one command at a time (no `&&`), flutter on PATH (`export PATH="$PATH:/sdks/flutter/bin"`):

1. `flutter pub get` — succeeds.
2. `flutter analyze lib test` — 0 issues **for the changed files**. Note: master currently has 2
   pre-existing `lib/main.dart` errors (`Supabase.initialize` `publishableKey`/`anonKey` arg
   mismatch from the resolved supabase_flutter version) unrelated to this change — do not touch
   `main.dart`. Confirm no *new* issues appear beyond those two pre-existing ones.
3. `flutter test` — all green (was 423 passing on master; the net test count changes by the
   replaced/added cases).

### Task 4 — A6 spec-table update — N/A

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` tracks **screen** implementations. This
is a service-layer change touching no screen — skip A6 explicitly.

### Task 5 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```
Only this branch's commit(s) should appear. Foreign commits → STOP.

### Task 6 — A8 commit + PR

```
git add app/lib/services/auth_service.dart app/test/unit/services/auth_service_test.dart docs/superpowers/plans/2026-06-14-issue-174-anon-session-state.md
git commit -m "<message>"
```

Commit message:

```
feat(auth): split anonymous from authenticated session state (#174)

Add an `anonymous` value to AuthSessionState, derived from
currentUser.isAnonymous, so the upcoming auth UI can tell a guest from a
fully-upgraded account. authSessionStateFor maps an anonymous session to
the new value; non-anonymous live sessions stay authenticated and no
session stays signedOut. No behaviour change at MVP scale — callers that
only care about "logged in vs not" treat anonymous as authenticated.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push and open the PR:

```
git push -u origin agent/issue-174-anon-session-state
gh pr create --repo Maortz/allergy-detector --base master --title "feat(auth): model anonymous vs authenticated session state distinction (#174)" --body "<body>"
```

PR body: `Closes #174`, change summary, note that the only consumer is the unit test (no screen
churn), the pre-existing `main.dart` analyze caveat, and `flutter analyze`/`flutter test` results.

### Task 7 — A9 comment + release claim

```
gh issue comment 174 --repo Maortz/allergy-detector --body "Opened PR <url> — <one-line summary>."
gh issue edit 174 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
