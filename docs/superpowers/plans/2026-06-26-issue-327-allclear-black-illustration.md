# Plan: Issue #327 — black element below "חזרה לבית" on ReviewAllClearScreen

## Root cause

`ReviewAllClearScreen._buildIllustration()` renders
`assets/images/review_all_clear.jpg` with `BoxFit.cover` at full opacity in a
180pt-tall box. That asset is a **1×1 placeholder JPEG** (byte-identical to
`onboarding_hero.jpg`); stretched full-bleed it paints a solid block — the
"unidentified black element". The real "Safe Food Lab" art was never shipped.
(Community/onboarding dodge this by painting their 1×1 stub at 0.30 opacity over
a themed background; the all-clear screen paints it at full opacity.) An
`errorBuilder` would not help — the 1×1 asset loads successfully.

Branch `agent/issue-327-allclear-black-illustration` already created (A3 done).

## Fix (AC option: replace with the intended widget)

Replace the bare stretched bitmap with an on-theme decorative panel so no black
block appears on any platform, pending real art.

### Task 1 — `review_all_clear_screen.dart`

Change `_buildIllustration()` to take `BuildContext` and render a themed panel:
```dart
  /// Decorative celebration panel (spec §4.6/§7.6). The original art asset was a
  /// 1×1 placeholder JPEG that, stretched full-bleed with BoxFit.cover, painted
  /// a solid black block below the CTA (#327). Until real "Safe Food Lab" art
  /// ships, render an on-theme decorative panel instead. Decorative only —
  /// excluded from semantics.
  Widget _buildIllustration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.spa_outlined,
          size: 64,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
```
Update the call site `_buildIllustration()` → `_buildIllustration(context)` (in
`build`).

### Task 2 — test (`review_all_clear_screen_test.dart`)

Replace the AC6 "renders the decorative illustration asset" test (which asserted
the now-removed raw `Image`) with a regression guard:
```dart
    testWidgets(
        'AC6/#327: renders a decorative panel, not a raw black image asset',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // The 1×1 placeholder asset rendered as a solid black block (#327); no
      // raw Image must remain.
      expect(find.byType(Image), findsNothing);
      // An on-theme decorative panel is shown instead.
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    });
```

### Task 3 — A6 spec/index update

Add a #327 note to the `review-all-clear` row in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md`: the illustration art
was a 1×1 placeholder rendering as a black block; replaced with an on-theme
decorative panel pending real art.

## Verify (from `app/`, one at a time)
1. `flutter pub get`
2. `flutter analyze lib test` — 0 issues.
3. `flutter test` — all green.

## A7 — drift check
`git fetch origin` then `git log origin/master..HEAD --oneline`.

## A8 — commit + PR
Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; body
`Closes #327` + summary + analyze/test results.

## A9 — comment + release
Comment on #327 with PR link; `gh issue edit 327 --remove-label agent-in-progress`.
