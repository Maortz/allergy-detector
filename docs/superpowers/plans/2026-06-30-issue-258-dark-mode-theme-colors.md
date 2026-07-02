# Plan: Issue #258 — Many UI elements/borders do not adapt to dark mode

Branch: `agent/issue-258-dark-mode-theme-colors` (already created)

## Root cause

Dark-mode infrastructure exists (`buildDarkAppTheme()`, `AppColorsExt.light/dark`,
`AppDarkColors`). Most widgets already read colours via the theme (`context.colors`,
`Theme.of(context).colorScheme`). The remaining dark-mode breakage comes from a small
set of widgets that still reference the **static, light-only `AppColors.X` constants**
(and one `Colors.orange` literal). These never change between light and dark, so they
render light-mode colours on dark surfaces.

Additionally, both `ColorScheme(...)` constructors in `app_theme.dart` only populate a
subset of M3 roles — `onSurfaceVariant`, `primaryFixed`, `onPrimaryFixed`, and the
`surfaceContainerLowest/Low/Container/High` roles are missing — so migrating widgets to
`colorScheme.X` requires completing the schemes first (otherwise those roles fall back
to Flutter's fixed-grey defaults).

## Tasks

### T1 — Complete both ColorSchemes (`lib/theme/app_theme.dart`)
Add the missing roles to the light scheme (from `AppColors`) and the dark scheme (from
`AppDarkColors`; `primaryFixed`/`onPrimaryFixed` use the light `AppColors` values since
M3 "fixed" colours are intentionally constant across brightness):
`onSurfaceVariant`, `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`,
`surfaceContainerHigh`, `primaryFixed`, `onPrimaryFixed`.

### T2 — Migrate widget colour references (6 files)
Replace static `AppColors.X` → `Theme.of(context).colorScheme.X`; `AppColors.avoid`
is not needed (only comment mentions remain). Remove `const` where a widget now reads a
runtime colour.
- `lib/widgets/allergen_card.dart`
- `lib/widgets/brand_card.dart`
- `lib/widgets/state_view.dart`
- `lib/utils/app_toast.dart` (`info()` → `colorScheme.primary/onPrimary`)
- `lib/screens/admin_destination_screen.dart`
- `lib/screens/drawer_user_screen.dart`

### T3 — Literal fix (`lib/main.dart`)
`_buildErrorScreen` offline icon `Colors.orange` → `context.colors.warning`
(theme-aware: light `#FF9800` / dark `#FFB74D`). Add `theme/app_colors.dart` import.
`all_clear_banner.dart`'s `Colors.white` check icon is left as-is — it is an intentional
on-colour over a saturated green circle, correct in both themes.

### T4 — Update tests that pumped widgets in a bare theme and asserted `AppColors.X`
Wrap with `theme: buildAppTheme()` so the light colorScheme roles equal the constants:
- `test/widgets/allergen_card_test.dart` (outline icon, primary badge)
- `test/allergen_card_test.dart` (selected border `#00478d`)
- `test/app_toast_test.dart` (info toast `primary` — pass theme to `pumpHost`)
- `test/widgets/screens/drawer_user_screen_test.dart` (`pumpDrawer` scaffold bg)

### T5 — Verify
`flutter pub get`; `flutter analyze lib test` (0 issues); `flutter test` (green).

### T6 — Spec index, drift check, commit + PR, issue comment + release claim.
