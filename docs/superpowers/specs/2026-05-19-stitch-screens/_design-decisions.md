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
  index 0–3). **Settings** is NOT a bottom-nav tab. *(Refined 2026-05-19, see
  DD-11* for how Settings is actually reached.)
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

## DD-6 · bottom-nav active-tab indicator

- **Element:** active tab visual treatment in the bottom navigation.
- **Conflict:** `community-hub` renders the active tab inside a rounded pill
  background; glossary + `home-dashboard`/`product-details`/`search-scan`
  describe a flat active style (no pill).
- **CHOSEN:** **Pill indicator.** The active tab shows a rounded-rectangle
  background (Material-3 style) behind the icon+label. `_components-glossary.md`
  `#bottom-nav` updated to the pill form; earlier screen specs reference the
  glossary and inherit this (flat mentions in their prose are superseded).
- **Rationale:** User-selected canonical; aligns with Material 3 `NavigationBar`.
- **Date:** 2026-05-19.

## DD-7 · Allergen Hebrew name plurality — DEFERRED (data/PM)

- **Element:** `allergen.nameHe` form (plural vs singular/construct).
- **Conflict:** onboarding shows plural (שקדים, פיסטוקים, פקאנים, אגוזי מלך);
  glossary/other screens use singular (שקד, פיסטוק, פקן, אגוז מלך).
- **CHOSEN:** **Deferred to the data/PM owner.** Specs reference allergens by
  **ID**, not by hard-coded `nameHe`. The canonical Hebrew form is owned by the
  Supabase seed (`supabase/seed.sql`) and is OUT OF SCOPE for these UI specs.
  Spec prose may show either form as illustrative; implementation binds
  `allergen.nameHe` from data.
- **Status:** OPEN (non-blocking for specs). Owner: seed-SQL / PM.
- **Date:** 2026-05-19.

## DD-8 · App-bar brand text

- **Element:** brand/logo text in the app bar.
- **Conflict:** screens variously render "בטיחות מזון", "בדיקת אלרגנים",
  "בטוח לאכול".
- **CHOSEN:** **Canonical = "בטוח לאכול"** (Inter Medium 16 pt, `#00478D`),
  per `_components-glossary.md#app-bar` brand variant. All other strings are
  stale Stitch artifacts; affected specs note the delta in §7, do not re-spec.
- **Rationale:** Single brand identity; "בטוח לאכול" is the established app
  name in CLAUDE.md and the home screen.
- **Date:** 2026-05-19 (coordinator artifact-resolution; flag if a separate
  admin brand identity is ever desired).

## DD-9 · Peanut (בוטנים) allergen icon

- **Element:** Material icon for בוטנים / Peanuts in `allergen-chip`.
- **Conflict:** glossary + `add-product-step-3-contains` use `park`; the
  step-4 screenshot renders what looks like `spa`.
- **CHOSEN:** **`park`** (glossary canonical, matches the step-3 exemplar and
  the icon-mapping table). The step-4 rendering is a Stitch artifact, noted as
  that spec's §7 delta.
- **Rationale:** Majority + the locked icon-mapping table; one icon per
  allergen across all chip variants.
- **Date:** 2026-05-19.

## DD-10 · Success illustration color token

- **Element:** success-state accent color (checkmark / illustration) on the
  add-product and report success screens.
- **Conflict:** `add-product-success` uses ~`#0D9488` teal; `report-success`
  uses `#006B5B` teal. Neither is an existing `AppColors` token.
- **CHOSEN:** Introduce **`AppColors.success` = `#0D9488`** as the canonical
  success accent for both screens. `report-success`'s `#006B5B` is treated as
  an artifact (noted as its §7 delta). This is distinct from
  `AppColors.safe`/the safe status-pill green.
- **Rationale:** One success token; `#0D9488` is the brighter, more legible of
  the two. Coordinator call — flag if PM wants the darker teal.
- **Date:** 2026-05-19.

## DD-11 · Settings & Profile entry point

- **Element:** how the user reaches the Settings & Profile screen.
- **Conflict:** DD-2 removed Settings from the bottom nav and said it is reached
  "via the nav drawer", but the user drawer Stitch design (`nav-drawer-user`)
  has **no הגדרות row** (rows: פרופיל, היסטוריית סריקה, מוצרים שמורים,
  ביקורות שלי, מרכז עזרה, אודות).
- **CHOSEN:** The drawer's **פרופיל** row opens the **Settings & Profile**
  screen (`settings_screen.dart`) — that screen already contains the profile
  block plus the settings menu rows (נהל אלרגיות, העדפות אפליקציה, etc.). No
  separate הגדרות row is added.
- **Affected specs:** `nav-drawer-user.md` (פרופיל → Settings & Profile),
  `nav-drawer-admin.md` (admin uses הגדרות מערכת for admin-scoped settings),
  `settings-profile.md` §1 (entry = drawer → פרופיל).
- **Rationale:** Matches the Stitch drawer as drawn and the settings screen's
  actual content; no design addition needed.
- **Date:** 2026-05-19.

---

### Cross-screen recurring artifacts (informational, no per-item decision)

Many screens' extracted HTML carry stale chrome: non-canonical bottom-nav tab
sets (→ DD-4), brand text (→ DD-8), `arrow_back`/`arrow_forward` instead of the
canonical `chevron_left` continue icon, and "בטיחות מזון"-style taglines. These
are Stitch generation artifacts. Specs reference the glossary/DD canon and note
the divergence as a §7 delta — they do NOT re-spec the artifact.
