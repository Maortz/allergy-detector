# Plan — Issue #263: Live Community stats + persist approval-driven product verification

## Context / current state (verified by reading the code)

- `app/lib/screens/community_screen.dart` renders two `StatCard`s with hardcoded
  fallbacks: `value: _statValue('${widget.verifiedCount ?? 5}')` and
  `'${widget.addedCount ?? 2}'` (lines ~271/280). `_statValue` already maps
  `widget.isLoading → '--'` and `widget.hasError → '?'`, so loading/error states
  are already wired at the widget level — the host just never supplies real
  counts or drives `isLoading`/`hasError` for the Community tab.
- `app/lib/screens/main_container.dart` builds `CommunityScreen(...)` (~line 480)
  with **no** `verifiedCount`/`addedCount`/`isLoading`/`hasError`.
- `app/lib/services/community_review_controller.dart` **already persists**
  approve/reject decisions to `pending_reviews` (`status='approved'|'rejected'`,
  `reviewed_at`). So issue AC#4 ("decision written back to pending_reviews") is
  **already satisfied** — no change needed there beyond the new verification step.
- `supabase/schema.sql`: `products` has **no `verified` column**; its RLS is
  read-only (`products_public_read` select policy, no update policy).
  `pending_reviews` has `status` enum + an open update policy.

## Scope of this change (the remaining work)

1. **Schema** (`supabase/schema.sql`): add `products.verified boolean not null
   default false` + an open `products` update policy (MVP, anon role — mirrors the
   existing open `pending_reviews` policies, with a comment to tighten under auth).
2. **Controller** (`community_review_controller.dart`):
   - `fetchStats()` → returns `({int verified, int added})` from Supabase:
     `verified` = count of `pending_reviews` rows with `status='approved'`;
     `added` = count of rows in `products` (community catalog size — the simplest
     well-defined "products added" metric for MVP, matching the issue's "count of
     products added by community members" with no per-user attribution in MVP).
   - On `approve()`, after flipping the review to `approved`, set the linked
     product's `verified=true` (threshold = 1 approval, per the issue's MVP
     suggestion). Needs the review's `product_id`, so `approve` takes it as a
     param.
3. **CommunityScreen** (`community_screen.dart`): remove `?? 5` / `?? 2`; render
   the injected counts directly through `_statValue` (which already shows `--`
   loading / `?` error / number otherwise). When a count is null and not
   loading/error, show `--` (no fabricated number).
4. **MainContainer** (`main_container.dart`): load stats via the controller on
   mount (and after each approve/reject round-trip is not required for MVP — load
   on mount + on tab-construction is enough; re-fetch after the review queue
   drains is out of scope), pass `verifiedCount`/`addedCount` + `isLoading`/
   `hasError` into `CommunityScreen`.

Out of scope (per issue): per-user vote attribution; multi-vote thresholds.

Staff-level notes: business logic stays in the controller/service, not the
widget; `const` where possible; no hardcoded colors; Hebrew RTL untouched;
nullable counts mean "unknown" → `--`, never a fake number.

Branch `agent/issue-263-community-live-stats` already created (A3 done).

---

## Task 1 — Schema: products.verified column + update policy

File: `supabase/schema.sql`.

In the `create table products (...)` block, add the column after `is_archived`:
```sql
  is_archived boolean not null default false,
  verified boolean not null default false,
  created_at timestamptz not null default now()
```

After the existing `products_public_read` policy, add an update policy (MVP open,
mirroring `pending_reviews updatable`):
```sql
-- Community peer-review marks a product verified once approved (issue #263).
-- MVP keeps this open to the anon/authenticated roles the app uses; tighten to
-- a reviewer/auth.uid() check once auth + roles land.
create policy "products_community_update" on products
  for update using (true) with check (true);
```

(No automated DB test runs in CI — schema is applied manually per CLAUDE.md.
Verification is via reading the file + the controller unit tests below that assert
the PATCH the app issues.)

## Task 2 — Test: controller fetchStats + approve-marks-product-verified

File: `app/test/unit/services/community_review_controller_test.dart`.

Add two groups using the existing `_RecordingHttpClient` / `_controllerWithFakeAuth`
helpers already in the file.

(a) `fetchStats` — assert it issues count requests and returns parsed numbers.
PostgREST count comes back via the `content-range` header, which the recording
client doesn't easily emulate; instead implement `fetchStats` with
`.select('id')` and count client-side (rows.length) — deterministic and testable
with the existing body-returning harness. Test:

```dart
group('CommunityReviewController.fetchStats', () {
  test('counts approved reviews and total products', () async {
    final httpClient = _RecordingHttpClient((req) {
      final path = req.url.path;
      if (path.endsWith('/pending_reviews')) {
        // approved reviews
        return jsonEncode([{'id': 'r1'}, {'id': 'r2'}, {'id': 'r3'}]);
      }
      if (path.endsWith('/products')) {
        return jsonEncode([{'id': 'p1'}, {'id': 'p2'}]);
      }
      return jsonEncode([]);
    });
    final controller = _controllerReturning(httpClient);

    final stats = await controller.fetchStats();

    expect(stats.verified, 3);
    expect(stats.added, 2);
    // verified query filters status=approved
    final reviewReq = httpClient.requests.firstWhere(
      (r) => r.url.path.endsWith('/pending_reviews'));
    expect(reviewReq.url.query, contains('status=eq.approved'));
  });
});
```

(b) Extend the approve group: after the pre-flight + PATCH to the review row,
the controller PATCHes the linked product to `verified=true`. Update the existing
approve signature to `approve(reviewId, productId)`:

```dart
test('also marks the linked product verified', () async {
  final httpClient = _RecordingHttpClient((_) => '');
  final (:controller, :auth) = _controllerWithFakeAuth(httpClient);

  await controller.approve('r-123', 'prod-9');

  // Two PATCHes: the review, then the product.
  final productReq = httpClient.requests.lastWhere(
    (r) => r.url.path.endsWith('/products'));
  expect(productReq.method, 'PATCH');
  expect(productReq.url.query, contains('id=eq.prod-9'));
  final body = jsonDecode(productReq.body) as Map<String, dynamic>;
  expect(body['verified'], true);
});
```

Also update the **existing** approve test that calls `controller.approve('r-123')`
to the new two-arg form `controller.approve('r-123', 'prod-x')` (and its body
assertions still target the `/pending_reviews` request — use
`httpClient.requests.firstWhere((r) => r.url.path.endsWith('/pending_reviews'))`
instead of `lastRequest`, since the product PATCH is now last).

Run (expect red — methods/signature don't exist yet):
```
flutter test test/unit/services/community_review_controller_test.dart
```

## Task 3 — Controller: fetchStats + verify-on-approve

File: `app/lib/services/community_review_controller.dart`.

Add `fetchStats`:
```dart
  /// Live community counters for the hub stat cards (issue #263):
  /// - [verified]: number of peer-reviews approved (`pending_reviews.status =
  ///   'approved'`).
  /// - [added]: total products in the catalog (the MVP "products added" metric;
  ///   no per-user attribution until auth lands).
  Future<({int verified, int added})> fetchStats() async {
    final approved = await _client
        .from('pending_reviews')
        .select('id')
        .eq('status', 'approved');
    final products = await _client.from('products').select('id');
    return (verified: approved.length, added: products.length);
  }
```

Change `approve` to also verify the product (threshold = 1 approval):
```dart
  /// Marks [reviewId] approved and flips the linked [productId] to
  /// `verified = true` (issue #263; MVP threshold = a single approval).
  Future<void> approve(String reviewId, String productId) async {
    await _authService.ensureSession();
    await _client.from('pending_reviews').update({
      'status': 'approved',
      'rejection_reason': null,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reviewId);
    await _client
        .from('products')
        .update({'verified': true}).eq('id', productId);
  }
```

Update the existing dartdoc above `approve` accordingly (issue #175 pre-flight
note stays).

Re-run the controller test — expect green:
```
flutter test test/unit/services/community_review_controller_test.dart
```

## Task 4 — Update approve callers

File: `app/lib/screens/community_screen.dart` — `_onApprove` calls
`widget.reviewController?.approve(review.id)`. Update to pass the product id.
`PendingReview` carries the product id — confirm the field name first:
```
grep -n "productId\|product_id\|final String" app/lib/models/pending_review.dart
```
Then:
```dart
    await widget.reviewController?.approve(review.id, review.productId);
```
(Use whatever the real field is named.)

Check for any other `.approve(` callers:
```
grep -rn "\.approve(" app/lib app/test
```
Update each to the two-arg form. `CommunityReviewScreen` may route approve through
a callback rather than the controller directly — if it calls the controller,
update it; if it calls a passed-in `onApprove(PendingReview)`, no change.

## Task 5 — CommunityScreen: drop hardcoded fallbacks

File: `app/lib/screens/community_screen.dart`.

Replace:
```dart
              value: _statValue('${widget.verifiedCount ?? 5}'),
```
with:
```dart
              value: _statValue(widget.verifiedCount?.toString() ?? '--'),
```
and:
```dart
              value: _statValue('${widget.addedCount ?? 2}'),
```
with:
```dart
              value: _statValue(widget.addedCount?.toString() ?? '--'),
```

Update the two dartdoc comments on `verifiedCount`/`addedCount` (lines ~54–60)
to drop the "Null → the spec default of 5/2" wording — null now means "unknown"
(renders `--`), and the host injects live values (issue #263).

## Task 6 — MainContainer: load + inject stats

File: `app/lib/screens/main_container.dart`.

Add state fields near `_reviewController`:
```dart
  /// Live community stat-card counts (issue #263). Null while the first load is
  /// in flight (drives the Community tab's loading `--`); `_communityStatsError`
  /// flips to true on a failed load (drives the `?` error state).
  int? _verifiedCount;
  int? _addedCount;
  bool _communityStatsLoading = true;
  bool _communityStatsError = false;
```

In `initState`, after the `_reviewController` try/catch, kick off the load only
when a controller exists (tests without Supabase keep the default loading/empty):
```dart
    if (_reviewController != null) {
      _loadCommunityStats();
    } else {
      _communityStatsLoading = false;
    }
```

Add the loader:
```dart
  Future<void> _loadCommunityStats() async {
    try {
      final stats = await _reviewController!.fetchStats();
      if (!mounted) return;
      setState(() {
        _verifiedCount = stats.verified;
        _addedCount = stats.added;
        _communityStatsLoading = false;
        _communityStatsError = false;
      });
    } catch (e) {
      debugPrint('community stats load failed: $e');
      if (!mounted) return;
      setState(() {
        _communityStatsLoading = false;
        _communityStatsError = true;
      });
    }
  }
```
(Confirm `debugPrint` is available — it is via `package:flutter/material.dart`,
already imported.)

Wire into the `CommunityScreen(...)` build:
```dart
            CommunityScreen(
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              allergens: widget.allergens,
              onAddProductTap: _navigateToAddProduct,
              reviewController: _reviewController,
              verifiedCount: _verifiedCount,
              addedCount: _addedCount,
              isLoading: _communityStatsLoading,
              hasError: _communityStatsError,
            ),
```

## Task 7 — Full verify

```
flutter pub get
```
```
flutter analyze lib test
```
Expect 0 issues.
```
flutter test
```
Expect all green. If any existing community/main_container test breaks on the new
loading default (e.g. a test mounting `MainContainer` without Supabase now sees
`_communityStatsLoading=false` → fine; with Supabase but no real backend the
catch flips error → stats show `?`, which existing tests likely don't assert),
fix the test expectations minimally or guard as above.

## Task 8 — A6 spec tracker

File: `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`, Community Hub
row (row 11). Append to the V-Spec cell:
`#263 replaced the hardcoded stat fallbacks (verifiedCount ?? 5 / addedCount ?? 2) with live counts injected from MainContainer via CommunityReviewController.fetchStats() (approved-review count + catalog size), with --/? loading/error states; approving a review now also flips products.verified=true (new column + open update policy, MVP single-approval threshold).`
Do not change status glyphs.

## Task 9 — A7 drift check
```
git fetch origin
```
```
git log origin/master..HEAD --oneline
```
Foreign commits → STOP.

## Task 10 — Commit + PR
```
git add -A
```
```
git commit
```
Message:
```
feat(community): live stat counts + approval-driven product verification (#263)

Replace the hardcoded Community stat-card fallbacks (verifiedCount ?? 5 /
addedCount ?? 2) with live counts loaded in MainContainer via a new
CommunityReviewController.fetchStats() (approved-review count + catalog
size), surfaced through the existing --/? loading/error states. Approving a
peer review now also marks the linked product verified (new products.verified
column + open update policy; MVP single-approval threshold). Reject/approve
persistence to pending_reviews was already in place.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```
```
git push -u origin agent/issue-263-community-live-stats
```
```
gh pr create --base master --repo Maortz/allergy-detector --title "feat(community): live stat counts + approval-driven product verification (#263)" --body "<body with Closes #263, summary, analyze/test results>"
```

## Task 11 — Comment + release
```
gh issue comment 263 --repo Maortz/allergy-detector --body "Opened PR <url> — <summary>."
```
```
gh issue edit 263 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
