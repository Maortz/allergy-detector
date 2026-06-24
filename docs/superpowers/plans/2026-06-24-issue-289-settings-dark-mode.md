# Implementation Plan — Issue #289: Migrate SettingsScreen to theme-aware colors (dark mode)

**Issue:** Maortz/allergy-detector#289 (part of #258)
**Branch:** `agent/issue-289-settings-dark-mode` (already created — execution starts at the first code task)
**Effort:** M

## Goal

`app/lib/screens/settings_screen.dart` uses non-adaptive literals (`Colors.white`, `Colors.black.withValues(...)`) and light-only `AppColors.*` static consts that do not respond to dark mode. Replace each with the appropriate theme-aware accessor so the screen renders correctly in both light and dark themes. The `AppColorsExt` foundation (light + dark) is already merged (#300) and registered on both `buildAppTheme()` / `buildDarkAppTheme()`.

## Mapping rules (from issue #289)

- `Colors.white` (surface/card bg) → `Theme.of(context).colorScheme.surfaceContainerLowest`
- `Colors.black.withValues(alpha: x)` (shadow) → `Theme.of(context).colorScheme.onSurface.withValues(alpha: x)`
- M3 role consts (`AppColors.surfaceContainer`, `onSurface`, `onSurfaceVariant`, `primary`, `onPrimary`, `primaryFixed`, `onPrimaryFixed`, `surfaceContainerLow`, `surfaceContainerLowest`, `surfaceContainerHigh`, `outlineVariant`) → `Theme.of(context).colorScheme.<role>`
- Semantic status tokens (`AppColors.safeBackground/safeText`, `cautionBackground/cautionText`, `avoidBackground/avoidText`) → `context.colors.<token>` (these exist on `AppColorsExt`, tuned for both themes)
- Do **not** replace with other `AppColors.*` static consts — they are light-only.

**Value-parity note (keeps existing tests green):** in `AppColorsExt._light`, `safeBackground/cautionBackground/avoidBackground` and their text pairs equal the corresponding `AppColors.*` consts. The widget-test harness renders in the default light theme, so existing assertions like `expect(iconBgColorFor(...), AppColors.safeBackground)` still hold after migrating to `context.colors.safeBackground`. M3 roles likewise resolve to the same light values via `buildAppTheme()`/default `ThemeData`. Where a test uses a bare `MaterialApp` (default `ThemeData`, no `AppColorsExt` registered), `context.colors` falls back to `AppColorsExt.light()` — same values.

## Structural changes required

Several helpers are `const` or take no `context`. To make them theme-aware:

1. `_personPlaceholder()` — currently `const CircleAvatar(... AppColors.primaryFixed / onPrimaryFixed)`. Change signature to `_personPlaceholder(BuildContext context)`, drop `const`, use `Theme.of(context).colorScheme.primaryContainer` (bg) + `onPrimaryContainer` (icon). Update the two call sites in `_buildAvatar` (which already has `context` via the closure / `build`). Note `_buildAvatar` is called from `_buildProfileSection` with the screen's `context` — pass it through: change `_buildAvatar()` → `_buildAvatar(context)` and thread `context` to `_personPlaceholder`.
2. `_buildProfileSection()` → `_buildProfileSection(BuildContext context)` (already called from `build` which has `context`). Use `colorScheme.surfaceContainerLowest` for the card and the inner avatar ring border, `colorScheme.onSurface.withValues(...)` for shadows, `colorScheme.primary`/`onPrimary` for the edit FAB (drop its `const BoxDecoration`/`const Icon`), `colorScheme.onSurface`/`onSurfaceVariant`/`primary` for the texts.
3. `_buildFilterSection()` → `(BuildContext context)`: card bg/shadow, `primaryFixed`→`colorScheme.primaryContainer` icon chip bg, `primary` icon, text colors.
4. `_buildFilterOption(...)` already receives `context`-free but is called inside `build`'s tree — change to `_buildFilterOption(BuildContext context, String label, ProductFilterLevel level)`. Map the `(background, foreground)` switch to `context.colors.avoidBackground/avoidText`, `cautionBackground/cautionText`, `safeBackground/safeText`; unselected bg → `colorScheme.surfaceContainerLowest`, unselected border → `colorScheme.outlineVariant`, unselected text → `colorScheme.onSurfaceVariant`.
5. `_buildNavMenu()` → `(BuildContext context)`: card bg/shadow. Update the per-tile `iconBgColor`/`iconColor` args to theme-aware values: medical/primaryFixed → `colorScheme.primaryContainer` + `colorScheme.primary`; neutral surfaceContainerLow → `colorScheme.surfaceContainerHighest` + `colorScheme.onSurfaceVariant`; safe → `context.colors.safeBackground` + `context.colors.safeText`; caution → `context.colors.cautionBackground` + `context.colors.cautionText`.
6. `_buildNavTile(...)` — `iconBgColor`/`iconColor` already passed as args; its label text uses `AppColors.onSurface` and trailing chevron uses `AppColors.onSurfaceVariant`. Add `BuildContext context` is **not** needed if we pass colors in — but the label/chevron need theme. Simplest: add `required BuildContext context` is avoidable since `_buildNavTile` is a method with access to `this.context`? No — `State.context` is available inside any instance method. Use `Theme.of(context)` directly (the `State`'s `context`) for label (`onSurface`) and chevron (`onSurfaceVariant`). Drop `const` on the chevron Icon.
7. `_buildDivider()` — `const Divider(... AppColors.surfaceContainerHigh)`. Use `State.context`: `Divider(color: Theme.of(context).colorScheme.surfaceContainerHigh, ...)`, drop `const`.
8. `build()` Scaffold/AppBar: `AppColors.surfaceContainer` → `colorScheme.surfaceContainer`; AppBar title `AppColors.onSurface` → `colorScheme.onSurface`.
9. `_buildLogoutButton()` → `(BuildContext context)`: `avoidBackground`/`avoidText` → `context.colors.avoidBackground`/`context.colors.avoidText` (bg, fg, border, label). Drop `const` on the `BorderSide` (now runtime color).
10. `_ProfileSkeleton` (separate `StatelessWidget`, has its own `build(context)`): `AppColors.surfaceContainerLowest` → `Theme.of(context).colorScheme.surfaceContainerLowest`; `AppColors.onSurface.withValues(...)` → `colorScheme.onSurface.withValues(...)`. Drop `const` on the decoration as needed.

Since `_buildNavTile` / `_buildDivider` are instance methods, they can use `this.context` (the `State`'s context) directly — no need to thread a parameter. For the builder methods invoked from `build`, pass the `context` from `build` explicitly for clarity, OR rely on `State.context`. **Decision: use `State.context` (i.e. `Theme.of(context)` / `context.colors` referencing the State's `context` field) throughout** — it is always valid after mount and avoids churn in call sites. Keep method signatures unchanged except where a `const` must be dropped. This minimizes diff and risk.

> Implementation note: prefer reading `final colorScheme = Theme.of(context).colorScheme;` at the top of each builder that needs ≥2 roles, mirroring the existing `_buildAppearanceSection` / `_buildAppearanceOption` pattern already in the file.

## Import cleanup

After migration, check whether `AppColors` is still referenced. If no `AppColors.*` remain, remove `import '../theme/app_colors.dart';` **unless** `context.colors` (the `AppColorsContext` extension) lives in that same file — it does (`app_colors.dart` defines both `AppColors` and the `AppColorsContext` extension). So the import must stay (it provides `context.colors`). Keep it.

---

## Task 1 — Migrate `build()` Scaffold + AppBar

In `build`, add `final colorScheme = Theme.of(context).colorScheme;` at the top. Replace:
- `backgroundColor: AppColors.surfaceContainer` (Scaffold) → `colorScheme.surfaceContainer`
- AppBar title color `AppColors.onSurface` → `colorScheme.onSurface`
- AppBar `backgroundColor: AppColors.surfaceContainer` → `colorScheme.surfaceContainer`
- `surfaceTintColor: Colors.transparent` → keep (`Colors.transparent` is theme-agnostic and correct).

## Task 2 — Migrate avatar helpers

- `_personPlaceholder()`: drop `const`, use `final colorScheme = Theme.of(context).colorScheme;` then `backgroundColor: colorScheme.primaryContainer`, icon `color: colorScheme.onPrimaryContainer`.

## Task 3 — Migrate `_buildProfileSection`

- Card `color: Colors.white` → `colorScheme.surfaceContainerLowest`
- Card shadow `Colors.black.withValues(alpha: 0.05)` → `colorScheme.onSurface.withValues(alpha: 0.05)`
- Avatar ring `border: Border.all(color: Colors.white, width: 4)` → `colorScheme.surfaceContainerLowest`
- Avatar ring shadow `Colors.black.withValues(alpha: 0.1)` → `colorScheme.onSurface.withValues(alpha: 0.1)`
- Edit FAB: drop `const` on `BoxDecoration`/`Icon`; `color: AppColors.primary` → `colorScheme.primary`; icon `AppColors.onPrimary` → `colorScheme.onPrimary`
- Name text `AppColors.onSurface` → `colorScheme.onSurface`
- Email text `AppColors.onSurfaceVariant` → `colorScheme.onSurfaceVariant`
- "ערוך פרופיל" icon + label `AppColors.primary` → `colorScheme.primary` (drop `const` on the icon)

## Task 4 — Migrate `_buildFilterSection`

- Card bg/shadow as Task 3.
- Icon chip `color: AppColors.primaryFixed` → `colorScheme.primaryContainer`; icon `AppColors.primary` → `colorScheme.primary` (drop `const` on the Icon)
- Title `AppColors.onSurface` → `colorScheme.onSurface`; subtitle `AppColors.onSurfaceVariant` → `colorScheme.onSurfaceVariant`

## Task 5 — Migrate `_buildFilterOption`

- `(background, foreground)` switch → `context.colors.avoidBackground`/`avoidText`, `cautionBackground`/`cautionText`, `safeBackground`/`safeText`
- Unselected bg `Colors.white` → `Theme.of(context).colorScheme.surfaceContainerLowest`
- Unselected border `AppColors.outlineVariant` → `colorScheme.outlineVariant`
- Unselected text `AppColors.onSurfaceVariant` → `colorScheme.onSurfaceVariant`

## Task 6 — Migrate `_buildNavMenu` + `_buildNavTile` + `_buildDivider`

`_buildNavMenu`:
- Card bg `Colors.white` → `colorScheme.surfaceContainerLowest`; shadow as Task 3.
- Per-tile color args:
  - "נהל אלרגיות": `primaryFixed`→`colorScheme.primaryContainer`, `primary`→`colorScheme.primary`
  - "העדפות אפליקציה": `surfaceContainerLow`→`colorScheme.surfaceContainerHighest`, `onSurfaceVariant`→`colorScheme.onSurfaceVariant`
  - "היסטוריית תרומות": `AppColors.safeBackground`→`context.colors.safeBackground`, `AppColors.safeText`→`context.colors.safeText`
  - "מרכז עזרה": `AppColors.cautionBackground`→`context.colors.cautionBackground`, `AppColors.cautionText`→`context.colors.cautionText`
  - "נהל מותגים" (admin): `surfaceContainerLow`→`colorScheme.surfaceContainerHighest`, `onSurfaceVariant`→`colorScheme.onSurfaceVariant`
  - "אודות": `surfaceContainerLow`→`colorScheme.surfaceContainerHighest`, `onSurfaceVariant`→`colorScheme.onSurfaceVariant`

`_buildNavTile`: label `AppColors.onSurface` → `Theme.of(context).colorScheme.onSurface`; chevron `AppColors.onSurfaceVariant` → `colorScheme.onSurfaceVariant` (drop `const` on the Icon). Uses the `State`'s `context`.

`_buildDivider`: drop `const`; `AppColors.surfaceContainerHigh` → `Theme.of(context).colorScheme.surfaceContainerHigh`.

## Task 7 — Migrate `_buildLogoutButton`

- `backgroundColor: AppColors.avoidBackground` → `context.colors.avoidBackground`
- `foregroundColor: AppColors.avoidText` → `context.colors.avoidText`
- `side: const BorderSide(color: AppColors.avoidText, ...)` → drop `const`, `context.colors.avoidText`
- label `AppColors.avoidText` → `context.colors.avoidText`

## Task 8 — Migrate `_ProfileSkeleton`

In its `build`: add `final colorScheme = Theme.of(context).colorScheme;`. Card `AppColors.surfaceContainerLowest` → `colorScheme.surfaceContainerLowest`; shadow `AppColors.onSurface.withValues(...)` → `colorScheme.onSurface.withValues(...)`. Drop `const` on the decoration; the children list can stay `const`.

## Task 9 — Verify no stray literals

Run:
```
grep -nE "Colors\.(white|black)|Color\(0x|AppColors\." app/lib/screens/settings_screen.dart
```
Expected remaining matches: only `Colors.transparent` (theme-agnostic, allowed) and the kept `import '../theme/app_colors.dart';` line (provides `context.colors`). No `Colors.white`, `Colors.black`, `Color(0x...)`, or `AppColors.<token>` field references should remain.

## Task 10 — Add a dark-mode widget test

Append a new group to `app/test/widgets/screens/settings_screen_test.dart` that pumps the screen under `buildDarkAppTheme()` and asserts it renders without exceptions and that a sample surface/text resolves to dark-theme values. Import `package:app/theme/app_theme.dart` and `package:app/theme/app_colors.dart` (already imported).

```dart
testWidgets('renders under dark theme without overflow/exception and uses '
    'dark surface tokens', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDarkAppTheme(),
      home: SettingsScreen(
        userProfile: testProfile,
        allergens: testAllergens,
        onProfileUpdated: (_) {},
        currentNavIndex: 0,
        onNavIndexChanged: (_) {},
      ),
    ),
  );

  expect(tester.takeException(), isNull);
  // Core Hebrew content still renders.
  expect(find.text('התנתק מהחשבון'), findsOneWidget);
  expect(find.text('נהל אלרגיות'), findsOneWidget);

  // The logout button picks up the DARK avoid tokens (not the light ones),
  // proving the migration is theme-aware.
  final button = tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'התנתק מהחשבון'),
  );
  final bg = button.style?.backgroundColor?.resolve(<WidgetState>{});
  expect(bg, AppColorsExt.dark().avoidBackground);
  expect(bg, isNot(AppColors.avoidBackground));
});
```

## Task 11 — Verify: pub get

From `app/`:
```
flutter pub get
```

## Task 12 — Verify: analyze

From `app/`:
```
flutter analyze lib test
```
Expect **0 issues**.

## Task 13 — Verify: settings test file

From `app/`:
```
flutter test test/widgets/screens/settings_screen_test.dart
```
Expect all green (existing light-mode assertions hold via value parity; new dark test passes).

## Task 14 — Verify: full suite

From `app/`:
```
flutter test
```
Expect all green.

## Task 15 — A6 spec index

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` row 15 (Settings & Profile). This change is a dark-mode color migration, not a spec/art parity change — the V-Spec and V-Art columns are unaffected. Add a brief parenthetical to the Settings row's existing note documenting the #289 dark-mode migration (theme-aware colors), without altering the ✓/⬜ status marks. Keep the edit minimal and factual.

## Task 16 — A7 drift check

```
git fetch origin
```
```
git log origin/master..HEAD --oneline
```
Only this branch's commit(s) should appear. Foreign commits → `STOPPED foreign commits on master`.

## Task 17 — A8 commit + push + PR

```
git add app/lib/screens/settings_screen.dart app/test/widgets/screens/settings_screen_test.dart docs/superpowers/specs/2026-05-19-stitch-screens/index.md docs/superpowers/plans/2026-06-24-issue-289-settings-dark-mode.md
```
```
git commit -m "feat(settings): migrate SettingsScreen to theme-aware colors for dark mode

Replaces Colors.white / Colors.black.withValues / light-only AppColors.*
literals with colorScheme.* roles and context.colors.* semantic tokens so
the screen adapts to dark mode. Adds a dark-theme render test.

Closes #289

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```
```
git push -u origin agent/issue-289-settings-dark-mode
```
```
gh pr create --repo Maortz/allergy-detector --base master --title "feat(settings): dark-mode theme-aware colors for SettingsScreen (#289)" --body "<body>"
```

PR body:
```
Closes #289 (part of #258)

## Summary
Migrates `settings_screen.dart` off non-adaptive literals so it renders correctly in dark mode:
- `Colors.white` card/surface backgrounds → `colorScheme.surfaceContainerLowest`
- `Colors.black.withValues(...)` shadows → `colorScheme.onSurface.withValues(...)`
- light-only `AppColors.*` M3 roles → `colorScheme.*`
- semantic status tints (safe/caution/avoid) → `context.colors.*` (theme-aware `AppColorsExt`)

`const` was dropped on the handful of widgets whose colors are now resolved at runtime. Light-mode appearance is unchanged (value parity between `AppColors.*` and `AppColorsExt.light()` + M3 light roles), so all existing widget tests still pass.

## Test
Adds a dark-theme render test asserting no exceptions and that the logout button resolves to `AppColorsExt.dark().avoidBackground` (proving theme-awareness).

## Verification
- `flutter analyze lib test` — 0 issues
- `flutter test` — all green
```

## Task 18 — A9 comment + release claim

```
gh issue comment 289 --repo Maortz/allergy-detector --body "PR opened: <PR_URL>"
```
```
gh issue edit 289 --repo Maortz/allergy-detector --remove-label agent-in-progress
```

## Return

`PR_OPENED <PR_URL>`
