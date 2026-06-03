---
name: merge-verdict
description: >
  Use when checking which open PRs in the allergy-detector repo are ready to
  merge. Triggers on /merge-verdict, "which PRs are ready to merge", "check
  merge readiness", "give merge verdict", or when asked to audit open PRs for
  merge eligibility. Read-only — never merges, approves, or modifies anything.
---

# Merge Verdict

## Overview

Read-only audit of all open PRs. For each, check three gates and post a verdict. Never merge, approve, or modify anything.

## Three Gates

A PR is **READY** only when ALL three pass:

| Gate | Check |
|------|-------|
| **Reviewed** | At least one completed review exists (not just comments) |
| **Comments clean** | No unresolved review threads — use GraphQL `reviewThreads { isResolved }`, not REST (REST misses resolution state) |
| **CI green** | All required checks passed on the head SHA |

## Steps

### 1 — List open PRs

```
gh pr list --repo Maortz/allergy-detector --state open --draft=false \
  --json number,title,url,headRefOid,reviewDecision,statusCheckRollup
```

### 2 — For each PR, gather state

```bash
# Review decision + thread resolution (GraphQL)
gh pr view <n> --json reviews,reviewDecision

# CI status on head SHA
gh pr checks <n>

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

### 3 — Evaluate

**READY** if:
- `reviewDecision` is `APPROVED` or at least one review with state `APPROVED` or `COMMENTED` exists (i.e. not zero reviews)
- Zero unresolved `reviewThreads` nodes
- All required CI checks = `SUCCESS` / `NEUTRAL` (no `FAILURE`, `PENDING`, `CANCELLED`)

**NOT READY** if any gate fails. Collect all failing gates.

### 4 — Post verdict comment on each PR

```
gh pr comment <n> --body "<verdict>"
```

**Format:**

For ready:
```
✅ **READY TO MERGE** — reviewed, all threads resolved, CI green.
```

For not ready:
```
❌ **NOT READY** — <list each failing gate on its own line>
  - No review yet
  - <N> unresolved thread(s)
  - CI failing: <check name>
```

### 5 — Print summary

After processing all PRs, print a table to stdout:

```
PR    | Title                  | Verdict
------|------------------------|--------
#42   | feat: add X            | ✅ READY
#38   | fix: Y                 | ❌ unresolved threads (2), CI pending
```

## Constraints

- Read-only. Never merge, approve, request-changes, or edit code.
- One verdict comment per run is fine; avoid spamming if run repeatedly — check if an identical verdict already exists as the most recent comment before posting.
