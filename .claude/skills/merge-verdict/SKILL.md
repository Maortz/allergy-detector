---
name: merge-verdict
description: >
  Use when checking which open PRs in the allergy-detector repo are ready to
  merge. Triggers on /merge-verdict, "which PRs are ready to merge", "check
  merge readiness", "give merge verdict", or when asked to audit open PRs for
  merge eligibility. First audits the review gate (reviewed + threads resolved)
  for every PR; then, for review-passing PRs lacking a green CI run, briefly
  enables the CI workflow, re-triggers it, and disables it again. Never merges
  or approves.
---

# Merge Verdict

## Overview

Two phases:

1. **Audit the review gate** for every open PR (read-only).
2. **Re-trigger CI** for PRs that pass review but have no current green CI run.
   This mutates Actions state: it enables the `CI` workflow, pushes an empty
   commit to each affected PR branch, then disables the workflow again.

Never merge, approve, or request-changes. The only writes this skill performs
are: verdict comments on PRs, empty commits on PR branches, and enable/disable
of the `CI` workflow.

## Gates

A PR passes the **review gate** when BOTH:

| Gate | Check |
|------|-------|
| **Reviewed** | At least one completed review exists (not just comments) |
| **Comments clean** | No unresolved review threads — use GraphQL `reviewThreads { isResolved }`, not REST (REST misses resolution state) |

A PR is **READY TO MERGE** when it passes the review gate AND has a green CI
run on its current head SHA. CI is **green** when every required check
(`build`, `apk`) is `SUCCESS`/`NEUTRAL` on the current `headRefOid`. A PR with
no run, a stale run (run SHA ≠ current head), a failed run, or a pending run is
**not green** and is a candidate for re-trigger.

## The CI workflow

- Single workflow: **CI** (`.github/workflows/ci.yml`), normally
  `disabled_manually`. Confirm with `gh workflow list --repo Maortz/allergy-detector --all`.
- It triggers only on `pull_request`/`push` to `master` — there is **no
  `workflow_dispatch`**. The only way to fire it for a PR is a new commit on the
  PR branch (a `synchronize` event), which is why Phase C pushes an empty commit.
- Enabling/disabling does **not** cancel in-flight runs. But disabling blocks
  *new* runs from being created — so after pushing, wait until each run is
  queued before disabling, or the trigger is lost.

## Steps

### 1 — List open PRs

```
gh pr list --repo Maortz/allergy-detector --state open --draft=false \
  --json number,title,url,headRefName,headRefOid,reviewDecision,statusCheckRollup
```

### 2 — Phase A: evaluate the review gate per PR

```bash
# Review decision
gh pr view <n> --json reviews,reviewDecision

# Unresolved threads — REST misses isResolved; use GraphQL:
gh api graphql -f query='
  query($owner:String!,$repo:String!,$number:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$number){
        reviewThreads(first:50){
          nodes{ isResolved }
        }
      }
    }
  }' -f owner=Maortz -f repo=allergy-detector -F number=<n>
```

**Passes review gate** when:
- `reviewDecision` is `APPROVED`, or at least one review with state `APPROVED`
  or `COMMENTED` exists (i.e. not zero reviews), AND
- Zero unresolved `reviewThreads` nodes.

PRs that fail the review gate are **NOT READY** — record the failing reason and
do nothing else to them. They are never candidates for CI re-trigger.

### 3 — Phase B: find review-passers with no green CI

For each review-passing PR, check CI on the current head SHA:

```bash
gh pr checks <n>   # or read statusCheckRollup from step 1
```

A PR is a **re-trigger candidate** when it passed the review gate but its
required checks are not all `SUCCESS`/`NEUTRAL` on the current `headRefOid`
(no run, stale, failed, or pending).

If there are **zero** candidates, skip Phase C entirely — do not touch the
workflow.

### 4 — Phase C: enable → re-trigger → disable

Only run this when Phase B found ≥1 candidate.

```bash
# 1. Enable the workflow
gh workflow enable CI --repo Maortz/allergy-detector

# 2. For each candidate PR, push an empty commit via the Git refs API
#    (no local checkout / working-tree churn). Same tree → empty commit.
SHA=$(gh pr view <n> --repo Maortz/allergy-detector --json headRefOid -q .headRefOid)
BRANCH=$(gh pr view <n> --repo Maortz/allergy-detector --json headRefName -q .headRefName)
TREE=$(gh api repos/Maortz/allergy-detector/commits/$SHA --jq .commit.tree.sha)
NEW=$(gh api repos/Maortz/allergy-detector/git/commits \
        -f message="ci: re-trigger checks" \
        -f tree=$TREE -f parents[]=$SHA --jq .sha)
gh api -X PATCH repos/Maortz/allergy-detector/git/refs/heads/$BRANCH -f sha=$NEW

# 3. Wait until a run is QUEUED for the new SHA before disabling, so the
#    disable does not drop the trigger. Poll per branch:
gh run list --repo Maortz/allergy-detector --workflow CI --branch $BRANCH \
  --json headSha,status --jq "[.[] | select(.headSha==\"$NEW\")] | length"
#    Loop until that returns ≥1 (or a short timeout, ~60s) for every candidate.

# 4. Disable the workflow again (restores its normal state)
gh workflow disable CI --repo Maortz/allergy-detector
```

Always disable in step 4 even if some pushes/polls failed — leaving CI enabled
changes the repo's normal state. Report any candidate whose run never queued.

Do **not** wait for runs to finish. They run to completion after disable; their
green/red result is picked up by a later merge-verdict run.

### 5 — Post a verdict comment on each PR

```
gh pr comment <n> --repo Maortz/allergy-detector --body "<verdict>"
```

Anti-spam: before posting, check the PR's most recent comment — if it already
carries an identical verdict, skip the post.

Verdict bodies:
- `✅ **READY TO MERGE** — reviewed, all threads resolved, CI green.`
- `🔄 **CI RE-TRIGGERED** — review passed; CI was missing/stale/failed, fresh run queued. Not ready until it goes green.`
- `❌ **NOT READY (review)** — <reason: "no review yet" / "<N> unresolved thread(s)">`

### 6 — Print summary

```
PR    | Title                  | Verdict
------|------------------------|--------
#42   | feat: add X            | ✅ READY (review + CI green)
#39   | feat: add Z            | 🔄 CI re-triggered (pending)
#38   | fix: Y                 | ❌ review: 2 unresolved threads
#35   | chore: W               | ❌ review: no review yet
```

Verdict values:
- `✅ READY` — passed review gate and CI already green on head SHA.
- `🔄 CI re-triggered (pending)` — passed review, CI was missing/stale/failed,
  a fresh run was queued this run.
- `❌ review: <reason>` — failed the review gate.

## Constraints

- Never merge, approve, request-changes, or edit application code.
- The only writes allowed: verdict comments on PRs, empty commits on candidate
  PR branches, and enable/disable of the `CI` workflow. Nothing else.
- Always end with the `CI` workflow `disabled_manually` (its normal state).
- Pushing an empty commit advances `headRefOid`; if branch protection has
  "dismiss stale reviews" enabled this re-opens the review gate next run. That
  is acceptable — the PR simply isn't READY until re-reviewed.
