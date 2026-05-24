# Stitch Screens — Spec Tracker

Tracker for the per-screen Stitch spec set. Reading/writing order = row order.

**Column legend:**
- **Spec** ✓ = `.md` spec file exists in this directory
- **Stitch** ✓ = Stitch art generated (screen ID exists) · ✗ = not drawn yet
- **Code** ✓ = Dart implementation shipped to `master` · ✗ = not implemented
- **Verified** ✓ = implementation checked against spec/Stitch art, known aligned · ⬜ = not yet verified · ⚠ = audited, diverged (see spec §7) · — = N/A

| # | Stitch title | Slug | Target Dart file | Spec | Code | Verified | Screen ID |
|---|---|---|---|---|---|---|---|
| 1 | דף הבית (Home Dashboard) | `home-dashboard` | `home_screen.dart` | ✓ | ✓ | ⚠ (HD1–HD8, §7) | `4cbae145a6a34837ab47bdec527b10df` |
| 2 | חיפוש וסריקה (Search & Scan) | `search-scan` | `search_scan_screen.dart` | ✓ | ✓ | ⚠ (SS1–SS8, §7.8) | `b075f5753b7948a9bb115786f1b922ed` |
| 3 | חיפוש פעיל - תוצאות (Active Search) | `active-search-results` | `search_screen.dart` | ✓ | ✓ | ⚠ (AS1–AS8, §7.9) | `45d081ae18b143ca8e15b12469468d9a` |
| 4 | פרטי מוצר - בטוח (Product Details — Safe) | `product-details-safe` | `product_details.dart` | ✓ | ✓ | ⚠ (SF1–SF9, §7.9) | `eda2fffaccee4c059519033acc27e842` |
| 5 | פרטי מוצר - הימנע (Product Details — Avoid) | `product-details-avoid` | `product_details.dart` | ✓ | ✓ | ⚠ (AV1–AV9, §7.8 — SEVERE: pink banner not red) | `9aa55d9704a849468749a219d7e81dc7` |
| 6 | הוספת מוצר - שלב 1 (Barcode) | `add-product-step-1-barcode` | `add_product_screen.dart` | ✓ | ✓ | ⚠ (S1-1–S1-14, §7.10) | `ffdb6626d62944548656cee7494af945` |
| 7 | הוספת מוצר - שלב 2 (Photos) | `add-product-step-2-photos` | `add_product_screen.dart` | ✓ | ✓ | ⚠ (S2-1–S2-11, §7.9) | `bbda540783f94818b581f4d7dd8f7811` |
| 8 | הוספת מוצר - שלב 3 (Contains) | `add-product-step-3-contains` | `add_product_screen.dart` | ✓ | ✓ | ⚠ (S3-1–S3-10, §7.8) | `0161b2a94e354831baac041620b68d6d` |
| 9 | הוספת מוצר - שלב 4 (May Contain) | `add-product-step-4-may-contain` | `add_product_screen.dart` | ✓ | ✓ | ⚠ (S4-1–S4-11, §7.9 — SEVERE: submit no-op) | `723494ade01f454e96e9ae22524ca7cb` |
| 10 | הוספה הצליחה (Add Product Success) | `add-product-success` | `add_product_success_screen.dart` (absent) | ✓ | ✗ | ⚠ (SU-1–SU-10, §7.7 — SEVERE: screen not built) | `7f85b05267594677827497af62b8de1e` |
| 11 | Community Hub | `community-hub` | `community_screen.dart` | ✓ | ✓ | ⚠ (CH1–CH13, §7.8) | `a8c9931205604870a6ecee4456c6e808` |
| 12 | Community Review | `community-review` | _no dedicated screen_ | ✓ | ✗ | ⚠ (CR1–CR11, §7.6 — SEVERE: not implemented) | `521b195cd91443849b0f983487ef5f9c` |
| 13 | המשך סקירה (Review Next Item) | `review-next-item` | `review_next_screen.dart` | ✓ | ✓ | ⚠ (RN1–RN12, §7.7) | `2d3d5126490f4c5496fc194b35a865a7` |
| 14 | הכל נבדק! (Review All Clear) | `review-all-clear` | `all_clear_banner.dart` widget | ✓ | ✓ | ⚠ (AC1–AC8, §7.8 — screen not built, only a banner) | `3c43a140383248dfa16bbd286c79f4f2` |
| 15 | Settings & Profile | `settings-profile` | `settings_screen.dart` | ✓ | ✓ | ⚠ (ST1–ST12, §7.8 — filter no-op) | `3a2bc2f1aac1444886d44def38b72bc4` |
| 16 | Onboarding — Allergen Selection | `onboarding-allergen-selection` | `onboarding_screen.dart` | ✓ | ✓ | ⚠ (OB1–OB4, §7.8 — minor) | `565153749ead4760b7cb331cf3ae28a9` |
| 17 | Contact Us (Updated) | `contact-us` | `contact_screen.dart` | ✓ | ✓ | ⚠ (CC1–CC7, §7.7 — partial) | `5a9bc40c2d8a46c7b760d2725cde2cf4` |
| 18 | Report Issue | `report-issue` | `feedback_screen.dart` | ✓ | ✓ | ⬜ | `a6741117c9f14b84938c4abda143a5dd` |
| 19 | דיווח נשלח בהצלחה (Success Confirmation) | `report-success` | `feedback_success_screen.dart` | ✓ | ✓ | ⚠ (RS1–RS9, §7.7 — WRONG screen: file renders review-next-item) | `4bb210f9ac7143e0a6d1558dd950a62d` |
| 20 | User Navigation Drawer (Right) | `nav-drawer-user` | `drawer_user_screen.dart` | ✓ | ✓ | ⚠ (DU1–DU12, §7.7) | `6e8f8bcbe71548b0a7f1bf6920de7343` |
| 21 | Admin Navigation Drawer (Right) | `nav-drawer-admin` | _no AdminNavigationDrawer_ | ✓ | ✗ | ⚠ (DA1–DA12, §7.8 — SEVERE: not implemented) | `b4224114bb2e4ff6a2cca1db65a401f6` |
| 22 | Manage Trusted Brands (Admin) | `admin-trusted-brands` | `admin_brands_screen.dart` | ✓ | ✓ | ⚠ (TB1–TB14, §7.8 — toggle no-op) | `59e6d26de9a64bec9123ec396aae32fc` |
| 23 | SafeBite — App Cover (390w) | `app-cover` | — excluded (marketing cover) | ✓ | — | — | `55abf4d7f4be4caa8e291b52c18bff6f` |

## Derived screens (added 2026-05-20; implemented 2026-05-21 PR #9)

These were referenced by existing specs as states / sub-screens / modals but
had no per-screen file. Added in the post-review sweep, implemented in
`feat/tier1-screens`. Verified column reflects that implementations were built
directly from the spec art in the same session.

| Slug | Source | Target Dart file | Spec | Code | Verified |
|---|---|---|---|---|---|
| `product-details-caution` | `product-details-safe §5` (promoted) | `product_details.dart` | ✓ | ✓ | ⚠ (D1–D8, §7.3) |
| `onboarding-step-2-notifications` | `onboarding-allergen-selection §7.4` | `onboarding_step_2_screen.dart` | ✓ | ✓ | ✓ |
| `allergen-management` | `settings-profile §7.5` | `allergen_management_screen.dart` | ✓ | ✓ | ✓ |
| `profile-edit` | `settings-profile §4.1` | `widgets/profile_edit_sheet.dart` | ✓ | ✓ | ✓ |
| `admin-brand-form` | `admin-trusted-brands §5.6/5.7/7.7` | `widgets/admin_brand_form_sheet.dart` | ✓ | ✓ | ✓ |
| `_dialogs` (D-1/D-2/D-3) | Multiple §5 sections | `utils/app_dialogs.dart` | ✓ | ✓ | ✓ |

> **product-details-caution** is the only Tier 1 item with Verified ⬜ — the caution
> state was already in `product_details.dart` before the spec was written. **Audited
> 2026-05-24: diverged on 8 axes (D1–D8), Verified stays ⬜.** See
> `product-details-caution.md §7.3` for the delta table; fixes deferred to Batch H
> (shared with Safe/Avoid). See ROADMAP item #2 for the parity-check task.

## Backlog (missing screens, dialogs, panels)

Full tracker below. `_missing-screens.md` remains the detailed backlog (with the
☐/◐/◑/☑ pipeline legend and prompt cross-links); this section rolls it up into
the same Stitch/Code/Verified dimensions used above. Stitch generation prompts:
see [_stitch-prompts.md](_stitch-prompts.md). Tier definitions: Tier 1 =
blockers in active implementation paths; Tier 2 = per-screen empty/error/loading
states; Tier 3 = drawer destinations + sub-screens promoted by tap targets.

### Tier 1 backlog (remaining)

| Item | Spec | Stitch | Code | Verified |
|---|---|---|---|---|
| FavoritesScreen — list variant | ✗ | ✓ (`1a06439f…`) | ✗ | — |

> FavoritesScreen **empty** variant is implemented (`favorites_screen.dart`, PR #9);
> the **list** variant (populated favorites) has Stitch art but no code yet — it
> waits on the "add to favorites" interaction (see Cross-cutting below).

### Tier 2 — per-screen states (none drawn, none implemented)

All Tier 2 items are **not designed in Stitch and not implemented** → nothing to
verify yet. Roadmap item #1 (generate Tier 2 Stitch art) must land first, then
implementation, then verification.

| Item | Referenced by | Stitch | Code | Verified |
|---|---|---|---|---|
| active-search-results — empty | `active-search-results.md §5.3` | ✗ | ✗ | — |
| active-search-results — error (network) | `active-search-results.md §5.4` | ✗ | ✗ | — |
| active-search-results — loading (shimmer) | `active-search-results.md §5.1` | ✗ | ✗ | — |
| community-review — empty queue | `community-review.md §7.3` | ✗ | ✗ | — |
| search-scan — camera permission denied | `search-scan.md §5` | ✗ | ✗ | — |
| search-scan — recently-scanned empty | `search-scan.md §7.4` | ✗ | ✗ | — |
| add-product step-1 — camera unavailable | `add-product-step-1-barcode.md §7.8` | ✗ | ✗ | — |
| add-product step-1 — inline validation | `add-product-step-1-barcode.md §7.6` | ✗ | ✗ | — |
| add-product step-2 — thumbnail-filled tile | `add-product-step-2-photos.md §4` | ✗ | ✗ | — |
| add-product step-2 — upload error / retry | `add-product-step-2-photos.md §5` | ✗ | ✗ | — |
| add-product step-4 — submit loading + error | `add-product-step-4-may-contain.md §5` | ✗ | ✗ | — |
| admin-trusted-brands — empty list | `admin-trusted-brands.md §5.3` | ✗ | ✗ | — |
| product-details — image load fallback | `product-details-safe.md §7` | ✗ | ✗ | — |
| review-next-item — loading next (shimmer) | `review-next-item.md §5.2` | ✗ | ✗ | — |
| home-dashboard — empty activity feed | `home-dashboard.md §5` | ✗ | ✗ | — |
| home-dashboard — loading (shimmer) | `home-dashboard.md §5` | ✗ | ✗ | — |
| community-hub — loading / error stats | `community-hub.md §5.2, §5.3` | ✗ | ✗ | — |
| settings — no-profile skeleton | `settings-profile.md §5.7` | ✗ | ✗ | — |
| contact-us — success state | `contact-us.md §5.5` | ✗ | ✗ | — |

### Tier 3 — drawer / settings destinations (none drawn, none implemented)

| Item | Referenced by | Stitch | Code | Verified |
|---|---|---|---|---|
| ScanHistoryScreen | `nav-drawer-user.md §3` | ✗ | ✗ | — |
| SavedProductsScreen | `nav-drawer-user.md §3` | ✗ | ✗ | — |
| MyReviewsScreen | `nav-drawer-user.md §3` | ✗ | ✗ | — |
| HelpCenterScreen | `nav-drawer-user.md §3`, `settings-profile.md §4.3` | ✗ | ✗ | — |
| AboutScreen | `nav-drawer-user.md §3`, `settings-profile.md §4.3` | ✗ | ✗ | — |
| AppPreferencesScreen | `settings-profile.md §4.3` | ✗ | ✗ | — |
| ContributionHistoryScreen | `settings-profile.md §4.3` | ✗ | ✗ | — |
| AdminDashboardScreen | `nav-drawer-admin.md §3` | ✗ | ✗ | — |
| ReportsScreen | `nav-drawer-admin.md §3` | ✗ | ✗ | — |
| SystemSettingsScreen | `nav-drawer-admin.md §3` | ✗ | ✗ | — |
| ProductScansScreen | `nav-drawer-admin.md §3` | ✗ | ✗ | — |
| CommunityManagementScreen | `nav-drawer-admin.md §3` | ✗ | ✗ | — |
| HelpTipsScreen | `search-scan.md §7.3` | ✗ | ✗ | — |
| ScanInstructionsScreen | `search-scan.md §7.3` | ✗ | ✗ | — |
| ActiveDiscussionScreen | `community-hub.md §7.2` | ✗ | ✗ | — |
| WeeklyTipScreen | `community-hub.md §7.2` | ✗ | ✗ | — |

### Cross-cutting (none drawn, none implemented)

| Item | Referenced by | Stitch | Code | Verified |
|---|---|---|---|---|
| Branded SnackBar / toast styles | multiple | ✗ | ✗ | — |
| "Add to favorites" interaction | `product-details-*.md` | ✗ | ✗ | — |
| contact-us subject picker | `contact-us.md §4.3` | ✗ | ✗ | — |

## Shared components

See [_components-glossary.md](_components-glossary.md):
`#status-pill`, `#allergen-chip`, `#app-bar`, `#bottom-nav`, `#primary-button`,
`#wizard-chrome`, `#product-row`, `#filter-chip`, `#success-badge-pair`.

Confirmation dialogs (`_dialogs.md`): `#d-1` wizard-exit, `#d-2` logout,
`#d-3` brand-delete.

Target framework: **Material 3** (`useMaterial3: true`) per
[DD-12](_design-decisions.md#dd-12-material-3-adoption). See
[_components-glossary.md#material-3-adoption](_components-glossary.md#material-3-adoption)
for the required `ColorScheme` token mapping.

## Cross-screen decisions

Resolved inconsistencies are recorded in
[_design-decisions.md](_design-decisions.md). Decisions DD-1..DD-11 closed the
spec-batch open questions; DD-12..DD-17 (added 2026-05-20) close the post-review
sweep: M3 adoption, success-token unification, wizard-chip selected style,
drawer footer simplification, app-bar variant set, new shared components,
status-pill padding.
