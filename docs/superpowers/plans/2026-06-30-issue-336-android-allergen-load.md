# Plan: Fix Android allergen-list load failure (issue #336)

## Problem / Root cause

On Android the allergen catalog fails to load while products load fine on both
Android and Chrome. The only code-level difference between the two queries is in
`app/lib/services/allergen_service.dart`:

```dart
_client.from('allergens').select().timeout(const Duration(seconds: 10))
```

`ProductService.searchProducts` issues an equivalent `select` with **no**
`.timeout(...)`. The allergens RLS policy (`allergens_public_read for select
using (true)`, `supabase/migrations/20260101000000_initial_schema.sql:79`) is
identical in permissiveness to the products policy, so RLS is **not** the
differentiator.

The differentiator is timing + the hard timeout:

- Allergens are fetched during the app **cold-start storm** in `main.dart`
  (`_AppShellState._loadProfileAndAllergens`), immediately after
  `Supabase.initialize` and the anonymous `ensureSession()` sign-in.
- On Android a cold device network stack (DNS + TLS handshake on first request)
  is materially slower than Chrome reusing the host OS network stack on the same
  machine. The 10s hard timeout fires, throwing `TimeoutException`, which
  `_loadProfileAndAllergens` catches into `loadError` → empty catalog.
- Products are fetched **later**, on a user-initiated search, with no timeout and
  a warm connection — so they always succeed.

This explains every reported symptom: always fails on Android, works on Chrome,
products fine on both.

AC#2 (surface error, no silent empty state) is already satisfied on master:
- Non-onboarded users: `AppShell` shows a full retry error screen.
- Onboarded users: `AllergenManagementScreen` shows the `StateView`
  "לא ניתן לטעון את רשימת האלרגנים" empty/error state (issue #256).

So the fix is scoped to making the fetch resilient (AC#1) and documenting the
root cause (AC#3).

## Fix

Make `AllergenService.fetchAllergens` resilient to transient cold-start slowness:
a bounded retry with linear backoff and a more generous per-attempt timeout,
throwing a descriptive `AllergenLoadException` after the last attempt so the
existing error surfaces (AC#2 paths) still trigger. The retry/parse policy is
extracted into a pure static method so it is unit-testable without a live client
(the repo's services are not mocked against Supabase).

## Tasks

### Task 1 — Rewrite `allergen_service.dart` with testable retry

`app/lib/services/allergen_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';

/// Thrown by [AllergenService.fetchAllergens] when every retry attempt to load
/// the allergen catalog fails. Preserves the last underlying error's string so
/// callers that sniff for network markers (e.g. AppShell's socket/connection
/// check) keep working.
class AllergenLoadException implements Exception {
  const AllergenLoadException(this.cause);

  final Object? cause;

  @override
  String toString() => 'AllergenLoadException: $cause';
}

class AllergenService {
  final SupabaseClient _client;

  AllergenService(this._client);

  /// Per-attempt network timeout. More generous than the original 10s so a slow
  /// Android cold-start TLS handshake does not trip it on the first try.
  static const Duration perAttemptTimeout = Duration(seconds: 15);

  /// Total attempts (1 initial + retries) before giving up.
  static const int maxAttempts = 3;

  /// Base linear backoff between attempts (attempt N waits base * N).
  static const Duration retryBackoff = Duration(milliseconds: 400);

  Future<List<Allergen>> fetchAllergens() {
    return fetchWithRetry(
      () => _client.from('allergens').select().timeout(perAttemptTimeout),
    );
  }

  /// Pure, injectable retry+parse policy. [query] performs one network read;
  /// its result is parsed into [Allergen]s. Retries up to [maxAttempts] on any
  /// error (timeout, transient network), waiting [backoff] * attempt between
  /// tries. Throws [AllergenLoadException] wrapping the last error when all
  /// attempts fail. Extracted as a static so it is testable without a live
  /// Supabase client.
  @visibleForTesting
  static Future<List<Allergen>> fetchWithRetry(
    Future<dynamic> Function() query, {
    int maxAttempts = AllergenService.maxAttempts,
    Duration backoff = AllergenService.retryBackoff,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await query();
        return (response as List)
            .map((json) => Allergen.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(backoff * attempt);
        }
      }
    }
    throw AllergenLoadException(lastError);
  }
}
```

`@visibleForTesting` comes from `package:flutter/foundation.dart` (re-exported by
material); supabase_flutter does not export it, so add the import
`import 'package:flutter/foundation.dart';`.

### Task 2 — Unit tests

Extend `app/test/unit/services/allergen_service_test.dart` with a
`fetchWithRetry` group (use `backoff: Duration.zero` to keep tests fast):

- returns parsed allergens and calls query once on first-try success
- retries and succeeds after two transient failures (query called 3×)
- throws `AllergenLoadException` after exhausting attempts (query called
  `maxAttempts`×), with the last error preserved as `cause`
- a `TimeoutException` is retryable (treated like any other error)

### Task 3 — Verify

From `app/`, one command at a time:
- `flutter pub get`
- `flutter analyze lib test`  → 0 issues
- `flutter test`              → all green

### Task 4 — A6 spec index

Issue #336 is a service/data bug, not a screen build. The affected screens
(`onboarding-allergen-selection` row 16, `allergen-management` row 55) are
already ✓/✓/✓ and their error-state handling is unchanged. Append a short note to
the `allergen-management` Code cell referencing #336 (the load path it depends on
is now retry-resilient). No status-column changes.

### Task 5 — A7 drift check

`git fetch origin` then `git log origin/master..HEAD --oneline` — abort if any
foreign commit appears.

### Task 6 — A8 commit + PR

Commit (footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`), push,
`gh pr create --base master`. PR body: `Closes #336`, root-cause writeup, change
summary, analyze/test results.

### Task 7 — A9 comment + release

Comment on #336 linking the PR; remove the `agent-in-progress` label.
