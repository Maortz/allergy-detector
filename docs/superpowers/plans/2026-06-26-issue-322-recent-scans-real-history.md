# Plan: Issue #322 — Scan screen "נסרק לאחרונה" shows hardcoded placeholder

## Goal

The Scan screen's "נסרק לאחרונה" (recently scanned) section currently renders a
hardcoded `_sampleRecentScans` list in debug builds and an empty state in
release. Wire it to real `ScanHistoryService` data, fed from the host
(`MainContainer`) exactly like the home dashboard's `recentActivity`, and delete
the mock fallback. Show the single most recently scanned product (spec
search-scan.md §13/§52: "single-row entry linking to the last scanned product";
issue title "Last scanned product").

Branch `agent/issue-322-recent-scans-real-history` is already created (A3 done).

## Acceptance criteria (from issue)

- Last scanned section shows the most recently scanned product from local history.
- Section hidden / empty-state when no product has been scanned yet (already
  handled by spec §7.4 empty-state path — keep it).
- No hardcoded strings remain (`_sampleRecentScans` deleted).

## Files

- `app/lib/screens/search_scan_screen.dart` — remove mock fallback; make
  `recentScans` a real host-fed param; call new `onScanRecorded` callback after
  recording a scan.
- `app/lib/screens/main_container.dart` — map `_scanHistory` → `List<RecentScan>`
  (take 1), pass to `SearchScanScreen`; pass `onScanRecorded: _loadScanHistory`;
  refresh history when entering the Scan tab (index 1).
- `app/test/widgets/screens/search_scan_screen_test.dart` — fix the existing
  "displays recent scans" test (no longer relies on the debug sample); add a
  test proving null `recentScans` renders the empty-state (no sample leak in
  debug).
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — A6 status update.

## Task 1 — search_scan_screen.dart: remove mock, repurpose `recentScans`, add callback

1. Delete the `_sampleRecentScans` static const list (lines ~110-123).
2. Replace the `_recentScans` getter (lines ~129-130) with:
   ```dart
   List<RecentScan> get _recentScans => widget.recentScans ?? const [];
   ```
   Delete the now-stale `kDebugMode` doc comment above it.
3. Update the `recentScans` field doc + drop `@visibleForTesting` (it is now a
   production data channel mirroring `HomeScreen.recentActivity`):
   ```dart
   /// Recently-scanned products to render under "נסרק לאחרונה", supplied by the
   /// host from real [ScanHistoryService] data. `null` (still loading) or empty
   /// renders the §7.4 empty-state — there is no mock fallback (issue #322).
   final List<RecentScan>? recentScans;
   ```
4. Add a new optional callback field + constructor param:
   ```dart
   /// Invoked after a scan is recorded to scan history so the host can refresh
   /// the recently-scanned feed (issue #322).
   final VoidCallback? onScanRecorded;
   ```
   Add `this.onScanRecorded,` to the constructor.
5. In `_handleBarcodeScan`, await the record and notify the host before pushing
   details. Replace:
   ```dart
   ScanHistoryService.record(resolved, widget.userProfile);
   await Navigator.push(
   ```
   with:
   ```dart
   await ScanHistoryService.record(resolved, widget.userProfile);
   widget.onScanRecorded?.call();
   if (!mounted) return;
   await Navigator.push(
   ```
6. `kDebugMode` is no longer referenced; `kIsWeb`, `debugPrint`,
   `@visibleForTesting` still are, so keep the `foundation.dart` import.

## Task 2 — main_container.dart: feed real recent scans to the Scan tab

1. Add import: `import '../models/recent_scan.dart';`
2. Add a getter near `_recentActivity`:
   ```dart
   /// The Scan tab's "נסרק לאחרונה" row: the single most recently scanned
   /// product mapped to [RecentScan]. `null` while history is still loading;
   /// empty list renders the §7.4 empty-state (issue #322).
   List<RecentScan>? get _recentScans {
     final history = _scanHistory;
     if (history == null) return null;
     return history
         .take(1)
         .map((e) => RecentScan(
               name: e.nameHe,
               brand: e.brandNameHe ?? '',
               time: e.relativeTime(),
               status: e.status,
             ))
         .toList();
   }
   ```
3. In the `SearchScanScreen(...)` constructor in `body`, add:
   ```dart
   recentScans: _recentScans,
   onScanRecorded: _loadScanHistory,
   ```
4. In `_onNavIndexChanged`, refresh on the Scan tab too:
   ```dart
   if (index == 0 || index == 1) _loadScanHistory();
   ```
   Update the adjacent comment to mention the scan tab.

## Task 3 — tests

In `search_scan_screen_test.dart`:

1. Fix "displays recent scans section with Hebrew text" to pass an explicit list
   (the debug sample is gone):
   ```dart
   await tester.pumpWidget(createWidgetUnderTest(recentScans: const [
     RecentScan(
       name: 'חלב שולו 5%',
       brand: 'שולו',
       time: 'לפני שעה',
       status: AllergenStatus.safe,
     ),
   ]));
   ```
   (keep the same expects for 'נסרק לאחרונה', 'חלב שולו 5%', 'שולו'.)
2. Add a test proving no sample leaks when `recentScans` is null (default),
   even in debug:
   ```dart
   testWidgets('renders empty-state (no mock) when recentScans is null (#322)',
       (tester) async {
     await tester.pumpWidget(createWidgetUnderTest());
     expect(find.text('נסרק לאחרונה'), findsOneWidget);
     expect(find.text('אין סריקות אחרונות'), findsOneWidget);
     expect(find.text('חלב שולו 5%'), findsNothing);
     expect(find.text('לחם מחמצת'), findsNothing);
   });
   ```
   Ensure `RecentScan` and `AllergenStatus` are imported in the test file (check
   top-of-file imports; add if missing).

## Task 4 — A6 spec/index update

Update `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` row(s) for the
search-scan screen — note the recently-scanned section now reads real
`ScanHistoryService` data (no mock). Touch only the Code/V-Spec/V-Art cells that
apply; do not restructure the table.

## Verify (one command at a time, from `app/`)

1. `flutter pub get`
2. `flutter analyze lib test` — expect 0 issues.
3. `flutter test` — all green. (Never `pumpAndSettle` in search_scan tests.)

## A7 — drift check

`git fetch origin` then `git log origin/master..HEAD --oneline` — only this
branch's own commits should appear; foreign commits → STOP.

## A8 — commit + PR

- Commit footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- `gh pr create --base master`; body: `Closes #322`, change summary,
  analyze/test results.

## A9 — comment + release

- Comment on #322 linking the PR.
- `gh issue edit 322 --repo Maortz/allergy-detector --remove-label agent-in-progress`

## Staff-level notes

- Business logic stays out of widgets; mapping lives in `MainContainer` (host),
  mirroring `_recentActivity`.
- `const` constructors, theme tokens, Hebrew RTL-first preserved.
- No new hardcoded strings; empty-state copy already tokenised via `StateView`.
