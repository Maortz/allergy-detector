# Plan: Fix theme-switch highlight + stale state on Settings (#257)

Branch `agent/issue-257-theme-switch-highlight` is already created. Execution starts at the first code task.

## Root cause (investigated)

`SettingsScreen._buildAppearanceOption` computes `isSelected = widget.themeMode == mode`,
reading the **prop** directly (`app/lib/screens/settings_screen.dart` L425). Tapping an option
calls `_onAppearanceSelected` → `widget.onThemeModeChanged(mode)`, which bubbles to `MyApp`
(`main.dart` L59) where `setState` rebuilds `MaterialApp.home: AppShell`.

But `SettingsScreen` is **not** a bottom-nav tab — it is pushed as a `MaterialPageRoute` from
the drawer (`main_container.dart` `_navigateToUserDestination`, L215). When `MyApp` rebuilds its
`home`, the already-pushed Settings route keeps its **stale** `themeMode` prop, so the highlight
never updates (tapped button stays as-is / previous one doesn't clear), and the underlying tree
churning under the pushed route reads as "broken nav". This is the same stale-prop root for all
three reported symptoms.

The screen already uses an optimistic local-state mirror for the profile (`late UserProfile
_userProfile` + `didUpdateWidget` re-sync + setState on change). Applying the same idiomatic
pattern to the theme mode fixes the highlight immediately and independently of whether the
pushed route receives a new prop.

## Approach

Mirror `widget.themeMode` into `late ThemeMode _themeMode` local state:
- init in `initState`, re-sync in `didUpdateWidget` when `widget.themeMode` changes,
- `_onAppearanceSelected` sets `_themeMode` via `setState` (optimistic) **and** bubbles up via
  `onThemeModeChanged`,
- `_buildAppearanceOption` reads `_themeMode` (local) instead of `widget.themeMode`.

No navigation changes. Persistence + the live `MaterialApp` theme swap continue to happen in
`MyApp` exactly as before.

## Tasks

### Task 1 — Add local theme-mode state

In `app/lib/screens/settings_screen.dart` `_SettingsScreenState`:
- Add `late ThemeMode _themeMode;`
- In `initState`: `_themeMode = widget.themeMode;`
- In `didUpdateWidget`: if `oldWidget.themeMode != widget.themeMode` → `_themeMode = widget.themeMode;`

### Task 2 — Use local state for selection + optimistic update

- `_onAppearanceSelected(mode)`: guard `if (handler == null || mode == _themeMode) return;`
  then `setState(() => _themeMode = mode);` then `handler(mode);`
- `_buildAppearanceOption`: `final isSelected = _themeMode == mode;`

### Task 3 — Tests

In `app/test/widgets/screens/settings_screen_test.dart`:
- Add a test: tapping an inactive appearance option immediately marks it selected and clears the
  previously-selected one — assert via the option's resolved style (selected uses
  `colorScheme.onPrimaryContainer` + `FontWeight.w600`) **without** the parent feeding a new
  `themeMode` prop back (simulating the pushed-route case). Pump `themeMode: ThemeMode.system`,
  tap 'כהה', `pump()`, assert 'כהה' text style is now the selected weight and 'מערכת' is not.
- Keep the existing appearance tests (propagation + no-op on already-selected). The no-op test
  taps the already-selected option and asserts the callback count stays 0 — still valid against
  `_themeMode`.

### Task 4 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

analyze 0 issues; tests green.

### Task 5 — A6 spec index update

Update the Settings & Profile row note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to record #257 (appearance picker
now tracks selection via optimistic local `_themeMode` state — fixes stale highlight when
Settings is shown as a pushed route and MyApp rebuilds home without updating the route's prop).

### Task 6 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 7 — A8 commit + PR

Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; push; `gh pr create --base master`,
body `Closes #257`, root-cause summary, analyze/test results.

### Task 8 — A9 comment + release

Comment on #257 linking PR; `gh issue edit 257 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
