#!/usr/bin/env bash
# Seed the agentic work queue as GitHub Issues.
# Prereq: a token with "Issues: Read and write" on Maortz/allergy-detector.
#   - Fine-grained PAT: GitHub > Settings > Developer settings > Fine-grained tokens
#     > [token] > Repository permissions > Issues = Read and write > Save.
#   - Or: gh auth login  (classic token with `repo` scope).
# Labels are already created (see ROADMAP.md §2). Idempotency is NOT handled —
# run once. Re-running creates duplicates.
set -euo pipefail

mk() { gh issue create --title "$1" --label "$2" --body "$3"; }

# ── P2 — SEVERE bugs ────────────────────────────────────────────────────────
mk "[bug] Add-product wizard submit is a no-op — saves nothing" \
   "area:bug,phase:2-fix,agent-ready,effort:M" \
'## Goal
Wire step-4 submit so the add-product wizard actually persists a product (today `onPressed: () {}`).

## Acceptance criteria
- [ ] Step-4 submit persists the product (contains + may-contain) via the product service
- [ ] On success, navigates to the add-product-success screen
- [ ] Amber "שים לב" may-contain note rendered per spec
- [ ] Submit loading + error states wired (Stitch art exists)

## Files / references
- index.md row: Primary #9 `add-product-step-4-may-contain`; Spec `add-product-step-4-may-contain.md` §3,§7.9 (S4-1..S4-11)
- Stitch: `723494ade01f454e96e9ae22524ca7cb` (loading `853093fa…`, error `a525e35f…`)
- Files: `app/lib/screens/add_product_screen.dart`

## Out of scope
- The success screen UI (separate issue) — just navigate to it.

## Definition of done
- [ ] `cd app && flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[bug] Admin brand verify-toggle is disabled (onChanged: null)" \
   "area:bug,phase:2-fix,agent-ready,effort:S" \
'## Goal
Make the admin trusted-brands verify toggle functional (currently `onChanged: null`).

## Acceptance criteria
- [ ] Toggle flips `is_verified` via `BrandService`, optimistic update + revert on error
- [ ] "סטטוס אימות" label above toggle; correct RTL thumb direction

## Files / references
- index.md row: Primary #22 `admin-trusted-brands`; Spec `admin-trusted-brands.md` §4.5,§7.8 (TB9)
- Stitch: `59e6d26de9a64bec9123ec396aae32fc`
- Files: `app/lib/screens/admin_brands_screen.dart`, `app/lib/services/brand_service.dart`

## Out of scope
- Page-header / stats-card / bento redesign (broader V-Spec fix).

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[bug] Avoid product banner is pink not solid red — weak danger signal" \
   "area:bug,phase:2-fix,agent-ready,effort:S" \
'## Goal
Restore the safety-critical danger signal: "הימנע" banner must be solid red, not light-pink (`#FCE8E6`).

## Acceptance criteria
- [ ] Avoid banner uses the solid red avoid token; copy/icon per spec ("הימנע – מכיל אלרגנים", `cancel`)
- [ ] `AppColors` tokens only (no hardcoded hex)

## Files / references
- index.md row: Primary #5 `product-details-avoid`; Spec `product-details-avoid.md` §4,§7.8 (AV1)
- Stitch: `9aa55d9704a849468749a219d7e81dc7`
- Files: `app/lib/screens/product_details.dart`, `app/lib/theme/`

## Out of scope
- Full tri-state pill-vs-banner refactor (separate V-Spec fix).

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[bug] Settings product-filter selector is a no-op (not wired/persisted)" \
   "area:bug,phase:2-fix,agent-ready,effort:M" \
'## Goal
Make the Settings "רמת סינון מוצרים" filter selector change + persist the filter level.

## Acceptance criteria
- [ ] Selecting a level updates state, persists (SharedPreferences), propagates via profile callback
- [ ] Rounded-pill chips with status-palette active colors; "רמת סינון מוצרים" label present
- [ ] Level affects product status computation where applicable

## Files / references
- index.md row: Primary #15 `settings-profile`; Spec `settings-profile.md` §4.2,§7.8 (ST6)
- Stitch: `3a2bc2f1aac1444886d44def38b72bc4`
- Files: `app/lib/screens/settings_screen.dart`

## Out of scope
- Drawer-vs-tab entry-point restructure (DD-2).

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[bug] Contact-us shows a false sent-successfully toast" \
   "area:bug,phase:2-fix,agent-ready,effort:S" \
'## Goal
Stop the contact form claiming success when nothing was sent.

## Acceptance criteria
- [ ] Submit actually sends/queues; success shown only on real success
- [ ] In-place success state per spec (not a SnackBar over a still-visible form)
- [ ] Loading state disables fields + spinner

## Files / references
- index.md row: Primary #17 `contact-us`; Spec `contact-us.md` §5.4,§5.5,§7.7 (CC4)
- Stitch: `5a9bc40c2d8a46c7b760d2725cde2cf4` (success `e2e5fe4d…`)
- Files: `app/lib/screens/contact_screen.dart`

## Out of scope
- Hero card / contact rows / subject dropdown unless trivial.

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[bug] report-success renders the wrong screen (review-next, not the report confirmation)" \
   "area:bug,phase:2-fix,agent-ready,effort:M" \
'## Goal
`feedback_success_screen.dart` renders a review-next-item style screen with gamification cards — it must render the report-sent confirmation.

## Acceptance criteria
- [ ] Renders success checkmark, "הדיווח נשלח בהצלחה!", body, success/brand badge pair, footer per spec
- [ ] CTA "חזרה לדף הבית" (filled), app-bar "דיווח נשלח", bottom nav "בית"
- [ ] Removes spurious next-product / points / rank widgets

## Files / references
- index.md row: Primary #19 `report-success`; Spec `report-success.md` §4,§7.7 (RS1..RS9)
- Stitch: `4bb210f9ac7143e0a6d1558dd950a62d`
- Files: `app/lib/screens/feedback_success_screen.dart`

## Out of scope
- review-next-item screen (do not regress it).

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

# ── P3 — never-built screens ────────────────────────────────────────────────
mk "[screen] Build Community Review screen (approve/reject workflow)" \
   "area:screen,phase:3-build,agent-ready,effort:L" \
'## Goal
Build the dedicated community-review screen — approve/reject workflow, allergen tiles, history strip. No dedicated screen exists today.

## Acceptance criteria
- [ ] Review card with product, allergen tiles, approve/reject actions wired to data
- [ ] Empty-queue state ("אין מוצרים לסקירה כרגע", Stitch `76fc099b…`)
- [ ] Loading-next state (Stitch `3005fabe…`)

## Files / references
- index.md row: Primary #12 `community-review`; Spec `community-review.md` §7.6 (CR1..CR11)
- Stitch: `521b195cd91443849b0f983487ef5f9c`
- Files: new screen under `app/lib/screens/`

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green (add widget tests) · `index.md` updated · PR `Closes #<this>`'

mk "[screen] Build Add-Product Success screen" \
   "area:screen,phase:3-build,agent-ready,effort:M" \
'## Goal
Build `add_product_success_screen.dart` (absent today). Reached after the wizard submit (see the submit no-op bug).

## Acceptance criteria
- [ ] "המוצר נוסף בהצלחה!" card, status badge pair ("ממתין לאישור"/"סטטוס בדיקה"), "חזרה לקהילה" button per spec
- [ ] Define `AppColors.success` token if missing (`#0D9488`, per DD)

## Files / references
- index.md row: Primary #10 `add-product-success`; Spec `add-product-success.md` §4,§7.7 (SU-1..SU-10)
- Stitch: `7f85b05267594677827497af62b8de1e`
- Files: new `app/lib/screens/add_product_success_screen.dart`, `app/lib/theme/`

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[screen] Build AdminNavigationDrawer (admin nav-drawer variant)" \
   "area:screen,phase:3-build,agent-ready,effort:M" \
'## Goal
Build the admin drawer variant with role gating — `navigation_drawer.dart` is a bottom-nav mirror, not admin sections.

## Acceptance criteria
- [ ] `Drawer`/`endDrawer` widget (RTL), gated on `UserProfile.isAdmin`
- [ ] Two sections ("ניהול מערכת"/"ניהול תוכן") + 6 admin rows per spec
- [ ] Logout copy "התנתקות" (not "יציאה")

## Files / references
- index.md row: Primary #21 `nav-drawer-admin`; Spec `nav-drawer-admin.md` §7.8 (DA1..DA12)
- Stitch: `b4224114bb2e4ff6a2cca1db65a401f6`
- Files: `app/lib/screens/` (new AdminNavigationDrawer)

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[screen] Build Review All Clear terminal screen (currently only a banner)" \
   "area:screen,phase:3-build,agent-ready,effort:M" \
'## Goal
Build the full review-all-clear terminal screen — only `all_clear_banner.dart` (inline banner) exists.

## Acceptance criteria
- [ ] Hero success ("כל הכבוד!", body, medal icon on `#00478D` circle), session-total bento, "חזרה לבית" CTA per spec
- [ ] Shown when the review queue empties

## Files / references
- index.md row: Primary #14 `review-all-clear`; Spec `review-all-clear.md` §7.8 (AC1..AC8)
- Stitch: `3c43a140383248dfa16bbd286c79f4f2`
- Files: `app/lib/screens/`, `app/lib/widgets/all_clear_banner.dart`

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

# ── P3 — Tier 2 state variants (art drawn) ──────────────────────────────────
mk "[screen] Implement Tier 2 states — search & scan flow" \
   "area:screen,phase:3-build,agent-ready,effort:L" \
'## Goal
Implement the drawn Tier 2 state variants for the search/scan flow.

## Acceptance criteria
- [ ] active-search-results: empty `e504f73f…`, error `70dbaf14…`, loading `039a3d7b…`
- [ ] search-scan: camera-denied `a1c46da7…`, recently-scanned-empty `bc36d27a…`
- [ ] Each state matches the parent screen chrome; spec refs in index.md §4

## Files / references
- index.md §4 rows (active-search-results ×3, search-scan ×2)
- Files: `app/lib/screens/search_screen.dart`, `search_scan_screen.dart`

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` V columns updated · PR `Closes #<this>`'

mk "[screen] Implement Tier 2 states — home, community, product-details, settings" \
   "area:screen,phase:3-build,agent-ready,effort:L" \
'## Goal
Implement the remaining drawn Tier 2 state variants (excludes add-product states — those follow the submit fix).

## Acceptance criteria
- [ ] home: empty `7ec4966c…`, loading `ba2c4bac…`
- [ ] community-review empty `76fc099b…`; community-hub loading `9412dcbd…` / error `a881dbbd…`
- [ ] product-details no-image `65ccebcb…`; review-next loading `3005fabe…`
- [ ] admin-brands empty `ccda9e77…`; settings no-profile `819e8bdf…`; contact-us success `e2e5fe4d…`

## Files / references
- index.md §4 rows (the non-search, non-add-product items)

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` V columns updated · PR `Closes #<this>`'

# ── P3 — Tier 3 destinations (art drawn) ────────────────────────────────────
mk "[screen] Implement Tier 3 user-drawer destinations + tap-target sub-screens" \
   "area:screen,phase:3-build,agent-ready,effort:L" \
'## Goal
Implement the drawn Tier 3 user-facing destinations.

## Acceptance criteria
- [ ] User drawer: ScanHistory `354525c0…`, SavedProducts `abf43922…`, MyReviews `f746f3e2…`, HelpCenter `8dd5e1f9…`, About `e7ed6ed4…`, AppPreferences `a44ffb74…`, ContributionHistory `dbad30d7…`
- [ ] Sub-screens: HelpTips `049e9df0…`, ScanInstructions `a79d3e8c…`, ActiveDiscussion `526f8d49…`, WeeklyTip `c5a858b7…`
- [ ] Drawer rows route to the new screens

## Files / references
- index.md §5 rows (user drawer + sub-screens)

## Notes
Large — split into per-screen sub-PRs if needed.

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

mk "[screen] Implement Tier 3 admin-drawer destinations" \
   "area:screen,phase:3-build,effort:L" \
'## Goal
Implement the drawn admin-drawer destinations. DEPENDS ON the AdminNavigationDrawer build (no `agent-ready` until that lands).

## Acceptance criteria
- [ ] AdminDashboard `23dd7228…`, Reports `6b5bdbd7…`, SystemSettings `34221698…`, ProductScans `a5a436fc…`, CommunityManagement `5643b4e9…`
- [ ] Reached from AdminNavigationDrawer; gated on isAdmin

## Files / references
- index.md §5 admin rows

## Definition of done
- [ ] `flutter analyze` 0 · `flutter test` green · `index.md` updated · PR `Closes #<this>`'

# ── P4 — verification (depend on impl; not agent-ready) ─────────────────────
mk "[verify] V-Spec re-audit after P2/P3 land" \
   "area:verify,phase:4-verify,effort:M" \
'## Goal
Re-audit each screen impl-vs-spec after the P2 fixes and P3 builds; update index.md V-Spec. Fold in stale `§7` spec-prose reconciliation.

## Acceptance criteria
- [ ] Every Code ✓ screen has V-Spec ✓ or a current ⚠ delta table
- [ ] Stale "not implemented"/"may exist as stub" spec prose corrected

## Notes
Not `agent-ready` — depends on P2/P3 completion; scope is broad.

## Definition of done
- [ ] index.md V-Spec column current · PR `Closes #<this>`'

mk "[verify] V-Art pixel pass (impl vs Stitch art)" \
   "area:verify,phase:4-verify,effort:L" \
'## Goal
Compare each implemented screen against its Stitch art (`get_screen <id>`); record V-Art in index.md.

## Acceptance criteria
- [ ] Every Code ✓ screen has V-Art ✓ or a ⚠ delta note
- [ ] Differences that are intentional per a DD are marked ✓ with the DD ref

## Notes
Not `agent-ready` — depends on impl; needs Stitch MCP + judgment.

## Definition of done
- [ ] index.md V-Art column current · PR `Closes #<this>`'

# ── P5 — infra ──────────────────────────────────────────────────────────────
mk "[infra] Re-gate the CI apk job (remove continue-on-error)" \
   "area:infra,effort:M" \
'## Goal
Make the CI `apk` job blocking now that the clean-build is fixed (`36e9d7c`).

## Acceptance criteria
- [ ] Confirm `apk` green on a clean runner
- [ ] Remove `continue-on-error` from the `apk` job; add to required checks
- [ ] (optional) `android.enableJetifier=false` experiment in a throwaway branch

## Notes
Not `agent-ready` — needs a human to confirm runner-green before flipping the gate.

## Files / references
- `.github/workflows/ci.yml`

## Definition of done
- [ ] CI apk blocking + green · PR `Closes #<this>`'

echo "Seeded $(gh issue list --limit 100 | wc -l) open issues."
