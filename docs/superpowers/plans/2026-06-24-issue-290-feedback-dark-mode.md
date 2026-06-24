# Implementation Plan — Issue #290: Migrate Feedback + FeedbackSuccess screens to theme-aware colors (dark mode)

**Issue:** Maortz/allergy-detector#290 (part of #258)
**Branch:** `agent/issue-290-feedback-dark-mode` (already created — execution starts at the first code task)
**Effort:** M

## Goal

`feedback_screen.dart` (~35 literal hits) and `feedback_success_screen.dart` (~23) use raw `Color(0xFF...)` hex literals, `Colors.black.withValues(...)`, and light-only `AppColors.*` consts that don't adapt to dark mode. Replace each with a theme-aware accessor. Foundation (`AppColorsExt` light+dark) is merged (#300).

## Token mapping (decided from light-theme value parity + role semantics)

| Literal | Replacement | Rationale |
|---|---|---|
| `Color(0xFF1F2937)` (gray-800 text) | `Theme.of(context).colorScheme.onSurface` | primary text |
| `Color(0xFF374151)` (gray-700 label) | `Theme.of(context).colorScheme.onSurface` | bold label text |
| `Color(0xFF6B7280)` (gray-500) | `Theme.of(context).colorScheme.onSurfaceVariant` | secondary text/icon |
| `Color(0xFF9CA3AF)` (gray-400) | `context.colors.iconMuted` | exact light value `0xFF9CA3AF`; muted hint/icon |
| `Color(0xFFE5E7EB)` (gray-200 border) | `context.colors.borderSubtle` | exact light value |
| `Color(0xFFD1D5DB)` (gray-300 border) | `context.colors.borderSubtle` | subtle border role |
| `Color(0xFFBFDBFE)` (blue-200 placeholder) | `context.colors.primaryTintBorder` | exact light value `0xFFBFDBFE` |
| `Color(0xFFF3F4F5)` (placeholder bg) | `Theme.of(context).colorScheme.surfaceContainerLow` | exact light value |
| `Color(0xFFF9FAFB)` (upload-zone bg) | `Theme.of(context).colorScheme.surfaceContainerLow` | faint neutral fill |
| `AppColors.surface` | `colorScheme.surface` | M3 role |
| `AppColors.background` | `colorScheme.surface` | scaffold bg (dark themes have no distinct `background`; `surface` is the M3 successor) |
| `AppColors.surfaceContainerLowest` | `colorScheme.surfaceContainerLowest` | M3 role |
| `AppColors.onSurface` | `colorScheme.onSurface` | M3 role |
| `AppColors.onSurfaceVariant` | `colorScheme.onSurfaceVariant` | M3 role |
| `AppColors.primary` | `colorScheme.primary` | M3 role |
| `AppColors.onPrimary` | `colorScheme.onPrimary` | M3 role |
| `AppColors.primaryContainer` | `colorScheme.primaryContainer` | M3 role |
| `AppColors.primaryTint` | `context.colors.primaryTint` | AppColorsExt token (selected chip bg) |
| `AppColors.closeButtonOverlay` | `context.colors.closeButtonOverlay` | AppColorsExt token |
| `AppColors.success` | `context.colors.success` | AppColorsExt token |
| `AppColors.safeBackground` / `safeText` | `context.colors.safeBackground` / `safeText` | AppColorsExt tokens |
| `AppColors.primaryFixed` / `primaryFixedDim` / `onPrimaryFixedVariant` | `colorScheme.primaryContainer` / `colorScheme.primary` / `colorScheme.onPrimaryContainer` | community badge — map the Fixed roles to their Container equivalents (Fixed roles are not theme-adaptive in this app's dark scheme) |
| `Colors.black.withValues(alpha: x)` | `colorScheme.shadow.withValues(alpha: x)` | adaptive shadow |
| `Colors.transparent` | keep | theme-agnostic |

Both files are `StatelessWidget`s / contain stateless sub-widgets, each with a `build(context)`. Where a helper method currently takes no `context`, thread `BuildContext context` into it (and its call site). For `const` widgets whose colors become runtime values, drop `const`.

## Test latitude

`test/feedback_test.dart` and `test/widgets/screens/feedback_success_screen_test.dart` assert only behavior and Hebrew text — **no color assertions**. So value remapping is safe as long as widget structure and text are preserved. A new dark-render smoke test will be added per file area.

---

## Task 1 — `feedback_success_screen.dart`

Convert each helper to receive `context` and read `final colorScheme = Theme.of(context).colorScheme;` / `final appColors = context.colors;` where needed.

- `build`: `AppColors.background`→`colorScheme.surface` (Scaffold + AppBar bg); AppBar title + back-icon `AppColors.onSurface`→`colorScheme.onSurface`.
- `_buildSuccessIcon(context)`: container `AppColors.surfaceContainerLowest`→`colorScheme.surfaceContainerLowest`; ring `AppColors.success.withValues(0.3)`→`appColors.success.withValues(0.3)`; shadow `Colors.black.withValues(0.12)`→`colorScheme.shadow.withValues(0.12)`; check icon `AppColors.success`→`appColors.success` (drop `const` on the Icon).
- `_buildHeadline(context)`: `AppColors.primary`→`colorScheme.primary`.
- `_buildBody(context)`: `AppColors.onSurfaceVariant`→`colorScheme.onSurfaceVariant`.
- `_buildBadgePair(context)`: pass through; map the two badge arg sets:
  - badge 1: `background: appColors.safeBackground`, `border: appColors.success.withValues(0.3)`, `iconColor: appColors.success`, `labelColor: appColors.safeText`.
  - badge 2: `background: colorScheme.primaryContainer.withValues(alpha: 0.2)`, `border: colorScheme.primary`, `iconColor: colorScheme.primary`, `labelColor: colorScheme.onPrimaryContainer`.
- `_buildHomeButton(context)`: `AppColors.primary`→`colorScheme.primary`, `AppColors.onPrimary`→`colorScheme.onPrimary`.
- `_buildFooter(context)`: footer text `AppColors.onSurface`→`colorScheme.onSurface`; health icon `AppColors.primary`→`colorScheme.primary` (drop `const`); brand text `AppColors.primaryContainer`→`colorScheme.primaryContainer`.

Update all helper call sites in `build` to pass `context`.

Verify file is clean:
```
grep -nE "Colors\.(white|black)|Color\(0x|AppColors\." app/lib/screens/feedback_success_screen.dart
```
Only `Colors.transparent` (if any) may remain; expect none here.

## Task 2 — `feedback_screen.dart`

Each sub-widget is a `StatelessWidget` with its own `build(context)` — read `colorScheme`/`appColors` locally; no signature changes needed except dropping `const` where colors are now runtime.

- `_FeedbackScreenState.build`: `AppColors.surface`→`colorScheme.surface`; AppBar `AppColors.surfaceContainerLowest`→`colorScheme.surfaceContainerLowest`; back-icon `AppColors.onSurfaceVariant`→`colorScheme.onSurfaceVariant`.
- `_SectionHeading`: `Color(0xFF1F2937)`→`colorScheme.onSurface`.
- `_ProductContextCard`: card `AppColors.surfaceContainerLowest`→`colorScheme.surfaceContainerLowest`; border `Color(0xFFE5E7EB)`→`appColors.borderSubtle`; name `Color(0xFF1F2937)`→`colorScheme.onSurface`; barcode `Color(0xFF6B7280)`→`colorScheme.onSurfaceVariant`; `_placeholder()` → make it `_placeholder(BuildContext context)`: bg `Color(0xFFF3F4F5)`→`colorScheme.surfaceContainerLow`, icon `Color(0xFF9CA3AF)`→`appColors.iconMuted` (drop `const`). Update both `_placeholder()` call sites to `_placeholder(context)`.
- `_IssueChip`: selected bg `AppColors.primaryTint`→`appColors.primaryTint`; unselected bg `AppColors.surfaceContainerLowest`→`colorScheme.surfaceContainerLowest`; border selected `AppColors.primary`→`colorScheme.primary`, unselected `Color(0xFFE5E7EB)`→`appColors.borderSubtle`; icon selected `AppColors.primary`→`colorScheme.primary`, unselected `Color(0xFF6B7280)`→`colorScheme.onSurfaceVariant`; label selected `AppColors.primary`→`colorScheme.primary`, unselected `Color(0xFF374151)`→`colorScheme.onSurface`.
- `_DetailsTextField`: hint `Color(0xFF9CA3AF)`→`appColors.iconMuted`; fill `AppColors.surfaceContainerLowest`→`colorScheme.surfaceContainerLowest`; border + enabledBorder `Color(0xFFE5E7EB)`→`appColors.borderSubtle` (drop `const` on those `BorderSide`s); focusedBorder `AppColors.primary`→`colorScheme.primary` (drop `const`).
- `_PhotoUploadZone`: bg `Color(0xFFF9FAFB)`→`colorScheme.surfaceContainerLow`; border `Color(0xFFD1D5DB)`→`appColors.borderSubtle`; add-photo icon `Color(0xFF6B7280)`→`colorScheme.onSurfaceVariant` (drop `const`); title `Color(0xFF374151)`→`colorScheme.onSurface`; subtitle `Color(0xFF9CA3AF)`→`appColors.iconMuted`.
- `_ThumbnailZone`: the two web/error `ColoredBox(color: Color(0xFFBFDBFE))`→`appColors.primaryTintBorder` (drop `const` on those `ColoredBox`es); close button `AppColors.closeButtonOverlay`→`appColors.closeButtonOverlay` (drop `const` on the `BoxDecoration`); close icon `AppColors.onPrimary`→`colorScheme.onPrimary` (drop `const`).
- `_SubmitButton`: spinner `AppColors.onPrimary`→`colorScheme.onPrimary`; send icon `AppColors.onPrimary`→`colorScheme.onPrimary`; bg `AppColors.primary`→`colorScheme.primary`; fg `AppColors.onPrimary`→`colorScheme.onPrimary` (drop `const` where needed — the spinner/icon become runtime-colored).
- `_CancelButton`: fg `AppColors.onSurfaceVariant`→`colorScheme.onSurfaceVariant`; side `Color(0xFFE5E7EB)`→`appColors.borderSubtle` (drop `const`).

Verify clean:
```
grep -nE "Colors\.(white|black)|Color\(0x|AppColors\." app/lib/screens/feedback_screen.dart
```
Only `Colors.transparent` (none expected) may remain.

## Task 3 — Keep imports

`app_colors.dart` provides the `context.colors` extension — keep the import in both files even though direct `AppColors.` references are gone. The analyzer will flag it if it becomes truly unused (it won't, because `context.colors` lives there).

## Task 4 — Dark-mode tests

Add to `test/feedback_test.dart` (or a co-located group) a dark-render smoke test:
```dart
testWidgets('FeedbackScreen renders under dark theme without exception (#290)',
    (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDarkAppTheme(),
      home: FeedbackScreen(
        productId: 'p1',
        productName: 'מוצר',
        productBarcode: '7290000000000',
        productImageUrl: null,
        onSubmit: (_, __, ___) async {},
      ),
    ),
  );
  expect(tester.takeException(), isNull);
  expect(find.text('דיווח על שגיאה'), findsOneWidget);
});
```
Add to `test/widgets/screens/feedback_success_screen_test.dart`:
```dart
testWidgets('renders under dark theme without exception (#290)',
    (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDarkAppTheme(),
      home: FeedbackSuccessScreen(onHome: () {}, onNavTap: (_) {}),
    ),
  );
  expect(tester.takeException(), isNull);
  expect(find.text('הדיווח נשלח בהצלחה!'), findsOneWidget);
});
```
Import `package:app/theme/app_theme.dart` in each test file (check existing imports — match how the existing tests construct the widget; reuse their helper if present). Use `onNavTap: (_) {}` so `BottomNavBar` taps don't hit `MainContainer.switchToTab`.

## Task 5 — Verify: pub get
From `app/`: `flutter pub get`

## Task 6 — Verify: analyze
From `app/`: `flutter analyze lib test` → 0 issues.

## Task 7 — Verify: feedback tests
From `app/`: `flutter test test/feedback_test.dart`
Then: `flutter test test/widgets/screens/feedback_success_screen_test.dart`
Both green.

## Task 8 — Verify: full suite
From `app/`: `flutter test` → all green.

## Task 9 — A6 spec index
Update `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` rows for the report-issue / feedback-success screens: append a brief `#290` dark-mode note to the V-Spec column parenthetical (theme-aware color migration), leaving ✓/⬜ marks unchanged. If those screens lack rows, skip with a note in the PR body.

## Task 10 — A7 drift check
```
git fetch origin
git log origin/master..HEAD --oneline
```
Foreign commits → `STOPPED foreign commits on master`.

## Task 11 — A8 commit + push + PR
```
git add app/lib/screens/feedback_screen.dart app/lib/screens/feedback_success_screen.dart app/test/feedback_test.dart app/test/widgets/screens/feedback_success_screen_test.dart docs/superpowers/specs/2026-05-19-stitch-screens/index.md docs/superpowers/plans/2026-06-24-issue-290-feedback-dark-mode.md
git commit -m "feat(feedback): migrate Feedback + FeedbackSuccess screens to theme-aware colors

Replaces raw Color(0xFF...) hex, Colors.black shadows, and light-only
AppColors.* consts with colorScheme.* M3 roles and context.colors.*
semantic tokens so both screens adapt to dark mode. Adds dark-theme
render smoke tests.

Closes #290

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push -u origin agent/issue-290-feedback-dark-mode
gh pr create --repo Maortz/allergy-detector --base master --title "feat(feedback): dark-mode theme-aware colors for Feedback screens (#290)" --body "<body>"
```
PR body: `Closes #290 (part of #258)`, summary of the literal→token migration across both files, note that feedback tests have no color assertions so behavior is preserved, dark-render smoke tests added, and analyze/test results.

## Task 12 — A9 comment + release claim
```
gh issue comment 290 --repo Maortz/allergy-detector --body "PR opened: <PR_URL>"
gh issue edit 290 --repo Maortz/allergy-detector --remove-label agent-in-progress
```

## Return
`PR_OPENED <PR_URL>`
