# Stitch Screens — Spec Tracker

**Single source of truth** for every screen's status across five dimensions:
Stitch design · Spec · Implementation · Verification-vs-Spec · Verification-vs-Art.
Status is tracked **only here** — no status table is duplicated in sibling files.

**Column legend:**
- **Stitch** ✓ = Stitch art generated (Screen ID exists) · ✗ = not drawn
- **Spec** ✓ = own `.md` spec file here · ◐ = no standalone file, specified inside a parent screen's `§` section
- **Code** ✓ = Dart impl shipped to `master` · ✗ = not implemented · ◑ = art drawn, code pending
- **V-Spec** (impl vs spec doc) ✓ = aligned · ⚠ = diverged (see spec §7) · ⬜ = impl exists, not checked · — = N/A
- **V-Art** (impl vs Stitch rendered art, via `get_screen <id>`) ✓ = matches art · ⚠ = diverged · ⬜ = impl exists, not checked · — = N/A

> **Why two verification columns:** specs are a *prescriptive transcription* of the
> Stitch art, and the design decisions (`_design-decisions.md` DD-1..DD-17)
> deliberately override the art in places. So an impl can match the spec (V-Spec ✓)
> yet still differ from the raw art (V-Art ⚠), or vice-versa. Track both.

---

## 1. Primary screens (own spec file)

| # | Stitch title | Slug | Dart file | Stitch | Spec | Code | V-Spec | V-Art | Screen ID |
|---|---|---|---|---|---|---|---|---|---|
| 1 | דף הבית (Home Dashboard) | `home-dashboard` | `home_screen.dart` | ✓ | ✓ | ✓ | ⚠ (HD1–HD8, §7) | ⬜ | `4cbae145a6a34837ab47bdec527b10df` |
| 2 | חיפוש וסריקה (Search & Scan) | `search-scan` | `search_scan_screen.dart` | ✓ | ✓ | ✓ | ⚠ (SS1–SS8, §7.8) | ⬜ | `b075f5753b7948a9bb115786f1b922ed` |
| 3 | חיפוש פעיל - תוצאות (Active Search) | `active-search-results` | `search_screen.dart` | ✓ | ✓ | ✓ | ⚠ (AS1–AS8, §7.9) | ⬜ | `45d081ae18b143ca8e15b12469468d9a` |
| 4 | פרטי מוצר - בטוח (Product Details — Safe) | `product-details-safe` | `product_details.dart` | ✓ | ✓ | ✓ | ⚠ (SF1–SF9, §7.9) | ⬜ | `eda2fffaccee4c059519033acc27e842` |
| 5 | פרטי מוצר - הימנע (Product Details — Avoid) | `product-details-avoid` | `product_details.dart` | ✓ | ✓ | ✓ | ⚠ (AV1–AV9, §7.8 — SEVERE: pink not red) | ⬜ | `9aa55d9704a849468749a219d7e81dc7` |
| 6 | הוספת מוצר - שלב 1 (Barcode) | `add-product-step-1-barcode` | `add_product_screen.dart` | ✓ | ✓ | ✓ | ⚠ (S1-1–S1-14, §7.10) | ⬜ | `ffdb6626d62944548656cee7494af945` |
| 7 | הוספת מוצר - שלב 2 (Photos) | `add-product-step-2-photos` | `add_product_screen.dart` | ✓ | ✓ | ✓ | ⚠ (S2-1–S2-11, §7.9) | ⬜ | `bbda540783f94818b581f4d7dd8f7811` |
| 8 | הוספת מוצר - שלב 3 (Contains) | `add-product-step-3-contains` | `add_product_screen.dart` | ✓ | ✓ | ✓ | ⚠ (S3-1–S3-10, §7.8) | ⬜ | `0161b2a94e354831baac041620b68d6d` |
| 9 | הוספת מוצר - שלב 4 (May Contain) | `add-product-step-4-may-contain` | `add_product_screen.dart` | ✓ | ✓ | ✓ | ⚠ (S4-1–S4-11, §7.9 — SEVERE: submit no-op) | ⬜ | `723494ade01f454e96e9ae22524ca7cb` |
| 10 | הוספה הצליחה (Add Product Success) | `add-product-success` | `add_product_success_screen.dart` (absent) | ✓ | ✓ | ✗ | ⚠ (SU-1–SU-10, §7.7 — SEVERE: not built) | — | `7f85b05267594677827497af62b8de1e` |
| 11 | Community Hub | `community-hub` | `community_screen.dart` | ✓ | ✓ | ✓ | ⚠ (CH1–CH13, §7.8) | ⬜ | `a8c9931205604870a6ecee4456c6e808` |
| 12 | Community Review | `community-review` | _no dedicated screen_ | ✓ | ✓ | ✗ | ⚠ (CR1–CR11, §7.6 — SEVERE: not impl) | — | `521b195cd91443849b0f983487ef5f9c` |
| 13 | המשך סקירה (Review Next Item) | `review-next-item` | `review_next_screen.dart` | ✓ | ✓ | ✓ | ⚠ (RN1–RN12, §7.7) | ⬜ | `2d3d5126490f4c5496fc194b35a865a7` |
| 14 | הכל נבדק! (Review All Clear) | `review-all-clear` | `all_clear_banner.dart` widget | ✓ | ✓ | ✓ | ⚠ (AC1–AC8, §7.8 — only a banner) | ⬜ | `3c43a140383248dfa16bbd286c79f4f2` |
| 15 | Settings & Profile | `settings-profile` | `settings_screen.dart` | ✓ | ✓ | ✓ | ⚠ (ST1–ST12, §7.8 — filter no-op) | ⬜ | `3a2bc2f1aac1444886d44def38b72bc4` |
| 16 | Onboarding — Allergen Selection | `onboarding-allergen-selection` | `onboarding_screen.dart` | ✓ | ✓ | ✓ | ⚠ (OB1–OB4, §7.8 — minor) | ⬜ | `565153749ead4760b7cb331cf3ae28a9` |
| 17 | Contact Us (Updated) | `contact-us` | `contact_screen.dart` | ✓ | ✓ | ✓ | ⚠ (CC1–CC7, §7.7 — partial) | ⬜ | `5a9bc40c2d8a46c7b760d2725cde2cf4` |
| 18 | Report Issue | `report-issue` | `feedback_screen.dart` | ✓ | ✓ | ✓ | ⬜ | ⬜ | `a6741117c9f14b84938c4abda143a5dd` |
| 19 | דיווח נשלח בהצלחה (Success Confirmation) | `report-success` | `feedback_success_screen.dart` | ✓ | ✓ | ✓ | ⚠ (RS1–RS9, §7.7 — WRONG screen) | ⬜ | `4bb210f9ac7143e0a6d1558dd950a62d` |
| 20 | User Navigation Drawer (Right) | `nav-drawer-user` | `drawer_user_screen.dart` | ✓ | ✓ | ✓ | ⚠ (DU1–DU12, §7.7) | ⬜ | `6e8f8bcbe71548b0a7f1bf6920de7343` |
| 21 | Admin Navigation Drawer (Right) | `nav-drawer-admin` | _no AdminNavigationDrawer_ | ✓ | ✓ | ✗ | ⚠ (DA1–DA12, §7.8 — SEVERE: not impl) | — | `b4224114bb2e4ff6a2cca1db65a401f6` |
| 22 | Manage Trusted Brands (Admin) | `admin-trusted-brands` | `admin_brands_screen.dart` | ✓ | ✓ | ✓ | ⚠ (TB1–TB14, §7.8 — TB9 toggle wired ✓; others pending) | ⬜ | `59e6d26de9a64bec9123ec396aae32fc` |
| 23 | SafeBite — App Cover (390w) | `app-cover` | — excluded (marketing cover) | ✓ | ✓ | — | — | — | `55abf4d7f4be4caa8e291b52c18bff6f` |

## 2. Derived screens (own spec file; implemented 2026-05-21 PR #9)

| Slug | Source | Dart file | Stitch | Spec | Code | V-Spec | V-Art | Screen ID |
|---|---|---|---|---|---|---|---|---|
| `product-details-caution` | `product-details-safe §5` | `product_details.dart` | ✓ | ✓ | ✓ | ⚠ (D1–D8, §7.3) | ⬜ | `cc547da888234066a41c3f6b870f9109` |
| `onboarding-step-2-notifications` | `onboarding-allergen-selection §7.4` | `onboarding_step_2_screen.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `7142e1d9c3444da28cbe9ad1d182e210` |
| `allergen-management` | `settings-profile §7.5` | `allergen_management_screen.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `ae91775d0e3d44698b83c6444ca59490` |
| `profile-edit` | `settings-profile §4.1` | `widgets/profile_edit_sheet.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `065940c55b2943098221676d72608c7c` |
| `admin-brand-form` | `admin-trusted-brands §5.6/5.7/7.7` | `widgets/admin_brand_form_sheet.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `e7a0ff0b66724d03bf93dbb3d797cac5` |
| `_dialogs` D-1 wizard-exit | `_dialogs.md#d-1` | `utils/app_dialogs.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `e04e8b6554954cf9b29b2e956db95e38` |
| `_dialogs` D-2 logout | `_dialogs.md#d-2` | `utils/app_dialogs.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `3def9aa18ff44e559b62e77153fc58f1` |
| `_dialogs` D-3 brand-delete | `_dialogs.md#d-3` | `utils/app_dialogs.dart` | ✓ | ✓ | ✓ | ✓ | ⬜ | `4e652f2ece7f466aad8fee02d16baec2` |
| Photo source picker | — | `utils/photo_source_picker.dart` | ✓ | ◐ | ✓ | ✓ | ⬜ | `b697e240e6ec4e6a95824e14810786b6` |

> **product-details-caution** V-Spec stays ⚠: caution state predated the spec;
> audited 2026-05-24, diverged on 8 axes (D1–D8). See `product-details-caution.md §7.3`;
> fixes deferred to Batch H (shared w/ Safe/Avoid).

## 3. Tier 1 backlog — remaining

| Item | Dart file | Stitch | Spec | Code | V-Spec | V-Art | Screen ID |
|---|---|---|---|---|---|---|---|
| FavoritesScreen — empty variant | `favorites_screen.dart` | ✓ | ◐ | ✓ | ✓ | ⬜ | `426bcc95dca14bf0ae93c4500a1f306c` |
| FavoritesScreen — list variant | _pending_ | ✓ | ◐ | ◑ | — | — | `1a06439f518f4a25b919c322a25bc5c2` |

> List variant waits on the "add to favorites" interaction (see §6 Cross-cutting).

## 4. Tier 2 — per-screen state variants (drawn 2026-05-25, not implemented)

Spec ◐ = state described inside the parent screen's `§` section (no standalone file).

| Item | Spec ref (parent §) | Stitch | Spec | Code | V-Spec | V-Art | Screen ID |
|---|---|---|---|---|---|---|---|
| active-search-results — empty | `active-search-results.md §5.3` | ✓ | ◐ | ✓ | ⚠ | ⬜ | `e504f73fec524b4ba013905f061a5768` (built #23 — `StateView`; icon shade `AppColors.outline` vs spec #9CA3AF) |
| active-search-results — error (network) | `active-search-results.md §5.4` | ✓ | ◐ | ✓ | ⚠ | ⬜ | `70dbaf144e6e42098f63fda967cd4102` (built #23 — `StateView` + retry; icon shade as above) |
| active-search-results — loading (shimmer) | `active-search-results.md §5.1` | ✓ | ◐ | ✓ | ⚠ | ⬜ | `039a3d7b5fb94e3ca509963e9589dd33` (#23 — spinner, not shimmer) |
| community-review — empty queue | `community-review.md §7.3` | ✓ | ◐ | ◑ | — | — | `76fc099b0447415991d17ff3f4e199a2` |
| search-scan — camera permission denied | `search-scan.md §5` | ✓ | ◐ | ✓ | ⚠ | ⬜ | `a1c46da747004d06bbba53e509eda8f6` (built #23 — StateView wired, but no live denial path yet: `ScannerService.initialize()` only constructs the controller; the real permission prompt fires later when `MobileScanner` mounts, so a permission-revoked user currently sees the inert viewfinder chrome. Reachable today only via the injected `_DeniedScannerService` in tests; needs a real probe — e.g. `controller.start()` + surface `PlatformException` — before V-Spec ✓.) |
| search-scan — recently-scanned empty | `search-scan.md §7.4` | ✓ | ◐ | ✓ | ✓ | ⬜ | `bc36d27a550c4c799e77debf1c80e5d9` (built #23) |
| add-product step-1 — camera unavailable | `add-product-step-1-barcode.md §7.8` | ✓ | ◐ | ◑ | — | — | `7734213045d84db5b5dc405bb1d6b0b1` |
| add-product step-1 — inline validation | `add-product-step-1-barcode.md §7.6` | ✓ | ◐ | ◑ | — | — | `29acef0c7ce74c4c892fa13b4befb8c7` |
| add-product step-2 — thumbnail-filled | `add-product-step-2-photos.md §4` | ✓ | ◐ | ◑ | — | — | `4d0abbf12a3241d6b6aa0dbe44e25796` |
| add-product step-2 — upload error / retry | `add-product-step-2-photos.md §5` | ✓ | ◐ | ◑ | — | — | `b455aadb1abc4f5cbec0f02430ca3899` |
| add-product step-4 — submit loading + error | `add-product-step-4-may-contain.md §5` | ✓ | ◐ | ◑ | — | — | loading `853093faac694925980a7d6ca03d3560` · error `a525e35fa2ac4c18a79fe876e179453d` |
| admin-trusted-brands — empty list | `admin-trusted-brands.md §5.3` | ✓ | ◐ | ◑ | — | — | `ccda9e77c2ba455a8538b30f7b2a97c0` |
| product-details — image load fallback | `product-details-safe.md §7` | ✓ | ◐ | ◑ | — | — | `65ccebcbc33a44cca25b4bee1789d11e` |
| review-next-item — loading next (shimmer) | `review-next-item.md §5.2` | ✓ | ◐ | ◑ | — | — | `3005fabe856f432a84d011a2ec58779e` |
| home-dashboard — empty activity feed | `home-dashboard.md §5` | ✓ | ◐ | ◑ | — | — | `7ec4966cbb8847bc9d7da908eec05727` |
| home-dashboard — loading (shimmer) | `home-dashboard.md §5` | ✓ | ◐ | ◑ | — | — | `ba2c4baced9c4a3f9bec305480e393ba` |
| community-hub — loading / error stats | `community-hub.md §5.2, §5.3` | ✓ | ◐ | ◑ | — | — | loading `9412dcbd08c34571b1b8c582e477546c` · error `a881dbbdc8834027ad02131e782c120a` |
| settings — logged-out / no-profile | `settings-profile.md §5.7` | ✓ | ◐ | ◑ | — | — | `819e8bdf6656480c9b6d94e4df10ce4b` |
| contact-us — success state | `contact-us.md §5.5` | ✓ | ◐ | ◑ | — | — | `e2e5fe4d593948bf8083412afe865a2c` |

## 5. Tier 3 — drawer destinations & tap-target sub-screens (drawn, not implemented)

| Item | Spec ref (parent §) | Stitch | Spec | Code | V-Spec | V-Art | Screen ID |
|---|---|---|---|---|---|---|---|
| ScanHistoryScreen | `nav-drawer-user.md §3` row 2 | ✓ | ◐ | ◑ | — | — | `354525c044af4399a12c43659148d1a8` (+ empty `3964f61e988142e1b09dc7afb5dbd5fb`) |
| SavedProductsScreen | `nav-drawer-user.md §3` row 3 | ✓ | ◐ | ◑ | — | — | `abf43922f856429d84501b8aed3d34fa` |
| MyReviewsScreen | `nav-drawer-user.md §3` row 4 | ✓ | ◐ | ◑ | — | — | `f746f3e2e1f64b88be971a69ed947327` |
| HelpCenterScreen | `nav-drawer-user.md §3` row 5, `settings-profile.md §4.3` | ✓ | ◐ | ◑ | — | — | `8dd5e1f96c684b8e9cc555c67c97999d` |
| AboutScreen | `nav-drawer-user.md §3` row 6, `settings-profile.md §4.3` | ✓ | ◐ | ◑ | — | — | `e7ed6ed4aa4d459f9cff98723ac28fd3` |
| AppPreferencesScreen | `settings-profile.md §4.3` | ✓ | ◐ | ◑ | — | — | `a44ffb749dc14b98a137b06d09a21ed6` |
| ContributionHistoryScreen | `settings-profile.md §4.3` | ✓ | ◐ | ◑ | — | — | `dbad30d71d9b4366966a1c28cc33664e` |
| AdminDashboardScreen | `nav-drawer-admin.md §3` row 1 | ✓ | ◐ | ◑ | — | — | `23dd72286c2444f5980d2ab9ca8783ba` |
| ReportsScreen | `nav-drawer-admin.md §3` row 3 | ✓ | ◐ | ◑ | — | — | `6b5bdbd744934ff780c87b8b6eeecb8c` |
| SystemSettingsScreen | `nav-drawer-admin.md §3` row 4 | ✓ | ◐ | ◑ | — | — | `34221698c42242b5bed31c855c648bd0` |
| ProductScansScreen | `nav-drawer-admin.md §3` row 5 | ✓ | ◐ | ◑ | — | — | `a5a436fc8f234927bb16a3f37a870485` |
| CommunityManagementScreen | `nav-drawer-admin.md §3` row 6 | ✓ | ◐ | ◑ | — | — | `5643b4e9a2b849d392bc56a260e04407` |
| HelpTipsScreen | `search-scan.md §7.3` | ✓ | ◐ | ◑ | — | — | `049e9df09593488fabc48a506aa07640` |
| ScanInstructionsScreen | `search-scan.md §7.3` | ✓ | ◐ | ◑ | — | — | `a79d3e8c0f754b26b131e877be7d79b2` |
| ActiveDiscussionScreen | `community-hub.md §7.2` | ✓ | ◐ | ◑ | — | — | `526f8d49ea4242e3ad14dc79927083af` |
| WeeklyTipScreen | `community-hub.md §7.2` | ✓ | ◐ | ◑ | — | — | `c5a858b7d1cf4476b6cbbdbc90e4408d` |

## 6. Cross-cutting (interactions, not standalone screens — no art by design)

| Item | Spec ref | Stitch | Spec | Code | V-Spec | V-Art |
|---|---|---|---|---|---|---|
| Branded SnackBar / toast styles | multiple | ✗ | ◐ | ✗ | — | — |
| "Add to favorites" interaction | `product-details-*.md` | ✗ | ◐ | ✗ | — | — |
| contact-us subject picker | `contact-us.md §4.3` | ✗ | ◐ | ✗ | — | — |

---

## Status summary (2026-05-25)

- **Stitch art: complete** for every screen (Tier 1–3); only cross-cutting interactions have no art (by design).
- **Implementation:** primary + derived screens shipped; all Tier 2/3 screens are `◑` (drawn, 0 implemented).
- **V-Spec:** every implemented screen audited → all `⚠` diverged (except `report-issue`/derived = `✓`/`⬜`).
- **V-Art:** **not started** — every implemented screen is `⬜`. This is a distinct future pass (`get_screen <id>` → compare pixels vs the running app).
- **Next:** promote Tier 2/3 to implementation; fix V-Spec `⚠` divergences; then run the V-Art pass.

## Known duplicate screens in the Stitch project

`mcp__stitch__list_screens` (2026-05-25, 86 screens) shows several screens
generated more than once. Stitch has **no delete-screen MCP tool**, so the dupes
can't be removed — use the **canonical ID** (the one in the tables above) and
ignore the rest:

| Screen | Canonical ID (use this) | Duplicate ID(s) to ignore |
|---|---|---|
| Onboarding Step 2 | `7142e1d9c3444da28cbe9ad1d182e210` | `6d99c14a2457…`, `b7c98e1d2853…` |
| Product Details — Caution | `cc547da888234066a41c3f6b870f9109` | `f937873ed5bc…` (cleaner title "זהירות"; canonical has typo "תוריהז") |
| Manage Allergens | `ae91775d0e3d44698b83c6444ca59490` | `e4237c3b3a04…` |
| Edit Brand Modal | `e7a0ff0b66724d03bf93dbb3d797cac5` | `686762b42d88…` |
| Logout Confirmation Modal | `3def9aa18ff44e559b62e77153fc58f1` | `8599eb19037f…` |
| Delete Brand Confirmation | `4e652f2ece7f466aad8fee02d16baec2` | `8d8cf45773f6…` |
| Exit Confirmation Modal | `e04e8b6554954cf9b29b2e956db95e38` | `233a86a467ae…` |
| Edit Profile Modal | `065940c55b2943098221676d72608c7c` | `33e571daf37d…` |
| Add Photo Modal | `b697e240e6ec4e6a95824e14810786b6` | `44f63b560fcc…` |

(Plus ~5 raw food-photo image assets and the marketing app-cover — not UI screens.)

## Sibling files

- **[_stitch-prompts.md](_stitch-prompts.md)** — Stitch generation reference (shared context, the P30 worked example, timeout gotcha). All backlog prompts already run.
- **[_components-glossary.md](_components-glossary.md)** — shared components + M3 `ColorScheme` mapping ([DD-12](_design-decisions.md#dd-12-material-3-adoption)).
- **[_dialogs.md](_dialogs.md)** — confirmation dialogs `#d-1`/`#d-2`/`#d-3`.
- **[_design-decisions.md](_design-decisions.md)** — cross-screen decisions DD-1..DD-17.
