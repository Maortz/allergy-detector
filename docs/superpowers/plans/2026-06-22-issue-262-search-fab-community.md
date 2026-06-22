# Plan — Issue #262: Search/Scan "+" pushes broken, dark-mode CommunityScreen

## Problem

The active-search overlay (`SearchScreenContent` in `app/lib/screens/search_screen.dart`,
opened by typing in the Search/Scan tab) has a FloatingActionButton (tooltip
"הוסף מוצר", `Icons.add`) whose `onPressed` pushes a **bare**
`CommunityScreen` via `MaterialPageRoute`:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityScreen(
          currentNavIndex: 2,
          onNavIndexChanged: (i) {},
        ),
      ),
    );
  },
  tooltip: 'הוסף מוצר',
  child: const Icon(Icons.add),
),
```

Two defects, matching the issue exactly:

1. **Broken layout / wrong behaviour.** This inline `CommunityScreen` is missing
   `allergens`, `onAddProductTap`, `reviewController`, and gets a no-op
   `onNavIndexChanged`. It is a degraded duplicate of the canonical Community tab
   (which `MainContainer` builds at line ~480 with all params wired). The "+"
   is meant to start the *add-product* flow, not re-render Community.
2. **Switches to dark mode.** The overlay's `AppBar` uses
   `backgroundColor: Theme.of(context).colorScheme.inversePrimary`
   (`search_screen.dart` line 241). `inversePrimary` is an inverted/dark swatch,
   so the surface that hosts the "+" reads as dark-themed regardless of the
   app-level light/dark setting.

The canonical add-product entry already exists: `MainContainer._navigateToAddProduct`
pushes the real `AddProductWizard` and, on completion, pops + switches to the
Community tab (`_onNavIndexChanged(2)`). The fix routes the overlay's "+" to that
same callback and removes the mis-themed AppBar color.

## Fix strategy

Thread an optional `VoidCallback? onAddProductTap` from `MainContainer` →
`SearchScanScreen` → `SearchScreenContent`. The overlay FAB invokes it instead of
inline-pushing `CommunityScreen`. Also replace the `inversePrimary` AppBar color
with a theme-aware token so the overlay never forces a dark surface. Drop the now
unused `community_screen.dart` import.

Staff-level notes: keep callbacks optional (`VoidCallback?`) so existing tests and
the `@visibleForTesting` SearchScanScreen test helper need no change; no business
logic added to widgets; use `AppColors`/theme tokens, Hebrew RTL preserved;
`const` where possible.

Branch `agent/issue-262-search-fab-community` is already created (A3 done).
Execution starts at Task 1.

---

## Task 1 — Test: overlay "+" invokes onAddProductTap, does not push CommunityScreen

File: `app/test/search_screen_test.dart` (add a new test).

Add a widget test that pumps `SearchScreenContent` with a spy `onAddProductTap`,
taps the `Icons.add` FAB, and asserts (a) the callback fired and (b) no
`CommunityScreen` was pushed. Use `pumpWidget` + a single `pump()` — do **not**
`pumpAndSettle` (the screen kicks off a Supabase load in a post-frame callback;
in the test env it errors out fast, but settling is unnecessary and flaky).

```dart
testWidgets('overlay "+" FAB calls onAddProductTap and does not push CommunityScreen',
    (tester) async {
  var addTaps = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: SearchScreenContent(
        userProfile: const UserProfile(),
        allergens: const [],
        onProfileUpdated: (_) {},
        onAddProductTap: () => addTaps++,
      ),
    ),
  );
  await tester.pump(); // let the post-frame load fire & fail without settling

  final fab = find.byIcon(Icons.add);
  expect(fab, findsOneWidget);
  await tester.tap(fab);
  await tester.pump();

  expect(addTaps, 1);
  expect(find.byType(CommunityScreen), findsNothing);
});
```

Add imports at the top of the test file if missing:
`import 'package:allergy_detector/screens/search_screen.dart';`,
`import 'package:allergy_detector/screens/community_screen.dart';`,
`import 'package:allergy_detector/models/user_profile.dart';`.
(Confirm the package name from `pubspec.yaml` `name:` before writing the import —
use whatever that value is.)

Verify it **fails** first:
```
flutter test test/search_screen_test.dart
```
Expect a compile error (param `onAddProductTap` does not exist yet) — that is the
red state.

## Task 2 — Add `onAddProductTap` to `SearchScreenContent` and fix the FAB + AppBar

File: `app/lib/screens/search_screen.dart`.

1. Add the field + constructor param:
```dart
  final ValueChanged<UserProfile> onProfileUpdated;

  /// Invoked by the overlay "+" FAB to start the add-product flow. Supplied by
  /// MainContainer (→ AddProductWizard). Optional so the screen degrades safely
  /// when no host wires it.
  final VoidCallback? onAddProductTap;

  const SearchScreenContent({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
    this.onAddProductTap,
  });
```

2. Replace the FAB `onPressed` body so it calls the callback instead of pushing
   `CommunityScreen`. When the callback is null, hide the FAB entirely (no broken
   fallback):
```dart
        floatingActionButton: widget.onAddProductTap == null
            ? null
            : FloatingActionButton(
                onPressed: widget.onAddProductTap,
                tooltip: 'הוסף מוצר',
                child: const Icon(Icons.add),
              ),
```

3. Fix the dark AppBar — replace
   `backgroundColor: Theme.of(context).colorScheme.inversePrimary,` with a
   theme-aware surface token so it follows the active theme:
```dart
          backgroundColor: Theme.of(context).colorScheme.surface,
```

4. Remove the now-unused `import 'community_screen.dart';` (line 2). If
   `flutter analyze` later reports it is still referenced elsewhere in the file,
   keep it — but after step 2 it should be unused.

Re-run the Task-1 test — expect green:
```
flutter test test/search_screen_test.dart
```

## Task 3 — Thread the callback through SearchScanScreen

File: `app/lib/screens/search_scan_screen.dart`.

1. Add an optional field + constructor param:
```dart
  final ValueChanged<UserProfile>? onProfileUpdated;

  /// Forwarded to the active-search overlay's "+" FAB so it can launch the
  /// add-product flow via the host (MainContainer). Optional for tests.
  final VoidCallback? onAddProductTap;

  const SearchScanScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.productService,
    this.onProfileUpdated,
    this.onAddProductTap,
    this.scannerService,
    this.mobileScannerBuilder,
    this.recentScans,
  });
```

2. In `_openSearch()`, pass it through to `SearchScreenContent`:
```dart
        builder: (_) => SearchScreenContent(
          userProfile: widget.userProfile,
          allergens: widget.allergens,
          onProfileUpdated: widget.onProfileUpdated ?? (_) {},
          onAddProductTap: widget.onAddProductTap,
        ),
```

Verify:
```
flutter analyze lib/screens/search_scan_screen.dart lib/screens/search_screen.dart
```

## Task 4 — Wire MainContainer's add-product callback into SearchScanScreen

File: `app/lib/screens/main_container.dart`.

In the `SearchScanScreen(...)` build (around line 473), add:
```dart
            SearchScanScreen(
              userProfile: widget.userProfile,
              allergens: widget.allergens,
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              onProfileUpdated: widget.onProfileUpdated,
              onAddProductTap: _navigateToAddProduct,
            ),
```

`_navigateToAddProduct` already pushes `AddProductWizard` and, on
`onReturnToCommunity`, pops and switches to the Community tab — the correct,
fully-themed flow. No new method needed.

## Task 5 — Full verify

One command at a time (no `&&` chaining):
```
flutter pub get
```
```
flutter analyze lib test
```
Expect: 0 issues. Resolve any (e.g. leftover unused import).
```
flutter test
```
Expect: all green.

## Task 6 — A6 spec tracker update

File: `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

This is a navigation/theming bugfix, not a spec-coverage change, but the
Search & Scan row (row 2) and Active Search row (row 3) carry an audit trail of
fixes in their V-Spec cell. Append a short note to **row 3** (Active Search /
`search_screen.dart`) V-Spec cell, e.g.:
`#262 routed the active-search overlay "+" FAB to the canonical add-product flow (AddProductWizard via MainContainer) instead of inline-pushing a bare, mis-parameterised CommunityScreen, and dropped the inversePrimary AppBar colour that forced a dark surface — overlay now follows the app theme.`
Do not change any status glyphs (still ⚠ / ✓).

## Task 7 — A7 drift check

```
git fetch origin
```
```
git log origin/master..HEAD --oneline
```
Only this branch's own commit(s) should appear. Any foreign commit on
`origin/master` not from this branch → STOP (`STOPPED foreign commits on master`).

## Task 8 — Commit + PR

```
git add -A
```
```
git commit
```
Commit message:
```
fix(search): route active-search "+" to add-product flow, drop dark AppBar (#262)

The active-search overlay's "+" FAB pushed a bare CommunityScreen via
MaterialPageRoute — missing allergens/onAddProductTap/reviewController and
given a no-op onNavIndexChanged — so it rendered a broken duplicate of the
Community tab. Its AppBar also used colorScheme.inversePrimary, forcing a
dark surface regardless of the app theme.

The FAB now invokes an onAddProductTap callback threaded from MainContainer
(→ AddProductWizard, the canonical add-product flow), and the AppBar uses a
theme-aware surface token. Community is no longer reachable via this path.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```
```
git push -u origin agent/issue-262-search-fab-community
```
```
gh pr create --base master --repo Maortz/allergy-detector --title 'fix(search): route active-search "+" to add-product flow, drop dark AppBar (#262)' --body "<body>"
```
PR body must include: `Closes #262`, a change summary (the two defects + the fix),
and the analyze/test results from Task 5.

## Task 9 — Comment on issue + release claim

```
gh issue comment 262 --repo Maortz/allergy-detector --body "Opened PR <url> — <one-line summary>."
```
```
gh issue edit 262 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
