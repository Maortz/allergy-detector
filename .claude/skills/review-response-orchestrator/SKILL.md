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
/sdks/flutter/bin/flutter --version   # Flutter lives at /sdks/flutter/bin/flutter
```

- `gh` not authenticated → **STOP**
- `flutter` unavailable → **STOP** (cannot satisfy verify gate; must not push code changes)

Note: Flutter is at `/sdks/flutter/bin/flutter`, not on `$PATH` by default. Use the full path in all flutter commands throughout the agent task.

### O1 — Clean slate

```
git status
git fetch origin && git checkout master && git pull --ff-only
git log origin/master..HEAD
```

- Dirty working tree → **STOP and report**
- Unexpected local commits → **STOP and report** (don't build on top of someone else's work)

### O2 — Pick work

Keep an **`attempted` set** of PR numbers already tried this pass (starts empty).
It prevents re-picking a PR you just skipped/blocked and looping forever.

```
gh pr list --repo Maortz/allergy-detector --state open \
  --json number,title,url,isDraft,reviewDecision,labels
```

**Consider only:** non-draft PRs authored by an agent (branch prefix `agent/`).

**Exclude up front:**
- any PR already in the `attempted` set this pass, and
- any PR carrying the `needs-human-decision` label (a prior run escalated it for
  a maintainer call — see O4 / A2; do not retry until a human removes the label).

For each remaining candidate fetch review threads:
```
gh pr view <n> --json reviews,comments
# + GraphQL reviewThreads { isResolved, comments(first:1){ nodes{ body } } } query
# (REST comments alone miss resolution state)
```

**Blocking thread definition (shared across skills).** A thread is **blocking**
only when it is unresolved AND its first comment's body begins with `🔴` (blocker)
or `🟠` (major). Unresolved `🟢` nit / `🟡` minor / `ported to #N` / "clean"
threads are non-blocking and are NOT actionable review-response work.

**A PR qualifies** if it has at least one unresolved **blocking** thread OR a
`CHANGES_REQUESTED` review decision. (Do not pick PRs whose only unresolved
threads are 🟢/🟡/ported/clean — there is nothing to fix.)

**Skip** any PR whose newest commit is newer than its newest unresolved blocking
comment — feedback likely already addressed, awaiting re-review.

**Pick order:** `CHANGES_REQUESTED` first, then comment-only; within each,
**lowest PR number first**. Pick ONE and proceed to O3. You will return here and
pick the next-lowest after acting on it — start low and walk upward across the
whole backlog; never stop at the first PR.

Nothing qualifies (after exclusions) → **STOP** (nothing left to do this pass).

### O3 — Dispatch ONE agent

Spawn a **general-purpose (opus)** agent with the Agent Task below, passing PR number P. One agent at a time — never parallel/background. Wait for return.

### O4 — Act on return contract

A per-PR return **never halts the whole loop** — add the PR to the `attempted`
set and move to the next-lowest qualifying PR. Only **global faults** (O1 dirty
tree / unexpected local commits, `gh`/`flutter` unavailable) halt the loop.

| Return | Action |
|--------|--------|
| `COMMENTS_ADDRESSED <url>` | Add PR to `attempted`; go back to O1 and pick the next-lowest qualifying PR |
| `BLOCKED_NEEDS_DECISION <reason>` | Agent already labeled `needs-human-decision` + commented (A2). Add to `attempted` and to the **cycle-end blocked report**; continue to next PR |
| `STOPPED <reason>` | Transient (branch drift, out-of-scope-for-now). Add to `attempted`; continue to next PR |
| `FAILED <reason>` | Verify gate failed on that PR. Add to `attempted`; continue to next PR. Track consecutive FAILEDs — **3 in a row → STOP loop** (likely systemic) |

When the loop ends, print a **blocked report**: every PR that returned
`BLOCKED_NEEDS_DECISION` (with its reason) so the pipeline surfaces it to the
maintainer at cycle end.

Never merge a PR. Never force-push to a shared branch unless the agent explicitly determines it owns the branch and a rebase is required (see A7). Never resolve a thread you did not actually address.

---

## Agent Task (dispatch to fresh opus agent for PR P)

> You are a Senior Mobile Engineer (Flutter/Dart) addressing exactly one pull request, **#P**, in Maortz/allergy-detector — a Hebrew, RTL-first Flutter app. Flutter code lives in `app/`; design specs in `docs/superpowers/specs/2026-05-19-stitch-screens/`. Hold your work to staff-level standards: business logic OUT of widgets, idiomatic modern Dart, `const` constructors, correct disposal of controllers/streams/AnimationControllers/FocusNodes, no heavy work in `build()`, and theme tokens (`AppColors`/`AppTypography`/`AppSpacing`) — never hardcoded colors or sizes. UI text is hard-coded Hebrew, RTL-first.

### A1 — Context

Read:
- `CLAUDE.md` — build/test commands and operational gotchas
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — per-screen status master table

### A2 — Gather feedback

```bash
gh pr view P    # description + linked issue

# Review threads — REST misses isResolved; use GraphQL.
# Fetch ALL comments per thread (not just first) to see agent replies/reasoning:
gh api graphql -f query='
  query($owner:String!,$repo:String!,$number:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$number){
        reviewThreads(first:50){
          nodes{ isResolved comments(first:10){ nodes{ body author { login } createdAt } } }
        }
      }
    }
  }' -f owner=Maortz -f repo=allergy-detector -F number=P

# General (issue-level) PR comments — carry prior verdict history, maintainer
# notes, and agent round-summaries. Gives full picture of what has already been
# discussed or decided:
gh api repos/Maortz/allergy-detector/issues/P/comments
```

Enumerate every review thread and every general comment. Build an explicit
checklist of each unresolved actionable item, distinguishing:
- **Unaddressed**: no reply yet, no code change yet
- **Replied-but-unresolved**: agent replied with reasoning (e.g. declined with
  justification); thread still open pending reviewer acknowledgement
- **Addressed**: code changed and thread resolved

Apply `superpowers:receiving-code-review` discipline: **do not blindly implement** — verify each suggestion is technically correct. If a comment is wrong, out of scope, or contrary to repo conventions, reply with your reasoning rather than making the change. If total scope is far larger than a review-response should be (e.g. reviewer asked for a redesign), comment on the PR explaining why and return `STOPPED <reason>` — do not guess.

**Escalation — needs a human design decision.** If addressing the feedback
requires a judgment call you cannot make autonomously — e.g. the requested change
now conflicts with master because the screen/feature was superseded or
re-implemented by another merged PR (add/add conflict, not a one-line fix), or
two valid implementations exist and picking one is a product decision — do NOT
guess and do NOT silently stop. Instead **ask the maintainer**:

```
gh pr edit P --repo Maortz/allergy-detector --add-label needs-human-decision
gh pr comment P --repo Maortz/allergy-detector --body "<what the conflict is, the
  options, and your recommendation — concrete enough for a human to decide>"
```

Then return `BLOCKED_NEEDS_DECISION <reason>`. Change no code, push nothing, leave
the tree clean. The orchestrator skips `needs-human-decision` PRs until a human
removes the label, so this will not be re-attempted in a loop.

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

### A5 — Verify (hard gate — analyze + test ONLY, no builds)

Run from `app/`, **one command at a time** (no `&&` chaining). Use full Flutter path:

1. `/sdks/flutter/bin/flutter pub get`
2. `/sdks/flutter/bin/flutter analyze lib test` — must report **0 issues** (CI fails on warnings)
3. `/sdks/flutter/bin/flutter test` — all green

**Do NOT run `flutter build web` or `flutter build apk`.** Builds run in CI. The verify gate is analyze + test only.

Fix until all green. Cannot get all green → comment on PR with failing output → return `FAILED <reason>`. Do NOT push.

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

Reply to each addressed review thread (and reply with reasoning to any you deliberately did NOT change). Resolve only threads you genuinely addressed. Post a top-level PR comment summarizing the round, including `flutter analyze lib test` and `flutter test` results.

---

## Return Contract

Last line of agent output must be **exactly one** of:

```
COMMENTS_ADDRESSED <url>
BLOCKED_NEEDS_DECISION <reason>
STOPPED <reason>
FAILED <reason>
```

- `COMMENTS_ADDRESSED` — fixed + pushed + threads replied/resolved.
- `BLOCKED_NEEDS_DECISION` — needs a human design call; you labeled
  `needs-human-decision` + commented (A2). Orchestrator skips it next time.
- `STOPPED` — transient block (branch drift, etc.); safe to retry next cycle.
- `FAILED` — verify gate failed; no push.

Never merge. Never force-push a shared branch. Never resolve a thread you did not address.
