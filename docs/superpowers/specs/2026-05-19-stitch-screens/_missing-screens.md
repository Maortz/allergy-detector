# Missing Screens / Dialogs / Panels — Backlog

Single source of truth for everything referenced by an existing spec but not
yet drawn by Stitch and/or not yet specced. Update this file as items move
through the pipeline.

**Status legend:**
- ☐ todo — neither specced nor drawn
- ◐ specced — has its own `.md` file in this directory, but no Stitch art yet
- ◑ drawn — Stitch art exists but no app implementation yet
- ☑ done — specced + Stitch art + (eventual) implementation matched
- ⊘ excluded — explicitly out of scope

Update the **Stitch URL** column when Stitch generates a screen
(format `projects/16588854804615693446/screens/<id>`).

---

## Tier 1 — Blockers (in active implementation paths)

| Status | Item | Spec file | Stitch URL |
|---|---|---|---|
| ◐ | product-details-caution | `product-details-caution.md` | — |
| ◐ | onboarding-step-2-notifications | `onboarding-step-2-notifications.md` | — |
| ◐ | allergen-management | `allergen-management.md` | — |
| ◐ | profile-edit (modal sheet) | `profile-edit.md` | — |
| ◐ | admin-brand-form (modal sheet) | `admin-brand-form.md` | — |
| ◐ | D-1 wizard-exit dialog | `_dialogs.md#d-1` | — |
| ◐ | D-2 logout dialog | `_dialogs.md#d-2` | — |
| ◐ | D-3 brand-delete dialog | `_dialogs.md#d-3` | — |
| ☐ | Photo source picker (camera/gallery sheet) | — | — |
| ☐ | FavoritesScreen (bottom-nav tab 4) | — | — |

---

## Tier 2 — States (quality polish; per-screen empty / error / loading)

| Status | Item | Referenced by | Stitch URL |
|---|---|---|---|
| ☐ | active-search-results — empty ("לא נמצאו תוצאות") | `active-search-results.md §5.3` | — |
| ☐ | active-search-results — error (network) | `active-search-results.md §5.4` | — |
| ☐ | active-search-results — loading (shimmer rows) | `active-search-results.md §5.1` | — |
| ☐ | community-review — empty queue ("אין מוצרים לסקירה כרגע") | `community-review.md §7.3` | — |
| ☐ | search-scan — camera permission denied | `search-scan.md §5` | — |
| ☐ | search-scan — recently-scanned empty (confirm "hide row" final) | `search-scan.md §7.4` | — |
| ☐ | add-product step-1 — camera unavailable placeholder | `add-product-step-1-barcode.md §7.8` | — |
| ☐ | add-product step-1 — inline validation errors | `add-product-step-1-barcode.md §7.6` | — |
| ☐ | add-product step-2 — photo tile thumbnail-filled state | `add-product-step-2-photos.md §4` | — |
| ☐ | add-product step-2 — upload error / retry | `add-product-step-2-photos.md §5` | — |
| ☐ | add-product step-4 — submit loading + error | `add-product-step-4-may-contain.md §5` | — |
| ☐ | admin-trusted-brands — empty list | `admin-trusted-brands.md §5.3` | — |
| ☐ | product-details — image load fallback | `product-details-safe.md §7` | — |
| ☐ | review-next-item — loading next item (shimmer card) | `review-next-item.md §5.2` | — |
| ☐ | home-dashboard — empty activity feed | `home-dashboard.md §5` | — |
| ☐ | home-dashboard — loading (shimmer hero + activity) | `home-dashboard.md §5` | — |
| ☐ | community-hub — loading / error stats | `community-hub.md §5.2, §5.3` | — |
| ☐ | settings — logged-out / no-profile skeleton | `settings-profile.md §5.7` | — |
| ☐ | contact-us — success state (deferred per §7.4) | `contact-us.md §5.5` | — |

---

## Tier 3 — Out-of-batch destinations (referenced by drawer / settings)

### User drawer destinations

| Status | Item | Referenced by | Stitch URL |
|---|---|---|---|
| ☐ | ScanHistoryScreen (היסטוריית סריקה) | `nav-drawer-user.md §3` row 2 | — |
| ☐ | SavedProductsScreen (מוצרים שמורים) | `nav-drawer-user.md §3` row 3 | — |
| ☐ | MyReviewsScreen (ביקורות שלי) | `nav-drawer-user.md §3` row 4 | — |
| ☐ | HelpCenterScreen (מרכז עזרה) | `nav-drawer-user.md §3` row 5, `settings-profile.md §4.3` | — |
| ☐ | AboutScreen (אודות) | `nav-drawer-user.md §3` row 6, `settings-profile.md §4.3` | — |
| ☐ | AppPreferencesScreen (העדפות אפליקציה) | `settings-profile.md §4.3` | — |
| ☐ | ContributionHistoryScreen (היסטוריית תרומות) | `settings-profile.md §4.3` | — |

### Admin drawer destinations

| Status | Item | Referenced by | Stitch URL |
|---|---|---|---|
| ☐ | AdminDashboardScreen (לוח בקרה) — includes the metrics panel + announcements strip per `nav-drawer-admin.md §7.4` | `nav-drawer-admin.md §3` row 1 | — |
| ☐ | ReportsScreen (דיווחים) | `nav-drawer-admin.md §3` row 3 | — |
| ☐ | SystemSettingsScreen (הגדרות מערכת) | `nav-drawer-admin.md §3` row 4 | — |
| ☐ | ProductScansScreen (סריקות מוצרים) | `nav-drawer-admin.md §3` row 5 | — |
| ☐ | CommunityManagementScreen (ניהול קהילה) | `nav-drawer-admin.md §3` row 6 | — |

### Sub-screens promoted by tap targets

| Status | Item | Referenced by | Stitch URL |
|---|---|---|---|
| ☐ | HelpTipsScreen (search-scan info card destination) | `search-scan.md §7.3` (MVP shows "בקרוב" toast) | — |
| ☐ | ScanInstructionsScreen (search-scan info card destination) | `search-scan.md §7.3` (MVP shows "בקרוב" toast) | — |
| ☐ | ActiveDiscussionScreen (community-hub insight card) | `community-hub.md §7.2` (MVP non-tappable) | — |
| ☐ | WeeklyTipScreen (community-hub insight card) | `community-hub.md §7.2` (MVP non-tappable) | — |

---

## Cross-cutting

| Status | Item | Referenced by | Stitch URL |
|---|---|---|---|
| ☐ | Branded SnackBar / toast styles (success / error / "בקרוב") | multiple screens | — |
| ☐ | "Add to favorites" interaction on product-details (icon button or app-bar slot) | `product-details-*.md` (implied by FavoritesScreen) | — |
| ☐ | Subject picker for contact-us dropdown (if custom-styled vs OS-native) | `contact-us.md §4.3` | — |

---

## How to use this file

1. **When you ask Stitch for a new screen:** find the row, copy the prompt from `_stitch-prompts.md` (or inline if not yet captured), paste into Stitch.
2. **When Stitch returns art:** flip the status to ◑, fill in the **Stitch URL** column.
3. **When implementation lands:** flip status to ☑.
4. **When you decide an item is out of scope:** flip to ⊘ with a one-line rationale appended.

Cross-link from per-screen specs' §7 entries to this file when an open
question maps to a missing tile here — e.g. `see _missing-screens.md` instead
of re-flagging.
