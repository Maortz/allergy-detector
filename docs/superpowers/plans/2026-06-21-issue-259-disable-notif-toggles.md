# Plan: Disable notification toggle buttons on App Preferences (issue #259)

Branch `agent/issue-259-disable-notif-toggles` is already created. Execution starts at the first code task.

## Context

`AppPreferencesScreen` (`app/lib/screens/app_preferences_screen.dart`) renders two
`SwitchListTile`s for notification preferences ("התראות על מוצרים חדשים", "עדכוני אלרגנים")
backed by `PreferencesService`. Push notifications are not implemented, so these toggles are
no-op/misleading. Issue #259 (UI-only) wants them disabled, greyed out, and accompanied by a
"coming soon" caption.

## Approach

- Disable both switches by passing `onChanged: null` (Flutter renders disabled switches greyed
  out automatically and `SwitchListTile.enabled` becomes false).
- Add a short caption "הודעות יהיו זמינות בקרוב" under the section, styled with theme tokens
  (`AppTypography.bodySm` + `AppColors.onSurfaceVariant`).
- Keep the persisted values being loaded/displayed (no functionality change to persistence;
  the toggles simply can't be changed). Remove the now-dead `_onNewProductsChanged` /
  `_onAllergenUpdatesChanged` handlers since they are no longer wired.
- Update the widget test: the previous toggle/persist test no longer applies (toggle is
  disabled); replace it with assertions that both switches are disabled (`onChanged == null`)
  and the caption is present. Keep default/restore tests (values still load & display).

## Tasks

### Task 1 — Make `_SwitchRow.onChanged` nullable and render disabled

In `app/lib/screens/app_preferences_screen.dart`:
- Change `_SwitchRow.onChanged` field type to `ValueChanged<bool>?` (nullable).
- `SwitchListTile` already accepts a nullable `onChanged`; passing null disables it.

### Task 2 — Disable both notification switches + add caption

- In `build`, pass `onChanged: null` to both `_SwitchRow`s.
- Add a caption widget at the end of the התראות section children (after the second switch),
  e.g. a `Padding` containing `Text('הודעות יהיו זמינות בקרוב', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant))`.
- Remove `_onNewProductsChanged` and `_onAllergenUpdatesChanged` (now unused).
  Keep `_loadPreferences` (values still load and display) — `_notifyNewProducts` /
  `_notifyAllergenUpdates` remain as read-only display state.

### Task 3 — Update widget tests

In `app/test/widgets/screens/app_preferences_screen_test.dart`:
- Keep "defaults both notification toggles to on when unset" and
  "restores persisted toggle state" (display still reflects persisted values).
- Replace "toggling a notification preference persists the new value" with a test asserting
  both switches are disabled (`onChanged` is null) and the caption text is shown.
- Keep the clear-cache test unchanged.

### Task 4 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

All must be: analyze 0 issues, tests green.

### Task 5 — A6 spec index update

Update the `AppPreferencesScreen` row in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` Code column note to mention #259
(notification toggles disabled + "coming soon" caption until push notifications are implemented).

### Task 6 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 7 — A8 commit + PR

Commit with footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
Push branch; `gh pr create --base master` with body `Closes #259`, change summary, analyze/test results.

### Task 8 — A9 comment + release

Comment on #259 linking PR. Release: `gh issue edit 259 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
