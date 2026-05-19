# Roadmap

A living, prioritized backlog of project-level next steps. This is a **meta-plan** — it picks *what* to do next, not *how*. Each item here either becomes a full plan in `docs/superpowers/plans/<date>-<slug>.md` when picked up, or gets done inline if small.

**Last reviewed:** 2026-05-19 (after the lint cleanup landed — `flutter analyze` is at zero and CI now fails on warnings; see Done).

## Where the project stands today

- Web ✓. **Android APK build ✓** — fixed from a clean checkout in `36e9d7c` (PR #3); the imperative Flutter Gradle plugin apply was migrated to the declarative `plugins {}` block and the stale `.gradle`/`.gradle.kts` duplicates removed.
- iOS ✓ — built green on every PR via the CI macOS runner (`flutter build ios --no-codesign`).
- Windows: target intentionally removed; `app/windows/` scaffold deleted (no longer a build surface).
- Tests: 184/184 passing.
- `flutter analyze`: **0 issues** (was 26 — roadmap previously miscounted as 32; all cleared). CI analyze step is now `--no-fatal-infos` only, so any new **warning** fails the build.
- **CI: live.** `.github/workflows/ci.yml` runs on PRs/pushes to `master`: required `build` job = analyze (errors only) + test + build web; `apk` and `ios` jobs. CI Android JDK pinned to 17 (local dev uses 21 via the 8.11.1 wrapper). With the APK fix landed, the `apk` job should be flipped back to blocking — see ranked item #2. **Caveat:** branch protection requires GitHub Pro or a public repo (private-repo plan limitation), so the required check is advisory until the repo is upgraded/made public.
- Working tree is honest again — no long-standing uncommitted WIP or orphan stashes.
- No auth (MVP profile stored locally in SharedPreferences).

## Ranked items

### 1. Implement more screens via Stitch (recommended next) — **not started**

The Stitch MCP is integrated and the "Clinical Clarity RTL" design system exists. Candidates worth designing/implementing next:
- Product detail screen (post-scan deep dive — ingredient breakdown, alternative product suggestions).
- Allergen profile editor with per-allergen severity (currently boolean selection).
- Community feed detail / post composer.

Pick one screen per cycle; use `mcp__stitch__get_screen` for reference, implement, write widget tests.

**Why first:** With both shipping-build blockers (APK, WIP hygiene) cleared, this is the highest-value remaining work — real user-facing progress. CI now bounds regression risk on new screens.

**Effort:** ~1 day per screen (design → implement → test).

---

### 2. Re-gate the CI `apk` job + further infra — **not started**

Now that the APK clean-build is fixed (`36e9d7c`), close the loop:
- Flip the CI `apk` job back to blocking (remove `continue-on-error`) and add it to the required-check list — verify it's green on a clean runner first.
- `android.enableJetifier=false` experiment — all deps are AndroidX, so Jetifier shouldn't be needed. Faster builds if it works. Verify in a throwaway branch.

Don't bump infra preemptively — the painful bump (AGP 8.9.1 / Gradle 8.11.1 / Kotlin 2.1.0 / compileSdk 36) is recent and stable. Flutter SDK upgrades only when a feature needs them; current 3.41.7 is fine.

**Effort:** ~30 min (apk re-gate) + ~15 min (Jetifier experiment).

---

## How to use this file

- When picking up project work in a new session, read this first.
- When an item is started, change its status from "not started" to "in progress (branch: …)".
- When finished, move it to the "Done" section at the bottom with a date and the merge commit SHA.
- New ideas: append to the end as "Backlog" entries; promote into the ranked list when they're concrete enough to estimate.
- Re-rank the whole list when the situation changes (CI lands, new constraints emerge, etc.) and bump the "Last reviewed" date.

## Backlog (unranked / not yet concrete)

- Supabase auth (MVP currently has none → needed for cross-device sync and community features).
- ScanHistory-backed home screen — replace the hardcoded mock recent-activity/stats on `home_screen.dart` with a real `ScanHistoryService`. (An abandoned WIP attempt existed in stashes but depended on an uncommitted service and was dropped during the 2026-05-18 cleanup; rebuild fresh if pursued.)
- Accessibility audit (RTL screen-reader labels, contrast on `AppColors`, focus order).
- `SearchCache` TTL tuning and barcode-result caching.
- Admin tooling for `scripts/admin-sync.dart` / `import-openfoodfacts.dart` — wire into CI or a scheduled job.

## Done

- **Clean up the lint warnings + gate CI** — 2026-05-19, branch `chore/lint-cleanup` (PR pending). Cleared all **26** `flutter analyze` issues (the roadmap's "32" was a stale miscount) to a clean `No issues found!` — 11 unused imports, dead write-only fields (`_searchResults`/`_isSearching` + the vestigial `_onSearch` that fired discarded network calls; the never-wired `_showOnlySafeProducts` stub), an unused test helper, `withOpacity`→`withValues`, deprecated form-field `value:`→`initialValue:`, redundant `as Map` casts, and multi-underscore wildcards. Then tightened the CI analyze step from `--no-fatal-infos --no-fatal-warnings` to `--no-fatal-infos` so any new **warning** fails the build (infos left non-fatal so SDK-bump deprecation noise doesn't break unrelated PRs). Mechanical only — 184/184 tests stayed green throughout. Note: a concurrent Stitch-spec process committed unrelated docs onto this branch mid-run; those were extracted to `docs/stitch-screen-specs` and the lint branch rebuilt clean.
- **Resolve long-standing uncommitted WIP** — 2026-05-18, branch `chore/resolve-wip-stashes`. Removed the never-committed `app/windows/` scaffold (16 files), tracked the project docs (`GEMINI.md`, `docs/ROADMAP.md`, `docs/superpowers/plans/*`), gitignored Claude machine-local artifacts (`.claude/plugins/`, `.claude/settings.local.json`), and dropped 5 redundant/stale stashes (`claude-rebase-preserve-2`, `ci-restructure-wip`, `ci-fix-wip`, `ci-pr-wip-preserve`, the iOS-job WIP). The stashed `home_screen.dart` rework was non-viable (imported an uncommitted `ScanHistoryService`) and was abandoned — recorded as a Backlog item instead. `git status` and CLAUDE.md are honest again.
- **Fix Android APK build from a clean checkout** — 2026-05-18, merged in `36e9d7c` (PR #3). Migrated the imperative Flutter `app_plugin_loader` Gradle plugin apply to the declarative `plugins {}` block and removed the stale `settings.gradle`/`.kts` and `build.gradle`/`.kts` duplicates. `flutter build apk --debug` now passes from a fresh clone (previously only "worked" locally because Gradle build caches masked it).
- **CI/CD pipeline** — 2026-05-18, merged in `19a0e35` (PR #1, branch `ci/github-actions`). `.github/workflows/ci.yml`: required `build` job = `flutter analyze --no-fatal-infos --no-fatal-warnings` + `flutter test` + `flutter build web --no-tree-shake-icons`; non-blocking `apk` and `ios` jobs. No Supabase secrets needed — analyze/test/build never execute `main()`, so empty `String.fromEnvironment` values compile fine. Caching via `subosito/flutter-action` (SDK+pub) + `actions/cache` (Gradle). CI Android JDK pinned to 17 (Java 21 bytecode was unreadable by the runner's Gradle). Spun out follow-ups: APK clean-build fix (now done, `36e9d7c`) and the private-repo branch-protection caveat (still open).
