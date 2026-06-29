# Plan: Issue #326 — "חזרה לבית" button on ReviewAllClearScreen is a no-op

## Root cause

`ReviewAllClearScreen._goHome()` calls `onReturnHome?.call()`, but none of the
four `ReviewAllClearScreen` instantiations in `community_screen.dart` (lines 212,
235, 302, 377) pass `onReturnHome` — so the button silently does nothing. The
sibling `ReviewNextScreen` already wires an `onGoHome` that pops to root +
switches to Home tab; reuse that idiom.

Branch `agent/issue-326-allclear-home-button` already created (A3 done).

## Fix

Wire `onReturnHome` on every `ReviewAllClearScreen` (and dedupe the existing
`ReviewNextScreen.onGoHome` logic) via one shared helper on `CommunityScreen`'s
state.

### Task 1 — add `_returnHome` helper + wire all sites (`community_screen.dart`)

1. Add the helper near `_onQueueExhausted`:
   ```dart
   /// Returns to the Home tab from a pushed terminal review screen: pops every
   /// route above the [MainContainer] root, then selects the Home tab. Shared
   /// by [ReviewAllClearScreen.onReturnHome] and [ReviewNextScreen.onGoHome]
   /// (#326).
   void _returnHome() {
     Navigator.of(context).popUntil((route) => route.isFirst);
     widget.onNavIndexChanged(0);
   }
   ```
2. Add `onReturnHome: _returnHome,` to each of the four `ReviewAllClearScreen(`
   constructors (in `_onQueueExhausted`, `_onReviewCompleted`,
   `_buildReviewScreen` defensive fallback, `_startReviewWithService` empty-queue).
3. Replace the inline `onGoHome` closure in `_onReviewCompleted` (ReviewNextScreen):
   ```dart
   onGoHome: () {
     Navigator.of(context).popUntil((route) => route.isFirst);
     widget.onNavIndexChanged(0);
   },
   ```
   with `onGoHome: _returnHome,`.

The `ReviewAllClearScreen` widget itself already exposes `onReturnHome` and a
tested "home CTA invokes onReturnHome" — no change needed there.

### Task 2 — test (`community_screen_test.dart`)

Add a test driving the in-memory path to the all-clear screen and asserting the
button switches to Home:

```dart
testWidgets(
  '"חזרה לבית" on the all-clear screen returns to the Home tab (#326)',
  (tester) async {
    int? selectedTab;
    await tester.pumpWidget(
      createWidgetUnderTest(
        onNavIndexChanged: (i) => selectedTab = i,
        pendingReviews: const [
          PendingReview(
            id: 'r1',
            productId: 'p1',
            productName: 'מוצר א',
            brandName: 'מותג א',
            categoryLabel: 'חטיפים',
          ),
        ],
      ),
    );

    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'התחל בבדיקה'));
    await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'אישור מוצר'));
    await tester.tap(find.widgetWithText(FilledButton, 'אישור מוצר'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Now on the all-clear celebration screen.
    expect(find.text('כל הכבוד!'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'חזרה לבית'));
    await tester.tap(find.widgetWithText(FilledButton, 'חזרה לבית'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(selectedTab, 0);
  },
);
```

If the exact navigation timing needs adjusting, drive extra `pump`s — never
`pumpAndSettle` (the all-clear screen has no infinite animation, but keep the
project convention conservative).

### Task 3 — A6 spec/index update

Add a short #326 note to the `review-all-clear` row Code cell in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

## Verify (from `app/`, one at a time)
1. `flutter pub get`
2. `flutter analyze lib test` — 0 issues.
3. `flutter test` — all green.

## A7 — drift check
`git fetch origin` then `git log origin/master..HEAD --oneline`.

## A8 — commit + PR
Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; body
`Closes #326` + summary + analyze/test results.

## A9 — comment + release
Comment on #326 with PR link; `gh issue edit 326 --remove-label agent-in-progress`.
