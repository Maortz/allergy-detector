# Stitch Screens — Spec Tracker

Tracker for the per-screen Stitch spec set. Reading/writing order = row order.

**Column legend:**
- **Spec** ✓ = `.md` spec file exists in this directory
- **Code** ✓ = Dart implementation shipped to `master`
- **Verified** ✓ = implementation checked against Stitch art, known aligned · ⬜ = not yet verified · — = N/A

| # | Stitch title | Slug | Target Dart file | Spec | Code | Verified | Screen ID |
|---|---|---|---|---|---|---|---|
| 1 | דף הבית (Home Dashboard) | `home-dashboard` | `home_screen.dart` | ✓ | ✓ | ⬜ | `4cbae145a6a34837ab47bdec527b10df` |
| 2 | חיפוש וסריקה (Search & Scan) | `search-scan` | `search_scan_screen.dart` | ✓ | ✓ | ⬜ | `b075f5753b7948a9bb115786f1b922ed` |
| 3 | חיפוש פעיל - תוצאות (Active Search) | `active-search-results` | `search_screen.dart` | ✓ | ✓ | ⬜ | `45d081ae18b143ca8e15b12469468d9a` |
| 4 | פרטי מוצר - בטוח (Product Details — Safe) | `product-details-safe` | `product_details.dart` | ✓ | ✓ | ⬜ | `eda2fffaccee4c059519033acc27e842` |
| 5 | פרטי מוצר - הימנע (Product Details — Avoid) | `product-details-avoid` | `product_details.dart` | ✓ | ✓ | ⬜ | `9aa55d9704a849468749a219d7e81dc7` |
| 6 | הוספת מוצר - שלב 1 (Barcode) | `add-product-step-1-barcode` | `add_product_screen.dart` | ✓ | ✓ | ⬜ | `ffdb6626d62944548656cee7494af945` |
| 7 | הוספת מוצר - שלב 2 (Photos) | `add-product-step-2-photos` | `add_product_screen.dart` | ✓ | ✓ | ⬜ | `bbda540783f94818b581f4d7dd8f7811` |
| 8 | הוספת מוצר - שלב 3 (Contains) | `add-product-step-3-contains` | `add_product_screen.dart` | ✓ | ✓ | ⬜ | `0161b2a94e354831baac041620b68d6d` |
| 9 | הוספת מוצר - שלב 4 (May Contain) | `add-product-step-4-may-contain` | `add_product_screen.dart` | ✓ | ✓ | ⬜ | `723494ade01f454e96e9ae22524ca7cb` |
| 10 | הוספה הצליחה (Add Product Success) | `add-product-success` | `add_product_screen.dart` | ✓ | ✓ | ⬜ | `7f85b05267594677827497af62b8de1e` |
| 11 | Community Hub | `community-hub` | `community_screen.dart` | ✓ | ✓ | ⬜ | `a8c9931205604870a6ecee4456c6e808` |
| 12 | Community Review | `community-review` | `review_next_screen.dart` | ✓ | ✓ | ⬜ | `521b195cd91443849b0f983487ef5f9c` |
| 13 | המשך סקירה (Review Next Item) | `review-next-item` | `review_next_screen.dart` | ✓ | ✓ | ⬜ | `2d3d5126490f4c5496fc194b35a865a7` |
| 14 | הכל נבדק! (Review All Clear) | `review-all-clear` | `all_clear_banner.dart` widget | ✓ | ✓ | ⬜ | `3c43a140383248dfa16bbd286c79f4f2` |
| 15 | Settings & Profile | `settings-profile` | `settings_screen.dart` | ✓ | ✓ | ⬜ | `3a2bc2f1aac1444886d44def38b72bc4` |
| 16 | Onboarding — Allergen Selection | `onboarding-allergen-selection` | `onboarding_screen.dart` | ✓ | ✓ | ⬜ | `565153749ead4760b7cb331cf3ae28a9` |
| 17 | Contact Us (Updated) | `contact-us` | `contact_screen.dart` | ✓ | ✓ | ⬜ | `5a9bc40c2d8a46c7b760d2725cde2cf4` |
| 18 | Report Issue | `report-issue` | `feedback_screen.dart` | ✓ | ✓ | ⬜ | `a6741117c9f14b84938c4abda143a5dd` |
| 19 | דיווח נשלח בהצלחה (Success Confirmation) | `report-success` | `feedback_success_screen.dart` | ✓ | ✓ | ⬜ | `4bb210f9ac7143e0a6d1558dd950a62d` |
| 20 | User Navigation Drawer (Right) | `nav-drawer-user` | `drawer_user_screen.dart` | ✓ | ✓ | ⬜ | `6e8f8bcbe71548b0a7f1bf6920de7343` |
| 21 | Admin Navigation Drawer (Right) | `nav-drawer-admin` | `navigation_drawer.dart` (admin variant) | ✓ | ✓ | ⬜ | `b4224114bb2e4ff6a2cca1db65a401f6` |
| 22 | Manage Trusted Brands (Admin) | `admin-trusted-brands` | `admin_brands_screen.dart` | ✓ | ✓ | ⬜ | `59e6d26de9a64bec9123ec396aae32fc` |
| 23 | SafeBite — App Cover (390w) | `app-cover` | — excluded (marketing cover) | ✓ | — | — | `55abf4d7f4be4caa8e291b52c18bff6f` |

## Derived screens (added 2026-05-20; implemented 2026-05-21 PR #9)

These were referenced by existing specs as states / sub-screens / modals but
had no per-screen file. Added in the post-review sweep, implemented in
`feat/tier1-screens`. Verified column reflects that implementations were built
directly from the spec art in the same session.

| Slug | Source | Target Dart file | Spec | Code | Verified |
|---|---|---|---|---|---|
| `product-details-caution` | `product-details-safe §5` (promoted) | `product_details.dart` | ✓ | ✓ | ⬜ |
| `onboarding-step-2-notifications` | `onboarding-allergen-selection §7.4` | `onboarding_step_2_screen.dart` | ✓ | ✓ | ✓ |
| `allergen-management` | `settings-profile §7.5` | `allergen_management_screen.dart` | ✓ | ✓ | ✓ |
| `profile-edit` | `settings-profile §4.1` | `widgets/profile_edit_sheet.dart` | ✓ | ✓ | ✓ |
| `admin-brand-form` | `admin-trusted-brands §5.6/5.7/7.7` | `widgets/admin_brand_form_sheet.dart` | ✓ | ✓ | ✓ |
| `_dialogs` (D-1/D-2/D-3) | Multiple §5 sections | `utils/app_dialogs.dart` | ✓ | ✓ | ✓ |

> **product-details-caution** is the only Tier 1 item with Verified ⬜ — the caution
> state was already in `product_details.dart` before the spec was written. See
> ROADMAP item #2 for the parity check task.

## Backlog (missing screens, dialogs, panels)

Full inventory of items referenced by an existing spec but not yet drawn by
Stitch and/or not yet specced — see [_missing-screens.md](_missing-screens.md).
Stitch generation prompts for Tier 1 items: see
[_stitch-prompts.md](_stitch-prompts.md). Tier 1 = blockers in active
implementation paths; Tier 2 = empty/error/loading states; Tier 3 = drawer
destinations + sub-screens promoted by tap targets.

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
