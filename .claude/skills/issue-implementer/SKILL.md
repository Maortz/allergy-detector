---
name: issue-implementer
description: >
  Use when running as a scheduled autonomous agent on the allergy-detector repo
  (Maortz/allergy-detector) to pick GitHub issues labeled agent-ready and dispatch
  implementation agents one at a time. Triggers on /orchestrate, "run orchestrator",
  "pick next issue", "dispatch agent for issue", or when invoked unattended on a
  schedule to drive the implementation backlog forward.
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

### O1 — Clean slate

```
git status
git fetch origin && git checkout master && git pull --ff-only
git log origin/master..HEAD
```

- Dirty working tree → **STOP and report**
- Unexpected local commits found → **STOP and report** (don't build on someone else's work)

### O2 — Pick work

```
gh issue list --repo Maortz/allergy-detector --state open --label agent-ready \
  --json number,title,labels,url
```

**Priority order:**
1. Phase: `phase:2-fix` > `phase:3-build` > `phase:4-verify`
2. Effort within phase: `effort:S` > `effort:M` > `effort:L`
3. Tiebreak: lowest issue number

**Skip** any issue with an open PR already referencing it:
```
gh pr list --state open --search "<number>"
```

Nothing qualifies → **STOP** (nothing to do this run)

### O3 — Dispatch ONE agent

Spawn a **general-purpose (opus)** agent with the Agent Task below, passing the chosen issue number N. Run synchronously — one agent at a time, never parallel/background. Wait for completion.

### O4 — Act on return contract

| Return | Action |
|--------|--------|
| `PR_OPENED <url>` | Go back to O1, pick next issue, loop |
| `STOPPED <reason>` | Report reason, **STOP loop** |
| `FAILED <reason>` | Report reason, **STOP loop** |

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

Scope ambiguous or clearly larger than the effort label implies → comment on the issue explaining why → return `STOPPED <reason>`. Do not guess.

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
2. `flutter analyze` — must report **0 issues** (CI fails on warnings)
3. `flutter test` — all green
4. `flutter build web --no-pub` — must succeed
5. `flutter build apk` — must succeed *(slow — allow long timeout; do NOT raise Android Gradle heap — pinned at 3G for this 7 GB host; bumping OOMs the build)*

Fix until all green. Cannot get all green → comment on issue with failing output → return `FAILED <reason>`. Do NOT open a PR.

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

### A9 — Comment on issue

Comment on issue N linking the new PR.

---

## Return Contract

Last line of agent output must be **exactly one** of:

```
PR_OPENED <url>
STOPPED <reason>
FAILED <reason>
```

Never merge. Never force-push. Never touch an issue lacking the `agent-ready` label.
