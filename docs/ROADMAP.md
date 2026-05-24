# Roadmap

**Strategic direction only.** This file picks *what* matters and *in what order*.
It does **not** track individual tasks or per-screen status.

- **Per-screen status** (Stitch · Spec · Code · V-Spec · V-Art) → the master table in
  [`docs/superpowers/specs/2026-05-19-stitch-screens/index.md`](superpowers/specs/2026-05-19-stitch-screens/index.md).
- **Dispatchable work** → **GitHub Issues** (the live queue an agent or human pulls from).
  Browse: `gh issue list`. Agent-pickable: `gh issue list --label agent-ready`.

**Last reviewed:** 2026-05-25 (restructured to strategy-only; per-task tracking moved
to GitHub Issues + index.md; added the screen pipeline + phases + agentic dispatch model).

---

## 1. The screen pipeline (process)

Every screen flows through these stages. Each stage has a definition-of-done gate;
a screen can't advance until the gate is met. The `index.md` columns record where
each screen currently sits.

| Stage | Gate (definition of done) | `index.md` column |
|---|---|---|
| **Spec** | A `.md` spec exists (own file) or the state is described in a parent screen's `§` | Spec ✓ / ◐ |
| **Art** | Stitch art generated; Screen ID recorded | Stitch ✓ |
| **Implement** | Dart shipped to `master`; `flutter analyze` 0, `flutter test` green | Code ✓ |
| **Verify-Spec** | Impl audited against the spec doc; deltas filed or none | V-Spec ✓/⚠ |
| **Verify-Art** | Impl compared pixel-wise against Stitch art (`get_screen <id>`) | V-Art ✓/⚠ |
| **Done** | Code ✓ and both V columns ✓ | all ✓ |

## 2. How work is dispatched (agentic)

Work units live as **GitHub Issues**, one atomic job each, written from the
`agent-job` issue template (`.github/ISSUE_TEMPLATE/agent-job.md`).

**Labels** route the queue:
- `area:screen` `area:bug` `area:verify` `area:infra`
- `phase:2-fix` `phase:3-build` `phase:4-verify`
- `effort:S` `effort:M` `effort:L`
- **`agent-ready`** — the gate: bounded scope + crisp acceptance criteria + low blast
  radius. Only labelled issues are safe to auto-pick. No label = human-only.

**The routine** (scheduled agent, 2–3×/day; set up via the `/schedule` skill):
> list `agent-ready` issues by priority → take top → branch → implement to acceptance
> criteria → update `index.md` → open PR with `Closes #N` → **stop** (human merges).

CI (`build` job: analyze + test + build web) is the merge gate. Branch protection is
unavailable on the private plan, so **a human merges every PR** — the routine never merges.

## 3. Where the project stands

- Web ✓ · Android APK ✓ (`36e9d7c`, PR #3) · iOS ✓ (CI macOS, `--no-codesign`). Windows target removed.
- Tests: 215/215. `flutter analyze`: 0. No auth (MVP profile in SharedPreferences).
- **CI live** (`.github/workflows/ci.yml`): required `build` = analyze + test + build web; `apk`/`ios` jobs (apk still `continue-on-error`). Android JDK 17.
- **Design: complete.** All Tier 1–3 screens drawn in Stitch (see `index.md`).
- **Implementation: partial.** Primary + derived screens shipped but **all audited screens diverge from spec (V-Spec ⚠)**; 6 SEVERE/functional bugs + 4 never-built screens. All Tier 2/3 screens are drawn-not-implemented (◑). V-Art pass not started.

## 4. Phases (ordered)

| Phase | Theme | Status |
|---|---|---|
| **P0** | Foundations — CI, APK clean-build, lint→0 | ✓ done |
| **P1** | Design — Stitch art for all screens | ✓ done (2026-05-25) |
| **P2** | Fix SEVERE divergences in shipped screens | ⏳ active — see `phase:2-fix` issues |
| **P3** | Build the unbuilt screens + Tier 2/3 | ☐ — see `phase:3-build` issues |
| **P4** | Verification — V-Spec sweep, then V-Art sweep | ☐ — see `phase:4-verify` issues |
| **P5** | Infra hardening + data-backed home | ☐ — see `area:infra` issues |

**P2 — SEVERE bugs (highest priority; safety + core flows):**
add-product wizard submit no-op · admin brand verify-toggle disabled · avoid-banner
pink not red (safety signal) · settings product-filter no-op · contact-us false
success toast · report-success renders the wrong screen.

**P3 — never-built + new screens:** `community-review`, `add-product-success`,
`nav-drawer-admin` (AdminNavigationDrawer), `review-all-clear` (full screen vs banner);
then the 19 Tier 2 state variants + 16 Tier 3 destinations (all drawn, awaiting code).

**P4 — verification:** re-audit each screen's V-Spec after P2/P3 land; fold in the
stale-spec-prose reconciliation (some `§7` notes predate implementation); then the
V-Art pixel pass against Stitch art.

**P5 — infra / quality:** re-gate the CI `apk` job (remove `continue-on-error`, add to
required checks) · `android.enableJetifier=false` experiment · `ScanHistoryService` →
real data-backed home screen (replaces hardcoded mock activity; ScanHistory art now exists).

## 5. Backlog (unranked / not yet phased)

- Supabase auth (needed for cross-device sync + community features).
- Accessibility audit (RTL screen-reader labels, `AppColors` contrast, focus order).
- `SearchCache` TTL tuning + barcode-result caching.
- Admin tooling (`scripts/admin-sync.dart`, `import-openfoodfacts.dart`) → CI or scheduled job.
- Cross-cutting UI: branded SnackBar/toast styles, "add to favorites" interaction, contact-us subject picker.

## 6. Done

- **P1 — Stitch art for all screens** — 2026-05-25. Tier 2 (19 states) + Tier 3 (16 destinations + sub-screens) generated, incl. ScanHistoryScreen (P30, + empty variant). Per-screen status consolidated into the single `index.md` master table (5 status columns); `_missing-screens.md` removed (folded into index); `_stitch-prompts.md` kept as generation reference.
- **Tier 1 unbuilt screens** — 2026-05-21, PR #9 (`feat/tier1-screens`, `b5dc11b`). 10 items: `AllergenManagementScreen`, `OnboardingStep2Screen`, `FavoritesScreen` (empty), `ProfileEditSheet`, `AdminBrandFormSheet`, `app_dialogs.dart` (D-1/2/3), `photo_source_picker.dart`, `Brand` model + `BrandService`. Tests 184→215; 0 analyze errors; CI green.
- **Lint cleanup + CI gate** — 2026-05-19, `chore/lint-cleanup`. Cleared all 26 `flutter analyze` issues to clean; tightened CI analyze to `--no-fatal-infos` (new warnings now fail the build).
- **Android APK clean-build fix** — 2026-05-18, `36e9d7c` (PR #3). Migrated Flutter Gradle plugin apply to declarative `plugins {}`; removed stale `.gradle`/`.kts` duplicates. `flutter build apk --debug` passes from a fresh clone.
- **CI/CD pipeline** — 2026-05-18, `19a0e35` (PR #1, `ci/github-actions`). `build` job (analyze + test + build web) required; `apk`/`ios` non-blocking. CI Android JDK pinned to 17.

## How to use this file

- New session: read this for direction, `index.md` for screen status, `gh issue list` for the work queue.
- New concrete work: open a GitHub Issue from the `agent-job` template; label it; add `agent-ready` only if dispatch-safe.
- Strategy shift (CI lands, new constraint): update phases here, bump "Last reviewed". Keep task detail in issues, not here.
