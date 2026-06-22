# Plan: Remove hardcoded "Last Scan" mock from Home (#261)

Branch `agent/issue-261-home-last-scan-real-data` is already created. Execution starts at the first code task.

## Root cause (investigated)

The home "פעילות אחרונה" feed was wired to real `ScanHistoryService` data in #77, and
`MainContainer` passes `recentActivity: _recentActivity` (real, mapped scans; `null` only while
loading, with `isLoading: _scanHistory == null`). However `home_screen.dart` still keeps a
`_kDefaultMockActivity` const list ("חלב שולו 5%", "לחם מחמצת", "שוקולד מריר") used as the
fallback when `recentActivity == null` (`_sourceActivity = widget.recentActivity ?? _kDefaultMockActivity`,
L112-113). This is the leftover hardcoded data the issue (AC4 "no hardcoded product data remains")
targets. The empty (`const []`) and loading states already work correctly.

## Approach

Drop the mock fallback: `_sourceActivity` returns `widget.recentActivity ?? const <RecentActivity>[]`
so a null/empty feed renders the existing no-scans empty state instead of fake products. Delete
`_kDefaultMockActivity`. Update `home_screen_test.dart` so the filter tests pass an explicit
3-item `recentActivity` (the same safe/caution/avoid items) rather than relying on the deleted
mock. The production path (`MainContainer`) is unchanged.

Out of scope: `SearchScanScreen`'s own separate recent-scan mock (different screen; this issue
is Home-only).

## Tasks

### Task 1 — Remove the mock fallback

In `app/lib/screens/home_screen.dart`:
- Delete the `_kDefaultMockActivity` const (L32-56) and its doc comment.
- Change `_sourceActivity` to:
  `List<RecentActivity> get _sourceActivity => widget.recentActivity ?? const <RecentActivity>[];`
- Update the `recentActivity` doc comment: null/empty → no-scans empty state (no mock).

### Task 2 — Update tests to supply explicit data

In `app/test/widgets/screens/home_screen_test.dart`:
- Add a shared `const _sampleActivity` (3 items: safe 'חלב שולו 5%', caution 'לחם מחמצת',
  avoid 'שוקולד מריר') at top of `main`.
- In the "recent activity respects productFilterLevel (#41)" group, pass
  `recentActivity: _sampleActivity` to each `createWidgetUnderTest` call (the items are no
  longer auto-supplied).
- Default `createWidgetUnderTest` calls that previously relied on the mock for non-activity
  assertions (greeting, name, "פעילות אחרונה" heading, etc.) are unaffected — they don't assert
  on the mock rows. The section heading still renders (it's outside the empty/data branch).
- Keep the Tier-2 state-variant tests (empty/loading/filtered) as-is — they already pass
  explicit `recentActivity` or `isLoading`.

### Task 3 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

analyze 0 issues; tests green.

### Task 4 — A6 spec index update

Update the Home Dashboard row note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to record #261 (removed the
`_kDefaultMockActivity` fallback — a null/empty feed now renders the no-scans empty state; real
data already flows from `ScanHistoryService` via `MainContainer` since #77).

### Task 5 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 6 — A8 commit + PR

Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; push; `gh pr create --base master`,
body `Closes #261`, root-cause summary, analyze/test results.

### Task 7 — A9 comment + release

Comment on #261 linking PR; `gh issue edit 261 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
