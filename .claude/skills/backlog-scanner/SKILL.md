---
name: backlog-scanner
description: >
  Use when the allergy-detector agent pipeline finds zero open agent-ready
  issues and needs to propose new backlog items. Scans spec-audit gaps,
  outdated dependencies, TODO/FIXME markers, and unblocked blocked-issues, then
  files DRAFT issues (never labeled agent-ready — the maintainer triages).
  Triggers on /backlog-scanner or from agent-pipeline stage 1 when the
  agent-ready backlog is empty. Idempotent via issue markers; max 5 issues/run.
---

# Backlog Scanner

## Hard rules

- **Never apply the `agent-ready` label.** Only the maintainer promotes drafts.
- Max **5** new issues per run. Prefer the highest-signal candidates.
- Idempotent: every issue body ends with `<!-- backlog-scanner:<slug> -->`
  where `<slug>` is a stable kebab-case id of the finding (e.g.
  `pub-outdated-share-plus-12`, `todo-product-service-l88`). Before creating,
  search: `gh issue list --repo Maortz/allergy-detector --state all --search "backlog-scanner:<slug>"` — skip on any hit (open OR closed: closed means rejected, don't re-file).
- Run at most once per 24h: check stamp `/var/log/agents/backlog-scanner.stamp`;
  if it exists and is younger than 24h (`find /var/log/agents/backlog-scanner.stamp -mmin -1440`), STOP with `SKIPPED stamp-fresh`. Touch it after a completed scan.

## Sources (scan all four)

1. **Spec-audit gaps** — grep the spec tree for unresolved audit flags:
   `grep -rn '⚠\|✗' docs/superpowers/specs/2026-05-19-stitch-screens/ | head -40`
   Each distinct flagged screen/section is a candidate (`area:verify` or `area:screen`).
2. **Outdated dependencies** — from `app/`: `flutter pub outdated --json | jq '.packages[] | select(.isDiscontinued or (.current.version != .resolvable.version)) | {package: .package, current: .current.version, resolvable: .resolvable.version}'`.
   Bundle ALL safe minor/patch bumps into ONE candidate issue (`area:infra`, `effort:S`); each major bump gets its own (`effort:M`).
3. **Code markers** — `grep -rn 'TODO\|FIXME\|HACK' app/lib --include='*.dart' | head -20`.
   Only file an issue for markers describing real user-facing gaps or bugs, not style notes.
4. **Unblocked blocked issues** — for each `gh issue list --repo Maortz/allergy-detector --state open --label blocked --json number,title,body`, extract the blocking reference (`#N` after "blocked on"/"depends on"); if that issue/PR is closed/merged, comment on the blocked issue: "Blocker #N has landed — candidate for unblocking" and include it in the report (do NOT file a new issue for these).

## Filing format

Use the issue-writer skill's structure: Problem, Proposed solution, Acceptance
criteria (checkboxed), Out of scope. Apply labels: one `area:*` + one
`effort:*` (never `agent-ready`, never `phase:*` — the maintainer assigns phase
at triage). Title prefixed by area, e.g. `[infra] bump outdated pub dependencies (minor/patch)`.

## Return contract

Last line exactly one of:
```
DONE filed=<#new-issues> unblock-candidates=<#>
SKIPPED <reason>
FAILED <reason>
```
