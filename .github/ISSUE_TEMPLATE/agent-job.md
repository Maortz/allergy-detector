---
name: Agent job
about: A bounded, dispatchable unit of work an LLM agent (or human) can pick up
title: "[area] short imperative title"
labels: []
---

<!--
Fill every section. An automated agent parses these headings, so keep them.
Add `agent-ready` ONLY when scope is bounded, acceptance criteria are crisp,
and blast radius is low. No `agent-ready` label = human-only.
-->

## Goal
<!-- One sentence: what outcome this job delivers and why. -->

## Acceptance criteria
<!-- Checklist the PR must satisfy. Concrete + testable. -->
- [ ]
- [ ]

## Files / references
<!-- Where to work + what to read first. Link the index.md row, Stitch ID, spec §. -->
- index.md row:
- Spec / §:
- Stitch screen ID:
- Likely files:

## Out of scope
<!-- Explicit guardrails — what NOT to touch. Prevents scope creep. -->
-

## Definition of done
- [ ] `cd app && flutter analyze` → 0 issues
- [ ] `cd app && flutter test` → all green
- [ ] `index.md` status columns updated for the affected screen(s)
- [ ] PR opened with `Closes #<this issue>`
