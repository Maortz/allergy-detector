# Plan: Remove hardcoded Week-Tip / Active-Discussion cards from Community screen (#264)

Branch `agent/issue-264-remove-community-insight-cards` is already created. Execution starts at the first code task.

## Context

`CommunityScreen` (`app/lib/screens/community_screen.dart`) renders a `_buildTipsSection()`
(L454) containing two hardcoded `_InsightCard`s — "טיפ השבוע" (L463) and "דיון פעיל" (L473) —
with static placeholder copy. It is invoked from `build` at L231 (preceded by a
`SizedBox(height: AppSpacing.lg)` at L230). The `_InsightCard` class (L532) is used **only**
by `_buildTipsSection`, so it becomes dead after removal.

Two CommunityScreen widget tests assert this copy:
`app/test/widgets/screens/community_screen_test.dart` CH9 (~L119) and CH10 (~L132).
The standalone `WeeklyTipScreen` / `ActiveDiscussionScreen` (tier3 tests) are SEPARATE widgets
and must NOT be touched — their tests stay.

## Tasks

### Task 1 — Remove the tips section from the build

In `app/lib/screens/community_screen.dart`:
- Remove the `_buildTipsSection()` call at L231 and the preceding
  `const SizedBox(height: AppSpacing.lg)` (L230) so no double spacing is left before the
  trailing `SizedBox(height: 100)`.

### Task 2 — Remove now-dead widgets

- Delete the `_buildTipsSection()` method (L454–L479).
- Delete the `_InsightCard` class (L529–L587) — confirm no other references first
  (`grep -n "_InsightCard" app/lib/screens/community_screen.dart`).

### Task 3 — Update tests

In `app/test/widgets/screens/community_screen_test.dart`:
- Delete the CH9 test ("displays tips section with corrected copy + icon").
- Delete the CH10 test ("displays active discussion with corrected copy + icon").
- Leave all other tests untouched.
- Do NOT touch `tier3_user_destinations_test.dart` (standalone tip/discussion screens).

### Task 4 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

analyze 0 issues; tests green.

### Task 5 — A6 spec index update

Update the Community Hub row note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to record #264 (removed the
hardcoded טיפ השבוע / דיון פעיל insight cards + `_InsightCard` — no dynamic backing data;
standalone WeeklyTip/ActiveDiscussion screens unaffected).

### Task 6 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 7 — A8 commit + PR

Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; push; `gh pr create --base master`,
body `Closes #264`, summary, analyze/test results.

### Task 8 — A9 comment + release

Comment on #264 linking PR; `gh issue edit 264 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
