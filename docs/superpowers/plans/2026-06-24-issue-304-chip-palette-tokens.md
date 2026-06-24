# Plan: Issue #304 — Use chipDetected*/chipCaution* palette tokens in allergen chips

**Date:** 2026-06-24  
**Issue:** #304  
**Branch:** `agent/issue-304-chip-palette-tokens`  
**Effort:** S (1 file, <1h)

## Context

`_buildContainsChip` and `_buildMayContainChip` in `app/lib/widgets/product_card.dart`
compute chip colours via `withValues(alpha:…)` arithmetic on base tokens (`avoid`, `warning`).
`AppColorsExt` already has dedicated semantic chip tokens tuned for both light and dark themes:

| Role            | Token             |
|-----------------|-------------------|
| detected bg     | `chipDetectedBg`  |
| detected border | `chipDetectedBorder` |
| detected text   | `chipDetectedFg`  |
| caution bg      | `chipCautionBg`   |
| caution border  | `chipCautionBorder` |
| caution text    | `chipCautionFg`   |

## Tasks

### Task 1 — Replace chip colours in product_card.dart

File: `app/lib/widgets/product_card.dart`

In `_buildContainsChip`:
- `color:` → `context.colors.chipDetectedBg`
- `border: Border.all(color: ...)` → `context.colors.chipDetectedBorder`
- text `color:` → `context.colors.chipDetectedFg`

In `_buildMayContainChip`:
- `color:` → `context.colors.chipCautionBg`
- `border: Border.all(color: ...)` → `context.colors.chipCautionBorder`
- text `color:` → `context.colors.chipCautionFg`

### Task 2 — Verify

```
flutter pub get
flutter analyze lib test
flutter test
```

### Task 3 — Update spec index

Update `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`:
- No screen row needs changes (product_card.dart is a widget, not a screen).
  This is a pure refactor — no spec or V-Art divergence is introduced.

### Task 4 — Drift check

```
git fetch origin && git log origin/master..HEAD --oneline
```

No foreign commits should appear.

### Task 5 — Commit + PR

Commit with message:
```
refactor(product-card): use chipDetected*/chipCaution* palette tokens in allergen chips

Replace ad-hoc alpha arithmetic on `avoid`/`warning` base tokens with the
dedicated `chipDetectedBg/Border/Fg` and `chipCautionBg/Border/Fg` semantic
tokens from `AppColorsExt`. These are already tuned for both light and dark
themes, making the chips dark-mode-aware without any extra logic.

Closes #304

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Then `gh pr create --base master`.

### Task 6 — Comment on issue + release claim

```
gh issue comment 304 --repo Maortz/allergy-detector --body "PR opened: <url>"
gh issue edit 304 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
