# Plan: refresh Community stat counts after in-session approve/reject (#278)

## Goal

After a user approves or rejects a pending review in the same session, the
Community tab stat cards (`אומתו בהצלחה` / `מוצרים נוספו`) must refresh to show
updated Supabase counts — silently (no spinner flash; keep current counts on
screen while the new fetch is in flight, then swap).

## Approach

Expose a `VoidCallback? onReviewCompleted` on `CommunityScreen`, invoked after
each successful `approve()` / `reject()`. `MainContainer` wires it to
`_loadCommunityStats()`. `_loadCommunityStats()` already performs a silent swap
— it never sets `_communityStatsLoading = true` before fetching, only sets it
`false` on completion, so no spinner re-appears.

Branch `agent/issue-278-refresh-stats-after-review` already created.

## Tasks

### Task 1 — TDD: failing widget test for the callback

In `app/test/widgets/screens/community_screen_test.dart`, add a test that:
- pumps `CommunityScreen` with a one-item `pendingReviews` queue and an
  `onReviewCompleted` spy,
- taps `התחל בבדיקה` to push `CommunityReviewScreen`,
- taps `אישור מוצר`,
- asserts the spy fired exactly once.

Add `onReviewCompleted` to the test's `createWidgetUnderTest` helper. Run the
test — it must fail to compile / fail (no such parameter yet).

### Task 2 — Implement on CommunityScreen

- Add `final VoidCallback? onReviewCompleted;` field with doc comment.
- Add `this.onReviewCompleted,` to the const constructor.
- In `_onApprove`, after the `setState` that drops the item, call
  `widget.onReviewCompleted?.call();`.
- In `_onReject`, same after its `setState`.

Run the test — it must pass.

### Task 3 — Wire MainContainer

In `app/lib/screens/main_container.dart`, on the `CommunityScreen` in the
`IndexedStack`, add `onReviewCompleted: _loadCommunityStats,`.

### Task 4 — Verify

- `flutter pub get`
- `flutter analyze lib test` → 0 issues
- `flutter test` → all green

### Task 5 — A6 spec index

Update the Community Hub row (#11) Code note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to mention #278
(stats refresh after in-session approve/reject). V-Spec / V-Art unchanged
(behaviour-only; no visual change).

### Task 6 — A7 drift, A8 commit+PR, A9 comment+release

- `git fetch origin && git log origin/master..HEAD --oneline` — foreign commits → STOP.
- Commit (footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`), push,
  `gh pr create --base master` with body `Closes #278` + analyze/test results.
- Comment on #278 linking the PR; `gh issue edit 278 --remove-label agent-in-progress`.
