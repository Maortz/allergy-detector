# Plan: Show profile picture on profile view screen (issue #260)

Branch `agent/issue-260-profile-avatar-view` is already created. Execution starts at the first code task.

## Context

The user avatar is stored as a base64 JPEG string in `UserProfile.avatarData`
(`app/lib/models/user_profile.dart`). `ProfileEditSheet`
(`app/lib/widgets/profile_edit_sheet.dart` ~L152) renders it via
`Image.memory(base64Decode(_avatarData!))` inside a `ClipOval`, falling back to an
initial/placeholder. But the profile *view* (`SettingsScreen._buildProfileSection`,
`app/lib/screens/settings_screen.dart` ~L159) hard-codes a `const CircleAvatar` showing
only an `Icons.person` placeholder — it never reads `_userProfile.avatarData`. So a saved
avatar is invisible on the profile view (issue #260).

Saving already updates the view: `_openProfileEdit` does
`setState(() => _userProfile = result)` (L77), so once the avatar widget reads
`_userProfile.avatarData`, acceptance criterion 3 (immediate reflection after save) is met.

## Approach

In `_buildProfileSection`, replace the `const CircleAvatar` with a 88px circular avatar that:
- renders `Image.memory(base64Decode(_userProfile.avatarData!))` in a `ClipOval` with
  `BoxFit.cover` when `avatarData` is non-null and non-empty;
- otherwise shows the existing `Icons.person` placeholder on `AppColors.primaryFixed`.

Use a private helper widget/method so the build stays readable. Add `dart:convert` import.
Keep the 96px outer ring + edit-badge stack unchanged. No model or callback changes.

## Tasks

### Task 1 — Render avatarData on the profile view

In `app/lib/screens/settings_screen.dart`:
- Add `import 'dart:convert';` at the top.
- Replace the `const CircleAvatar(... Icons.person ...)` child of the 96x96 ring `Container`
  with a helper that branches on `_userProfile.avatarData`:
  - non-null & not empty → `ClipOval(child: Image.memory(base64Decode(data), width: 88, height: 88, fit: BoxFit.cover))` inside a `CircleAvatar(radius: 44, backgroundColor: AppColors.primaryFixed)` (or a sized ClipOval) — match the edit-sheet visual.
  - else → the current person-icon `CircleAvatar` placeholder.

Extract the branch into a `Widget _buildAvatar()` method on the State for readability.

### Task 2 — Add a widget test

In `app/test/widgets/screens/settings_screen_test.dart`:
- Add a test: when `testProfile` has a valid base64 `avatarData`, the profile view renders an
  `Image` (and no `Icons.person`).
- Add a test: when `avatarData` is null, the `Icons.person` placeholder renders.
- Use a tiny valid in-memory PNG/JPEG bytes → base64 for the avatar fixture
  (avoid network/asset). A 1x1 transparent PNG byte list is sufficient.
- Pump with `tester.pump()` only — settings screen has no repeating animations, but avoid
  decode-on-network; `Image.memory` needs a frame: use `await tester.pump()` and assert on
  the `Image` widget presence (not pixel decode).

### Task 3 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

analyze 0 issues; tests green.

### Task 4 — A6 spec index update

Update the Settings & Profile row note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to mention #260 (profile view now
renders the saved `avatarData`, placeholder fallback otherwise).

### Task 5 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 6 — A8 commit + PR

Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; push; `gh pr create --base master`,
body `Closes #260`, summary, analyze/test results.

### Task 7 — A9 comment + release

Comment on #260 linking PR; `gh issue edit 260 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
