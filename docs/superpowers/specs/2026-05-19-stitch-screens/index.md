# Stitch Screen Specs — Index
Design system: **Clinical Clarity RTL**
Stitch project: `16588854804615693446`
Spec batch started: 2026-05-19

Rows marked ☑ have a complete spec file in this directory.
Rows marked ☐ are pending.

| # | Status | Slug | Hebrew title | Stitch screen ID | Dart file |
|---|---|---|---|---|---|
| 1 | ☑ | `home-dashboard` | דף הבית | `4cbae145a6a34837ab47bdec527b10df` | home_screen.dart |
| 2 | ☐ | `onboarding-welcome` | ברוכים הבאים | TBD | onboarding_screen.dart |
| 3 | ☐ | `onboarding-allergen-select` | בחירת אלרגנים | TBD | onboarding_screen.dart |
| 4 | ☐ | `search-scan-idle` | חיפוש וסריקה | TBD | search_scan_screen.dart |
| 5 | ☑ | `product-details-avoid` | פרטי מוצר - הימנע | `9aa55d9704a849468749a219d7e81dc7` | product_details.dart |
| 6 | ☐ | `product-details-safe` | פרטי מוצר - בטוח | TBD | product_details.dart |
| 7 | ☐ | `product-details-caution` | פרטי מוצר - זהירות | TBD | product_details.dart |
| 8 | ☑ | `add-product-step-3-contains` | הוספת מוצר - שלב 3 | `0161b2a94e354831baac041620b68d6d` | add_product_screen.dart |
| 9 | ☐ | `add-product-step-1` | הוספת מוצר - שלב 1 | TBD | add_product_screen.dart |
| 10 | ☐ | `add-product-step-2` | הוספת מוצר - שלב 2 | TBD | add_product_screen.dart |
| 11 | ☐ | `add-product-step-4-may-contain` | הוספת מוצר - שלב 4 | TBD | add_product_screen.dart |
| 12 | ☐ | `settings` | הגדרות | TBD | settings_screen.dart |
| 13 | ☐ | `community` | קהילה | TBD | community_screen.dart |
| 14 | ☐ | `active-search-results` | תוצאות חיפוש | TBD | active_search_screen.dart |
| 15 | ☐ | `profile-allergen-edit` | עריכת אלרגנים | TBD | settings_screen.dart |
| 16 | ☐ | `app-cover` | מסך פתיחה | TBD | main.dart / splash |
| 17 | ☐ | (reserved) | — | — | — |
| 18 | ☐ | (reserved) | — | — | — |
| 19 | ☐ | (reserved) | — | — | — |
| 20 | ☐ | (reserved) | — | — | — |
| 21 | ☐ | (reserved) | — | — | — |
| 22 | ☐ | (reserved) | — | — | — |
| 23 | ☐ | (reserved) | — | — | — |

## Shared components
See [_components-glossary.md](_components-glossary.md) for the locked definitions of:
- `#status-pill` — safe/caution/avoid verdict badge
- `#allergen-chip` — display / detected / wizard-toggle variants
- `#app-bar` — brand / detail / wizard variants
- `#bottom-nav` — 4-tab persistent bar
- `#primary-button` — standard / avoid variants

## Known conflicts requiring user decision
1. **`#status-pill` vs. full-width Avoid banner** — detail screen uses a banner, not the pill. Are these unified or separate components?
2. **`#bottom-nav` tab 4** — app has "Settings"; design shows "מועדפים (Favorites)". Which is correct?

See individual glossary entries for full conflict documentation.
