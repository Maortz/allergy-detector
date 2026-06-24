# Implementation Plan — Issue #291: Migrate Home + Community screens to theme-aware colors (dark mode)

**Issue:** Maortz/allergy-detector#291 (part of #258)
**Branch:** `agent/issue-291-home-community-dark-mode` (already created — execution starts at the first code task)
**Effort:** M

## Goal

Three screens reference light-only `AppColors.*` static consts that don't adapt to dark mode:
- `app/lib/screens/home_screen.dart`
- `app/lib/screens/community_screen.dart`
- `app/lib/screens/community_review_screen.dart`

Survey result: there are **no raw `Color(0xFF…)` hex literals and no raw `Colors.X`** except `Colors.transparent` (theme-agnostic, allowed). The entire migration is mechanical: `AppColors.<role>` → `Theme.of(context).colorScheme.<role>` (M3 roles) or `context.colors.<token>` (semantic tokens). Foundation (`AppColorsExt` light+dark) is merged (#300).

## Token mapping

**M3 roles → `colorScheme.*`** (identical light values; adapt in dark):
`onSurface`, `primary`, `onSurfaceVariant`, `surfaceContainerLow`, `outline`, `onPrimary`, `error`, `surfaceContainerLowest`, `onErrorContainer`, `secondary`, `outlineVariant`, `surfaceContainer`, `secondaryContainer`, `errorContainer`, `surfaceContainerHigh`, `surfaceVariant`, `surfaceContainerHighest`, `surface`, `onSecondaryContainer`.

**Fixed roles** (not theme-adaptive in this app) → Container equivalents:
- `AppColors.primaryFixed` → `colorScheme.primaryContainer`
- `AppColors.onPrimaryFixed` → `colorScheme.onPrimaryContainer`
- `AppColors.onPrimaryFixedVariant` → `colorScheme.onPrimaryContainer`

**Semantic tokens → `context.colors.*`:**
- `AppColors.safeText` → `context.colors.safeText`
- `AppColors.safeBackground` → `context.colors.safeBackground`
- `AppColors.success` → `context.colors.success`

**Value-parity invariant:** all `colorScheme.*` light values and `AppColorsExt.light()` values equal the prior `AppColors.*` consts, so light appearance and any light-theme widget test assertions are preserved.

## Execution per file

For each file: where colors come from `AppColors.*` inside a `build`/helper that has a `BuildContext`, read `final colorScheme = Theme.of(context).colorScheme;` and/or `final appColors = context.colors;` at the top and replace each reference. Drop `const` on any widget whose color becomes a runtime value. Sub-widgets that are separate `StatelessWidget`/`StatefulWidget` classes each get their own local reads. Thread `BuildContext` into any pure helper method that currently takes none but needs theme (mirror the approach used in #289/#290). Keep the `app_colors.dart` import (provides `context.colors`). Preserve `Colors.transparent`.

### Task 1 — `home_screen.dart`
Replace all `AppColors.*` per the mapping. Verify clean:
```
grep -nE "Colors\.(white|black|grey|red|orange|green|blue)|Color\(0x|AppColors\." app/lib/screens/home_screen.dart
```
Only `Colors.transparent` may remain.

### Task 2 — `community_screen.dart`
Replace all `AppColors.*` per the mapping. The two stat cards (≈ lines 456–470) use `accentColor: AppColors.success` → `context.colors.success` and `accentColor: AppColors.primary` → `colorScheme.primary`. Verify clean as Task 1.

### Task 3 — `community_review_screen.dart`
Replace all `AppColors.*` per the mapping (64 refs — the bulk). Verify clean as Task 1.

### Task 4 — Fix the one color-asserting test
`test/widgets/screens/community_screen_test.dart` line ~68 asserts the stat-card dash colours equal `{AppColors.success, AppColors.primary}`. Its `createWidgetUnderTest` uses a **bare** `MaterialApp` (no `theme:`), so after migration `colorScheme.primary` would resolve to Flutter's *default* primary, not `AppColors.primary`. Fix: give `createWidgetUnderTest` a `theme: buildAppTheme()` so the registered `AppColorsExt.light()` + M3 light roles resolve to the canonical values. Then the existing assertion `{AppColors.success, AppColors.primary}` still holds (buildAppTheme's `colorScheme.primary == AppColors.primary`, and `context.colors.success == AppColors.success`). Import `package:app/theme/app_theme.dart` in the test.

### Task 5 — Dark-render smoke tests
Add one dark-theme render test per screen, asserting no exception + a sample Hebrew string. Use `theme: buildDarkAppTheme()`. Place in each screen's existing test file:
- `home_screen_test.dart`
- `community_screen_test.dart`
- `community_review_screen_test.dart`

Match each file's existing widget-construction helper (reuse `createWidgetUnderTest`/`buildSubject` with an added `theme` param where practical; otherwise inline a `MaterialApp(theme: buildDarkAppTheme(), home: …)`). For screens with required callbacks, pass no-ops. Avoid `pumpAndSettle` if the screen runs repeating animations.

### Task 6 — Verify: pub get
`flutter pub get` (from `app/`).

### Task 7 — Verify: analyze
`flutter analyze lib test` → 0 issues.

### Task 8 — Verify: affected tests
Run each, one at a time:
```
flutter test test/widgets/screens/home_screen_test.dart
flutter test test/widgets/screens/community_screen_test.dart
flutter test test/widgets/screens/community_review_screen_test.dart
```
All green.

### Task 9 — Verify: full suite
`flutter test` → all green.

### Task 10 — A6 spec index
Append a brief `#291` dark-mode note to the V-Spec/V-Art parenthetical of the Home, Community Hub, and Community Review rows in `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` (theme-aware color migration), leaving ✓/⚠/⬜ marks unchanged. If a row is absent, skip and note in PR body.

### Task 11 — A7 drift check
```
git fetch origin
git log origin/master..HEAD --oneline
```
Foreign commits → `STOPPED foreign commits on master`.

### Task 12 — A8 commit + push + PR
Commit footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`, body `Closes #291`, summary of the `AppColors.*`→`colorScheme.*`/`context.colors.*` migration across the three screens, the community-test theme fix, the three dark-render tests, and analyze/test results. Push branch; `gh pr create --base master`.

### Task 13 — A9 comment + release claim
```
gh issue comment 291 --repo Maortz/allergy-detector --body "PR opened: <PR_URL>"
gh issue edit 291 --repo Maortz/allergy-detector --remove-label agent-in-progress
```

## Return
`PR_OPENED <PR_URL>`
