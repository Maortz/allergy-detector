---
name: issue-implementer
description: >
  Inner implementation skill for one GitHub issue in Maortz/allergy-detector.
  Contains two sequential briefs: Planning Agent Brief (opus — writes the plan)
  and Execution Agent Brief (sonnet — follows the plan). Invoked by the
  issue-implementer agent, which spawns one opus agent for planning then one
  sonnet agent for execution, each reading the relevant section of this skill.
---

## Planning Agent Brief (opus agent — issue N)

> You are a Senior Mobile Engineer (Flutter/Dart) planning the implementation of exactly one issue, **#N**, in Maortz/allergy-detector — a Hebrew, RTL-first Flutter app. Flutter code lives in `app/`; design specs in `docs/superpowers/specs/2026-05-19-stitch-screens/`. You do NOT write code yet — you produce a detailed implementation plan that a separate execution agent will follow exactly.

### A1 — Context

Read:
- `CLAUDE.md` — build/test commands and operational gotchas
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — per-screen status master table

### A2 — Understand

```
gh issue view N
```

Read the `index.md` row + the spec section(s) referenced in the issue's *Files / references*.

Scope ambiguous or clearly larger than the effort label implies → comment on the issue explaining why → release claim:
```
gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress
```
→ return `STOPPED <reason>`. Do not guess.

### A3 — Branch

```
git fetch origin && git checkout master && git pull --ff-only
git checkout -b agent/issue-N-<short-slug>
```

### A4 — Write plan

Use the **superpowers:writing-plans** skill to produce a complete implementation plan. The plan must:

- Follow the writing-plans skill exactly (header, file structure, bite-sized TDD tasks with real code, no placeholders)
- Cover: branch is already created (A3 done), execution starts at the first code task
- Include all verify steps: `flutter pub get`, `flutter analyze lib test` (0 issues), `flutter test` (all green) — one command at a time, no `&&` chaining
- Include A6 (update `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` Code/V-Spec/V-Art columns for affected screens)
- Include A7 drift check: `git fetch origin && git log origin/master..HEAD --oneline` — STOPPED if foreign commits visible
- Include A8 commit + PR (body: `Closes #N`, change summary, analyze/test/build results; commit footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`)
- Include A9: comment on issue N linking PR; release claim: `gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress`
- Note staff-level standards throughout: business logic OUT of widgets, idiomatic Dart, `const` constructors, correct disposal, theme tokens (`AppColors`/`AppTypography`/`AppSpacing`), Hebrew RTL-first

Save to: `docs/superpowers/plans/YYYY-MM-DD-issue-N-<short-slug>.md`

Cannot produce a complete, non-placeholder plan → release claim → return `FAILED <reason>`.

### Planning Agent Return Contract

Last line must be **exactly one** of:

```
PLAN_READY agent/issue-N-<short-slug> docs/superpowers/plans/YYYY-MM-DD-issue-N-<short-slug>.md
STOPPED <reason>
FAILED <reason>
```

---

## Execution Agent Brief (sonnet agent — issue N, branch B, plan P)

> You are a Senior Mobile Engineer (Flutter/Dart) executing an implementation plan for issue **#N** in Maortz/allergy-detector. The planning agent has already created branch **B** and saved the plan at **P**. Execute the plan task-by-task inline — do NOT spawn further sub-agents.

### E1 — Check out branch

```
git fetch origin && git checkout B
```

Verify the plan file exists at path P. If branch or plan missing → release claim:
```
gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress
```
→ return `FAILED branch or plan not found`.

### E2 — Execute plan

Read plan P. Execute all tasks task-by-task inline in this session. Follow the plan exactly — no improvisation, no scope creep. Do not spawn sub-agents.

If you hit a blocker that cannot be resolved without human input → release claim → return `STOPPED <reason>`.

If verify (analyze/test) cannot be made green after exhausting plan steps → comment on issue N with failing output → release claim → return `FAILED <reason>`.

**Release claim on any early exit:**
```
gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress
```

### E3 — After plan execution completes

The plan covers all remaining steps (A6 spec update, A7 drift check, A8 commit+PR, A9 comment+release). Confirm each was executed. If the plan omitted any step, execute it now:

- **A6**: Update Code / V-Spec / V-Art columns in `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` for affected screens.
- **A7**: `git fetch origin && git log origin/master..HEAD --oneline` — foreign commits → `STOPPED <reason>`.
- **A8**: Push branch, `gh pr create --base master`. PR body: `Closes #N`, change summary, analyze/test/build results. Commit footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **A9**: Comment on issue N linking PR. Release claim: `gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress`.

### Execution Agent Return Contract

Last line must be **exactly one** of:

```
PR_OPENED <url>
STOPPED <reason>
FAILED <reason>
```

Never merge. Never force-push. Never touch an issue lacking the `agent-ready` label.
