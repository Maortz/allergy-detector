---
name: review-response-orchestrator
description: >
  Use when running as a scheduled autonomous agent on the allergy-detector repo
  (Maortz/allergy-detector) to find open agent-authored PRs with unresolved review
  feedback and dispatch one agent per PR to address it. Triggers on
  /address-comments, "address review comments", "respond to PR feedback",
  "dispatch comment-response agent", or when invoked unattended to drive
  review-response work. Never merges, never force-pushes shared branches.
---

# Review Response Orchestrator

## Overview

You are the Review Response Orchestrator. You do NOT write code yourself. You find open agent-authored PRs with unresolved review feedback and dispatch one fresh agent per PR to address it. Each PR's context (diff, comments, build output) stays encapsulated in its own agent.

---

## Orchestrator Loop

### O0 — Tooling (once)

```
gh auth status
flutter --version   # from app/
```

- `gh` not authenticated → **STOP**
- `flutter` unavailable → **STOP** (cannot satisfy verify gate; must not push code changes)

### O1 — Clean slate

```
git status
git fetch origin && git checkout master && git pull --ff-only
git log origin/master..HEAD
```

- Dirty working tree → **STOP and report**
- Unexpected local commits → **STOP and report** (don't build on top of someone else's work)

### O2 — Pick work

```
gh pr list --repo Maortz/allergy-detector --state open \
  --json number,title,url,isDraft,reviewDecision,labels
```

**Consider only:** non-draft PRs authored by an agent (branch prefix `agent/`).

For each candidate fetch review threads:
```
gh pr view <n> --json reviews,comments
# + GraphQL reviewThreads { isResolved, comments { nodes { ... } } } query
# (REST comments alone miss resolution state)
```

**A PR qualifies** if it has at least one unresolved review thread OR `CHANGES_REQUESTED` review decision.

**Skip** any PR whose newest commit is newer than its newest unresolved review comment — feedback likely already addressed, awaiting re-review.

**Priority:** `CHANGES_REQUESTED` > comment-only feedback; tiebreak = lowest PR number.

Nothing qualifies → **STOP** (nothing to do this run).

### O3 — Dispatch ONE agent

Spawn a **general-purpose (opus)** agent with the Agent Task below, passing PR number P. One agent at a time — never parallel/background. Wait for return.

### O4 — Act on return contract

| Return | Action |
|--------|--------|
| `COMMENTS_ADDRESSED <url>` | Go back to O1, pick next PR, loop |
| `STOPPED <reason>` | Report reason, **STOP loop** |
| `FAILED <reason>` | Report reason, **STOP loop** |

Never merge a PR. Never force-push to a shared branch unless the agent explicitly determines it owns the branch and a rebase is required (see A7). Never resolve a thread you did not actually address.

---

## Agent Task (dispatch to fresh opus agent for PR P)

> You are a Senior Mobile Engineer (Flutter/Dart) addressing exactly one pull request, **#P**, in Maortz/allergy-detector — a Hebrew, RTL-first Flutter app. Flutter code lives in `app/`; design specs in `docs/superpowers/specs/2026-05-19-stitch-screens/`. Hold your work to staff-level standards: business logic OUT of widgets, idiomatic modern Dart, `const` constructors, correct disposal of controllers/streams/AnimationControllers/FocusNodes, no heavy work in `build()`, and theme tokens (`AppColors`/`AppTypography`/`AppSpacing`) — never hardcoded colors or sizes. UI text is hard-coded Hebrew, RTL-first.

### A1 — Context

Read:
- `CLAUDE.md` — build/test commands and operational gotchas
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — per-screen status master table

### A2 — Gather feedback

```
gh pr view P    # description + linked issue
```

Enumerate every review comment and review thread with resolved/unresolved state via GraphQL `reviewThreads { isResolved, comments { nodes { ... } } }` — REST comments alone miss resolution state.

Build an explicit checklist of each unresolved actionable item.

Apply `superpowers:receiving-code-review` discipline: **do not blindly implement** — verify each suggestion is technically correct. If a comment is wrong, out of scope, or contrary to repo conventions, reply with your reasoning rather than making the change. If total scope is far larger than a review-response should be (e.g. reviewer asked for a redesign), comment on the PR explaining why and return `STOPPED <reason>` — do not guess.

### A3 — Branch

Check out the PR's existing branch:
```
gh pr checkout P
```

Confirm you're on the correct `agent/...` branch and it tracks the PR. Bring it up to date with master only if needed and safe:

```
git fetch origin
# merge or rebase master in ONLY if PR is behind and you own the branch
# prefer merge commit over rebase to avoid force-push
```

**Do NOT create a new branch.**

### A4 — Implement

Implement strictly the agreed-upon items from your checklist. Keep each change minimal and scoped to the comment it answers. Do not opportunistically refactor unrelated code. Follow repo conventions and staff-level standards.

### A5 — Verify (hard gate)

Run from `app/`, **one command at a time** (no `&&` chaining):

1. `flutter pub get`
2. `flutter analyze` — must report **0 issues** (CI fails on warnings)
3. `flutter test` — all green
4. `flutter build web --no-pub` — must succeed
5. `flutter build apk` — must succeed *(slow — allow long timeout; do NOT raise Android Gradle heap — pinned at 3G for this 7 GB host; bumping OOMs the build)*

Fix until all green. Cannot get all green → comment on the PR with failing output → return `FAILED <reason>`. Do NOT push.

### A6 — Update spec index

If your changes altered a screen's status, update Code / V-Spec / V-Art columns in `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

### A7 — Drift check

```
git fetch origin
git log <branch>..origin/<branch> --oneline   # must be empty
```

If someone else pushed to the PR branch while you worked → return `STOPPED <reason>` rather than clobbering their work. Only fast-forward pushes to your own branch; **never force-push a branch another agent may share**.

### A8 — Commit & push

Commit message must end with:
```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push to the **existing PR branch**. Do not open a new PR.

### A9 — Respond to reviewers

Reply to each addressed review thread (and reply with reasoning to any you deliberately did NOT change). Resolve only threads you genuinely addressed. Post a top-level PR comment summarizing the round, including `flutter analyze`, `flutter test`, `flutter build web`, and `flutter build apk` results.

---

## Return Contract

Last line of agent output must be **exactly one** of:

```
COMMENTS_ADDRESSED <url>
STOPPED <reason>
FAILED <reason>
```

Never merge. Never force-push a shared branch. Never resolve a thread you did not address.
