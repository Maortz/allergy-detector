# Cross-Screen Design Decisions

Resolved inconsistencies. Each entry: element · conflicting variants + source
screens · CHOSEN canonical form · rationale · date.

---

## DD-1 · status-pill vs. Avoid banner

- **Element:** product safety-verdict indicator.
- **Conflict:**
  - `home-dashboard` — compact rounded **status-pill** ("להימנע") inside product cards.
  - `product-details-avoid` — full-width red **banner** ("הימנע – מכיל אלרגנים"), no pill.
- **CHOSEN:** **Two distinct components.** `status-pill` = compact badge for
  cards/lists (glossary `#status-pill`). `avoid-banner` = full-width detail-header
  band, screen-specific to product-details (documented in
  `product-details-avoid.md` §2/§4, not a shared glossary component). Detail
  screens never render the compact pill.
- **Rationale:** Matches what the Stitch designs actually render; the detail
  screen intentionally uses a stronger danger signal. No forced unification.
- **Date:** 2026-05-19.

## DD-2 · bottom-nav tab 4 identity

- **Element:** 4th bottom-navigation tab.
- **Conflict:**
  - App `MainContainer` — tab 4 = **Settings**.
  - Stitch designs — tab 4 = **מועדפים / Favorites**.
- **CHOSEN:** **Favorites (follow Stitch).** Canonical bottom-nav =
  בית / סריקה / קהילה / מועדפים (Home / Scan / Community / Favorites,
  index 0–3). **Settings** is reached via the navigation drawer (which exists
  as its own Stitch screen, `nav-drawer-user`), not the bottom nav.
- **Rationale:** These specs are an implementation source-of-truth from Stitch
  design intent; the app code is the thing to realign. The drawer already
  provides a Settings entry point.
- **Date:** 2026-05-19.
