# Cross-Screen Design Decisions

Resolved inconsistencies. Each entry: element · conflicting variants + source
screens · CHOSEN canonical form · rationale · date.

---

## DD-1 · status-pill vs. Avoid banner

- **Element:** product safety-verdict indicator.
- **Conflict:**
  - `home-dashboard` — compact rounded **status-pill** ("להימנע") inside product cards.
  - `product-details-avoid` — full-width red **banner** ("הימנע – מכיל אלרגנים"), no pill.
- **CHOSEN (revised 2026-05-19):** **Two distinct components, state-scoped.**
  `status-pill` = compact badge (glossary `#status-pill`) used in cards/lists
  AND on the **Safe and Caution** product-detail headers (safe/caution
  variants). `avoid-banner` = full-width detail-header band used **only on the
  Avoid** product-detail state (screen-specific, documented in
  `product-details-avoid.md` §2/§4; not a shared glossary component).
- **Rationale:** The Safe Stitch screen renders a compact green pill on its
  header; only Avoid uses the full-width banner. The original "detail screens
  never render the pill" over-generalized from the Avoid screen alone. Avoid
  keeps the stronger banner for its danger signal.
- **Date:** 2026-05-19 (revised same day after Safe-screen review).

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

## DD-3 · status-pill label model

- **Element:** status-pill text content.
- **Conflict:** glossary fixes labels בטוח/זהירות/להימנע; screens render
  contextual strings ("בטוח לצריכה", "מכיל אגוזי לוז", "חשש לגלוטן",
  "בטוח - ללא אלרגנים עבורך").
- **CHOSEN:** **Fixed short labels only.** The pill always shows exactly
  בטוח / זהירות / להימנע (per status variant). Any longer contextual string is
  a **separate adjacent text element**, not part of the pill component.
- **Rationale:** Keeps the shared pill simple and uniform; contextual messaging
  is screen-specific copy, specced in that screen's §2/§3, not in the pill.
- **Date:** 2026-05-19.

## DD-4 · Divergent bottom-nav tab sets

- **Element:** bottom navigation tab set.
- **Conflict:** several screens' extracted HTML show non-canonical tabs
  (e.g. חיפוש/סריקה/מועדפים/הגדרות; בית/סריקה/חיפוש/פרופיל).
- **CHOSEN:** **DD-2 is canonical everywhere** (בית/סריקה/קהילה/מועדפים,
  index 0–3). Divergent tab sets in screen HTML are stale Stitch artifacts. Each
  affected spec references `_components-glossary.md#bottom-nav` and records the
  observed divergence as a delta in its §7 — it does not re-spec the nav.
- **Rationale:** One nav model; design source-of-truth = DD-2. Artifacts must
  not leak into 23 specs.
- **Date:** 2026-05-19.

## DD-5 · Add-Product wizard chrome

- **Element:** wizard shell (progress indicator, app-bar title, nav buttons).
- **Conflict:** step 1 numbered-node stepper vs step 3 linear progress bar;
  title "הוספת מוצר - שלב N" vs "הוספת מוצר חדש"; back button absent step 2,
  present step 3; continue icon `arrow_back` vs `chevron_left`.
- **CHOSEN (canonical wizard chrome):**
  - Progress: **linear progress bar** (filled track + step %), all 4 steps.
  - App-bar title: **"הוספת מוצר חדש"** + a step subtitle ("שלב N מתוך 4" / the
    step's name), all steps.
  - Continue button: `chevron_left` trailing icon (RTL forward).
  - Back ("חזרה", outlined): present on steps **2, 3, 4** (not step 1).
  - Documented as `#wizard-chrome` in `_components-glossary.md`. Each step spec
    references it and notes its own Stitch delta in §7.
- **Rationale:** One coherent wizard; step 3 (an exemplar) already uses the
  linear bar; "הוספת מוצר חדש" + subtitle scales to any step count.
- **Date:** 2026-05-19.
