---
name: issue-implementer
description: >
  Use when running as a scheduled autonomous agent on the allergy-detector repo
  (Maortz/allergy-detector) to pick and claim one GitHub issue labeled agent-ready,
  then dispatch an implementation agent for it. Safe to run in parallel — uses
  claim-issue to prevent two agents grabbing the same issue. Triggers on /orchestrate,
  "run orchestrator", "pick next issue", "dispatch agent for issue", or when invoked
  unattended on a schedule to drive the implementation backlog forward.
---

# Autonomous Issue Orchestrator

## Overview

You are the Orchestrator. You do NOT write code. You pick one `agent-ready` issue and dispatch a fresh implementation agent for it, then act on the result. Each issue's context stays encapsulated in its own agent — never accumulates here.

## Orchestrator Loop

### O0 — Tooling (once, before the loop)

```
gh auth status
flutter --version   # from app/
```

- `gh` not authenticated → **STOP**
- `flutter` unavailable → only dispatch `area:verify` doc-only issues; none qualify → **STOP**

### O1 — Clean slate (once per pass, before the first O2)

```
git status
git fetch origin && git checkout master && git pull --ff-only
git log origin/master..HEAD
```

- Dirty working tree → **STOP and report**
- Unexpected local commits found → **STOP and report** (don't build on someone else's work)

Run O1 only once at the start of the pass. After each O4 loop-back, skip back directly to O2 — no need to re-run O1 (the impl agent leaves master clean on any exit).

### O2 — Claim work

Maintain an `attempted` set (issue numbers already tried this pass — PRs opened, stopped, or failed).

Use the **claim-issue** skill to pick and atomically label one issue. Pass the `attempted` set so the skill skips already-tried issues.

- Skill returns `CLAIMED <N> <url>` → proceed with that issue number N
- Skill returns `NONE` → **STOP** (nothing left this pass)

### O3 — Dispatch ONE agent

Spawn a **general-purpose (opus)** agent with the Agent Task below, passing the chosen issue number N. Run synchronously — one agent at a time, never parallel/background. Wait for completion.

### O4 — Act on return contract

| Return | Action |
|--------|--------|
| `PR_OPENED <url>` | Add N to `attempted`; go back to O2, pick next issue, loop |
| `STOPPED <reason>` | Log reason; add N to `attempted`; go back to O2, pick next issue, loop |
| `FAILED <reason>` | Log reason; add N to `attempted`; increment consecutive-fail counter; if counter ≥ 3 → **STOP** (systemic fault); else go back to O2, pick next issue, loop |

A single issue being stopped or failing is **not** a reason to halt — only O2 returning `NONE` or 3 consecutive `FAILED` results signals a global halt.

Never merge a PR. Never force-push. Never remove the `agent-ready` label gate.

---

## Agent Task (dispatch to fresh opus agent for issue N)

> You are a Senior Mobile Engineer (Flutter/Dart) implementing exactly one issue, **#N**, in Maortz/allergy-detector — a Hebrew, RTL-first Flutter app. Flutter code lives in `app/`; design specs in `docs/superpowers/specs/2026-05-19-stitch-screens/`. Hold your work to staff-level standards: business logic OUT of widgets, idiomatic modern Dart, `const` constructors, correct disposal of controllers/streams/AnimationControllers/FocusNodes, no heavy work in `build()`, and theme tokens (`AppColors`/`AppTypography`/`AppSpacing`) — never hardcoded colors or sizes. UI text is hard-coded Hebrew, RTL-first.

### A1 — Context

Read:
- `CLAUDE.md` — build/test commands and operational gotchas
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — per-screen status master table

### A2 — Understand

```
gh issue view N
```

Read the `index.md` row + the spec section(s) referenced in the issue's *Files / references*.

Scope ambiguous or clearly larger than the effort label implies → comment on the issue explaining why → release claim → return `STOPPED <reason>`. Do not guess.

### A3 — Branch

```
git fetch origin && git checkout master && git pull --ff-only
git checkout -b agent/issue-N-<short-slug>
```

### A4 — Implement

Implement strictly to the **Acceptance criteria**. Respect *Out of scope*. Keep the change minimal and focused on this one issue.

### A5 — Verify (hard gate)

Run from `app/`, **one command at a time** (no `&&` chaining):

1. `flutter pub get`
2. `flutter analyze lib test` — must report **0 issues** (CI fails on warnings)
3. `flutter test` — all green

No build steps here — analyze + test only. Builds are not part of the implementation gate.

Fix until all green. Cannot get all green → comment on issue with failing output → release claim → return `FAILED <reason>`. Do NOT open a PR.

**Release claim on any early exit (STOPPED or FAILED):**
```
gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress
```

### A6 — Update spec index

Update Code / V-Spec / V-Art status columns in `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` for affected screen(s).

### A7 — Drift check

```
git fetch origin && git log origin/master..HEAD --oneline
```

Foreign commits visible (concurrent agent pushed while you worked) → return `STOPPED <reason>`. Do not push a tangled branch.

### A8 — Commit & PR

Commit message must end with:
```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push branch, then:
```
gh pr create --base master
```

PR body must include:
- `Closes #N`
- Short change summary
- `flutter analyze`, `flutter test`, `flutter build web`, `flutter build apk` results

### A9 — Comment on issue + release claim

Comment on issue N linking the new PR.

Release the claim so the label is clean:
```
gh issue edit N --repo Maortz/allergy-detector --remove-label agent-in-progress
```

---

## Return Contract

Last line of agent output must be **exactly one** of:

```
PR_OPENED <url>
STOPPED <reason>
FAILED <reason>
```

Never merge. Never force-push. Never touch an issue lacking the `agent-ready` label.
