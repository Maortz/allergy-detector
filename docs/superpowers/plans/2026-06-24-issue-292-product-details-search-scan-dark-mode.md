# Implementation Plan — Issue #292: Migrate Product Details + Search/Scan to theme-aware colors (dark mode)

**Issue:** Maortz/allergy-detector#292 (part of #258)
**Branch:** `agent/issue-292-product-details-search-scan-dark-mode` (already created)
**Effort:** M

## Goal

`product_details.dart` (49 `AppColors.*` refs) and `search_scan_screen.dart` (34) use light-only `AppColors.*` consts. Migrate to `colorScheme.*` (M3) / `context.colors.*` (semantic). No raw hex/`Colors.X` literals (only `Colors.transparent`, kept). Foundation merged (#300).

## Mapping

**M3 → `colorScheme.*`:** onSurface, onSurfaceVariant, primary, onPrimary, outline, outlineVariant, surfaceContainerLowest, surfaceContainerLow, surfaceContainerHigh, inverseSurface, inverseOnSurface.
**Fixed → Container:** `primaryFixed`→`primaryContainer`, `primaryFixedDim`→`primaryContainer`.
**Semantic → `context.colors.*`:** avoid, onAvoid, safeText, safeBackground, cautionText, cautionBackground, cautionHighlight, scanFrame, and all chip tokens (chipDisplayBg/Border, chipDetectedBg/Border/Fg, chipCautionBg/Border/Fg).

### ⚠ Chip-palette value change (intentional, per issue)
`AppColors.chipDetectedBg` = `0xFFFEE2E2` but `AppColorsExt.light().chipDetectedBg` = `0xFFFCE8E6` (the two-source divergence noted in #302). The issue explicitly directs chips → `context.colors.chip*`, so the detected-chip bg/fg **change** to the AppColorsExt values:
- chipDetectedBg `0xFFFEE2E2`→`0xFFFCE8E6`, chipDetectedFg `0xFF991B1B`→`0xFFD93025`
- chipCautionBg `0xFFFEF9C3`→`0xFFFEF7E0`, chipCautionBorder `0xFFCA8A04`→`0xFFFF9800`, chipCautionFg `0xFFA16207`→`0xFFB05B00`
- chipDisplayBg/Border unchanged (same values in both)
This is expected churn; update the affected test assertion (below).

## Test reconciliation (`test/widgets/screens/product_details_screen_test.dart`)
- L81 `banner.color == AppColors.avoid`: unchanged (`context.colors.avoid` light == `AppColors.avoid` == `0xFFDC2626`). Keep, but to be theme-safe ensure the test harness uses a theme that registers `AppColorsExt` OR relies on the `context.colors` light fallback (it does — `context.colors` falls back to `AppColorsExt.light()`). No change needed.
- L82 `isNot(AppColors.avoidBackground)`: unchanged.
- **L167 `decoration.color == const Color(0xFFFEE2E2)` → change to `const Color(0xFFFCE8E6)`** (new detected-chip bg from AppColorsExt). Update the comment.
- L262 highlight `== const Color(0xFFDC2626)`: unchanged (avoid highlight; `context.colors.avoid` light == `0xFFDC2626`).

Verify `context.colors` resolves correctly in the test harness: if it uses a bare `MaterialApp` with no theme, `context.colors` falls back to `AppColorsExt.light()` — same values asserted. Confirm by running the file.

## Tasks

1. **product_details.dart** — replace per mapping. Helper methods/sub-widgets each read `colorScheme`/`appColors` locally; drop `const` where a color becomes runtime (e.g. icons currently `Icon(..., color: AppColors.X)` are already non-const here, but the switch tuples in `_StatusPill` and `_AllergenChip` need the locals declared before them). Keep `Colors.transparent` (the ExpansionTile Material). Keep the `app_colors.dart` import (provides `context.colors`).
   - Verify: `grep -nE "AppColors\.|Color\(0x|Colors\.(white|black)" lib/screens/product_details.dart` → only `Colors.transparent`.

2. **search_scan_screen.dart** — replace per mapping. Read the file first; it has a repeating `_laserController` animation (do NOT `pumpAndSettle` in its tests per CLAUDE.md). Map `scanFrame`→`context.colors.scanFrame`, `inverseSurface`/`inverseOnSurface`→`colorScheme.*`, `primaryFixed`/`primaryFixedDim`→`colorScheme.primaryContainer`, rest M3→`colorScheme.*`. Keep `Colors.transparent` if present. Keep/drop the `app_colors.dart` import based on whether `context.colors` ends up used (scanFrame ⇒ used ⇒ keep).
   - Verify clean as task 1.

3. **Fix test L167** in `product_details_screen_test.dart`: `0xFFFEE2E2` → `0xFFFCE8E6`.

4. **Dark-render smoke tests**: add one per screen.
   - product_details: pump `MaterialApp(theme: buildDarkAppTheme(), home: ProductDetailsScreen(...))` with a sample product+profile (reuse the test file's existing fixture/helper); assert no exception + a known Hebrew string ('פרטי מוצר').
   - search_scan: reuse the existing test's widget builder with a dark theme; assert no exception. **Do NOT pumpAndSettle** — `await tester.pumpWidget(...)` only (laser animation).

5. `flutter pub get`.
6. `flutter analyze lib test` → 0 issues (watch for any deprecated `colorScheme.*` like `surfaceVariant`/`background`; replace with the recommended role if flagged).
7. `flutter test test/widgets/screens/product_details_screen_test.dart` then `flutter test test/widgets/screens/search_scan_screen_test.dart` → green.
8. `flutter test` → all green.
9. **A6**: append `#292` dark-mode note to the V-Spec/V-Art parentheticals of the Product Details (rows 4 & 5) and Search & Scan (row 2) rows in `index.md`; note the intentional chip-palette value alignment to `AppColorsExt`. Marks unchanged.
10. **A7**: `git fetch origin`; `git log origin/master..HEAD --oneline` — foreign commits → STOPPED.
11. **A8**: commit (footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`, body `Closes #292`), push, `gh pr create --base master`. PR body documents the migration, the intentional chip-bg value change (AppColors vs AppColorsExt divergence), the test update, dark-render tests, analyze/test results.
12. **A9**: comment on #292 with PR URL; `gh issue edit 292 --remove-label agent-in-progress`.

## Return
`PR_OPENED <PR_URL>`
