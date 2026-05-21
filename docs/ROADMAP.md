# Roadmap

A living, prioritized backlog of project-level next steps. This is a **meta-plan** — it picks *what* to do next, not *how*. Each item here either becomes a full plan in `docs/superpowers/plans/<date>-<slug>.md` when picked up, or gets done inline if small.

**Last reviewed:** 2026-05-21 (PR #9 merged; added Spec/Code/Verified columns to index.md; introduced rolling verification pass as item #2).

## Where the project stands today

- Web ✓. **Android APK build ✓** — fixed from a clean checkout in `36e9d7c` (PR #3); the imperative Flutter Gradle plugin apply was migrated to the declarative `plugins {}` block and the stale `.gradle`/`.gradle.kts` duplicates removed.
- iOS ✓ — built green on every PR via the CI macOS runner (`flutter build ios --no-codesign`).
- Windows: target intentionally removed; `app/windows/` scaffold deleted (no longer a build surface).
- Tests: 215/215 passing (+6 Brand model tests from PR #9 review fixes).
- `flutter analyze`: **0 issues** (was 26 — roadmap previously miscounted as 32; all cleared). CI analyze step is now `--no-fatal-infos` only, so any new **warning** fails the build.
- **CI: live.** `.github/workflows/ci.yml` runs on PRs/pushes to `master`: required `build` job = analyze (errors only) + test + build web; `apk` and `ios` jobs. CI Android JDK pinned to 17 (local dev uses 21 via the 8.11.1 wrapper). The `apk` job still has `continue-on-error` — re-gating it is ranked item #4 below.
- Working tree is honest again — no long-standing uncommitted WIP or orphan stashes.
- No auth (MVP profile stored locally in SharedPreferences).

### Screen implementation status

All 32 Stitch spec files in `docs/superpowers/specs/2026-05-19-stitch-screens/` have been cross-referenced against `app/lib/screens/` and `app/lib/widgets/`.

**Implemented (spec + code both exist):**
| Spec | Dart file |
|---|---|
| home-dashboard | `home_screen.dart` |
| search-scan | `search_scan_screen.dart` |
| active-search-results | `search_screen.dart` |
| product-details-safe / avoid / caution | `product_details.dart` (3-state single file) |
| onboarding-allergen-selection | `onboarding_screen.dart` |
| settings-profile | `settings_screen.dart` |
| community-hub | `community_screen.dart` |
| community-review | `review_next_screen.dart` |
| contact-us | `contact_screen.dart` |
| report-issue | `feedback_screen.dart` |
| report-success | `feedback_success_screen.dart` |
| review-next-item | `review_next_screen.dart` |
| review-all-clear | `all_clear_banner.dart` widget |
| add-product steps 1-4 + success | `add_product_screen.dart` (wizard) |
| nav-drawer-user | `navigation_drawer.dart` |
| nav-drawer-admin | `navigation_drawer.dart` (admin variant) |
| admin-trusted-brands | `admin_brands_screen.dart` |

**Stitch art exists, now implemented (Tier 1 — completed 2026-05-21, `feat/tier1-screens`):**
| Item | Dart file |
|---|---|
| allergen-management screen | `allergen_management_screen.dart` |
| profile-edit modal sheet | `widgets/profile_edit_sheet.dart` |
| onboarding step 2 — notifications | `onboarding_step_2_screen.dart` |
| admin-brand-form modal sheet | `widgets/admin_brand_form_sheet.dart` |
| FavoritesScreen — empty state | `favorites_screen.dart` |
| D-1 wizard-exit dialog | `utils/app_dialogs.dart` |
| D-2 logout dialog | `utils/app_dialogs.dart` |
| D-3 brand-delete dialog | `utils/app_dialogs.dart` |
| photo source picker sheet | `utils/photo_source_picker.dart` |
| Brand model + BrandService | `models/brand.dart`, `services/brand_service.dart` |

**Remaining Tier 1 (pending):**
| Item | Stitch screen ID |
|---|---|
| product-details-caution (verify parity) | `cc547da888234066a41c3f6b870f9109` |

**No Stitch art yet, not implemented (Tier 2-3 — see `_missing-screens.md` for full list):**
- Per-screen empty / error / loading states (18 items)
- Drawer destinations: ScanHistoryScreen, SavedProductsScreen, MyReviewsScreen, HelpCenterScreen, AboutScreen, AppPreferencesScreen, ContributionHistoryScreen
- Admin drawer destinations: AdminDashboardScreen, ReportsScreen, SystemSettingsScreen, ProductScansScreen, CommunityManagementScreen
- Cross-cutting: SnackBar/toast styles, "add to favorites" interaction

## Ranked items

### 1. Generate Stitch art for Tier 2 screens — **not started**

Tier 1 is fully implemented (PR #9). The next design pass covers Tier 2: per-screen empty/error/loading states (18 items) and the 12 drawer-destination screens. The Stitch project ID is `16588854804615693446`. Use `_stitch-prompts.md` for prompt templates; pass `projectId: "16588854804615693446"` to `mcp__stitch__generate_screen_from_text`. When art lands:
1. Flip the status in `_missing-screens.md` from ☐ to ◑ and fill in the Stitch URL column.
2. Promote groups to ranked items for implementation.

**Why first:** Unblocks Tier 2 implementation. Design before implement keeps concerns separate and avoids re-work.

**Effort:** ~15–30 min per screen in Stitch.

---

### 2. Spec-parity verification pass — **not started**

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` now tracks a **Verified** column. 22 screens + `product-details-caution` are implemented but unverified (Verified = ⬜). The 5 Tier 1 derived screens built directly from spec art in PR #9 are already ✓.

**Approach per screen:** `mcp__stitch__get_screen <id>` → compare rendered layout, colours, typography, RTL alignment, and interaction states against the widget → fix divergences in-place → flip Verified to ✓ in `index.md`.

**Priority order** (suggested batches of 3–4 per session):

| Batch | Screens | Stitch IDs |
|---|---|---|
| A — Tier 1 blocker | `product-details-caution` | `cc547da8...` |
| B — Simple single-state | `report-success`, `review-all-clear`, `contact-us` | `4bb210f9`, `3c43a140`, `5a9bc40c` |
| C — Core UX | `search-scan`, `active-search-results`, `home-dashboard` | `b075f575`, `45d081ae`, `4cbae145` |
| D — Auth/flow | `onboarding-allergen-selection`, `settings-profile` | `56515374`, `3a2bc2f1` |
| E — Community | `community-hub`, `community-review`, `review-next-item` | `a8c99312`, `521b195c`, `2d3d5126` |
| F — Add-product wizard | steps 1–4 + success | `ffdb6626`–`7f85b052` |
| G — Admin + nav | `admin-trusted-brands`, `nav-drawer-user`, `nav-drawer-admin` | `59e6d26d`, `6e8f8bcb`, `b4224114` |
| H — Product-details | `product-details-safe`, `product-details-avoid` | `eda2fffa`, `9aa55d97` |

Start with Batch A (it's a known risk) then B (quick wins), C (highest daily-use impact).

**Why second:** Every unverified screen is a silent divergence risk. Cheap to fix now; expensive after Tier 2 state work builds on top of diverged layouts.

**Effort:** ~1–2 hrs per batch of 3–4 screens.

---

### 3. Re-gate the CI `apk` job + further infra — **not started**

Now that the APK clean-build is fixed (`36e9d7c`), close the loop:
- Flip the CI `apk` job back to blocking (remove `continue-on-error`) and add it to the required-check list — verify it's green on a clean runner first.
- `android.enableJetifier=false` experiment — all deps are AndroidX, so Jetifier shouldn't be needed. Faster builds if it works. Verify in a throwaway branch.

Don't bump infra preemptively — the painful bump (AGP 8.9.1 / Gradle 8.11.1 / Kotlin 2.1.0 / compileSdk 36) is recent and stable. Flutter SDK upgrades only when a feature needs them; current 3.41.7 is fine.

**Effort:** ~30 min (apk re-gate) + ~15 min (Jetifier experiment).

---

### 4. ScanHistory-backed home screen — **not started**

Replace the hardcoded mock recent-activity/stats on `home_screen.dart` with a real `ScanHistoryService` (promoted from Backlog). An abandoned WIP attempt existed in stashes but depended on an uncommitted service and was dropped during the 2026-05-18 cleanup; rebuild fresh. The `home-dashboard.md` spec in `docs/superpowers/specs/` describes the expected data shape.

**Why fifth:** Depends on nothing above it, but a real home screen is a meaningful quality-of-life milestone. Slot after the Tier 1 screen work so CI bounds regression risk.

**Effort:** ~½ day (service + wiring + tests).

---

## How to use this file

- When picking up project work in a new session, read this first.
- When an item is started, change its status from "not started" to "in progress (branch: …)".
- When finished, move it to the "Done" section at the bottom with a date and the merge commit SHA.
- New ideas: append to the end as "Backlog" entries; promote into the ranked list when they're concrete enough to estimate.
- Re-rank the whole list when the situation changes (CI lands, new constraints emerge, etc.) and bump the "Last reviewed" date.

## Backlog (unranked / not yet concrete)

- Tier 2 per-screen states (18 items) — empty / error / loading variants; see `_missing-screens.md` Tier 2 for the full list. Pick up after Tier 1 implementation is complete.
- Tier 3 drawer destinations (12 screens) — ScanHistory, SavedProducts, MyReviews, HelpCenter, About, AppPreferences, ContributionHistory, AdminDashboard, Reports, SystemSettings, ProductScans, CommunityManagement. Most require backend work; design them in Stitch before implementing.
- Cross-cutting polish — branded SnackBar/toast styles, "add to favorites" interaction on product-details, subject picker for contact-us dropdown (see `_missing-screens.md` Cross-cutting).
- Supabase auth (MVP currently has none → needed for cross-device sync and community features).
- Accessibility audit (RTL screen-reader labels, contrast on `AppColors`, focus order).
- `SearchCache` TTL tuning and barcode-result caching.
- Admin tooling for `scripts/admin-sync.dart` / `import-openfoodfacts.dart` — wire into CI or a scheduled job.

## Done

- **Implement Tier 1 unbuilt screens** — 2026-05-21, merged as PR #9 (branch `feat/tier1-screens`, final commit `b5dc11b`). All 10 Tier 1 items built and reviewed: `AllergenManagementScreen`, `OnboardingStep2Screen`, `FavoritesScreen` (empty state), `ProfileEditSheet`, `AdminBrandFormSheet`, `app_dialogs.dart` (D-1/D-2/D-3), `photo_source_picker.dart`, `Brand` model, `BrandService`. Wiring: `OnboardingScreen` routes to step 2; `MainContainer` tab 4 → `FavoritesScreen`; Settings → drawer nav; `BottomNavBar` (M3). Review fixes: post-pop SnackBar bug, `NSUserNotificationUsageDescription` in iOS plist, all `Color(0x...)` / `TextStyle(fontSize: N)` literals replaced with `AppColors`/`AppTypography`, decorative `Switch.onChanged: null`, UTC timestamps, 6 new `Brand` model tests. Test count: 184 → 215 (+31); 0 analyze errors; all CI jobs green.

- **Clean up the lint warnings + gate CI** — 2026-05-19, branch `chore/lint-cleanup` (PR pending). Cleared all **26** `flutter analyze` issues (the roadmap's "32" was a stale miscount) to a clean `No issues found!` — 11 unused imports, dead write-only fields (`_searchResults`/`_isSearching` + the vestigial `_onSearch` that fired discarded network calls; the never-wired `_showOnlySafeProducts` stub), an unused test helper, `withOpacity`→`withValues`, deprecated form-field `value:`→`initialValue:`, redundant `as Map` casts, and multi-underscore wildcards. Then tightened the CI analyze step from `--no-fatal-infos --no-fatal-warnings` to `--no-fatal-infos` so any new **warning** fails the build (infos left non-fatal so SDK-bump deprecation noise doesn't break unrelated PRs). Mechanical only — 184/184 tests stayed green throughout. Note: a concurrent Stitch-spec process committed unrelated docs onto this branch mid-run; those were extracted to `docs/stitch-screen-specs` and the lint branch rebuilt clean.
- **Resolve long-standing uncommitted WIP** — 2026-05-18, branch `chore/resolve-wip-stashes`. Removed the never-committed `app/windows/` scaffold (16 files), tracked the project docs (`GEMINI.md`, `docs/ROADMAP.md`, `docs/superpowers/plans/*`), gitignored Claude machine-local artifacts (`.claude/plugins/`, `.claude/settings.local.json`), and dropped 5 redundant/stale stashes (`claude-rebase-preserve-2`, `ci-restructure-wip`, `ci-fix-wip`, `ci-pr-wip-preserve`, the iOS-job WIP). The stashed `home_screen.dart` rework was non-viable (imported an uncommitted `ScanHistoryService`) and was abandoned — recorded as a Backlog item instead. `git status` and CLAUDE.md are honest again.
- **Fix Android APK build from a clean checkout** — 2026-05-18, merged in `36e9d7c` (PR #3). Migrated the imperative Flutter `app_plugin_loader` Gradle plugin apply to the declarative `plugins {}` block and removed the stale `settings.gradle`/`.kts` and `build.gradle`/`.kts` duplicates. `flutter build apk --debug` now passes from a fresh clone (previously only "worked" locally because Gradle build caches masked it).
- **CI/CD pipeline** — 2026-05-18, merged in `19a0e35` (PR #1, branch `ci/github-actions`). `.github/workflows/ci.yml`: required `build` job = `flutter analyze --no-fatal-infos --no-fatal-warnings` + `flutter test` + `flutter build web --no-tree-shake-icons`; non-blocking `apk` and `ios` jobs. No Supabase secrets needed — analyze/test/build never execute `main()`, so empty `String.fromEnvironment` values compile fine. Caching via `subosito/flutter-action` (SDK+pub) + `actions/cache` (Gradle). CI Android JDK pinned to 17 (Java 21 bytecode was unreadable by the runner's Gradle). Spun out follow-ups: APK clean-build fix (now done, `36e9d7c`) and the private-repo branch-protection caveat (still open).
