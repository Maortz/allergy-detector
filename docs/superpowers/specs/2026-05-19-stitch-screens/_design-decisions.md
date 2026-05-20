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

## DD-10 · Success illustration color token  *(widened 2026-05-20)*

- **Element:** success-state accent color (checkmark / illustration) on terminal
  success screens AND the green/teal accents on community/review screens.
- **Conflict:** `add-product-success` used `#0D9488` teal; `report-success` used
  `#006B5B` teal; `community-hub` verified StatCard and `review-next-item` hero
  circle also used `#006B5B`/`#78F8DD`. Multiple teal tokens, no shared
  `AppColors` entry.
- **CHOSEN:** **`AppColors.success` = `#0D9488` is the single canonical success
  accent and applies everywhere a "completed/verified/positive contribution"
  signal is rendered** — terminal success screens (add-product-success,
  report-success), community StatCard verified value, review-next-item hero
  icon container. The `#006B5B` / `#78F8DD` family is retired across these
  screens; per-screen specs are updated to use `AppColors.success`.
- **Distinct from:**
  - `AppColors.safe` `#16A34A` — used in the safe `status-pill` and the
    `filter-chip` safe variant. Encodes "this product is safe for *you*",
    not "your contribution succeeded". Do not conflate.
  - The Material `ColorScheme.secondary` slot — that slot may still map to
    `#006B5B` for arbitrary secondary UI accents, but no current spec depends
    on it.
- **Rationale:** One success token end-to-end avoids drift; brighter `#0D9488`
  reads better at small sizes and in the badge/illustration contexts where it
  appears.
- **Date:** 2026-05-19 (original); widened 2026-05-20.

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

## DD-12 · Material 3 adoption

- **Element:** Flutter `ThemeData.useMaterial3` and the colour-scheme / widget choices that depend on it.
- **Conflict:** Specs reference M3-only tokens (`primaryContainer`, `secondaryContainer`, `surfaceContainerLow/High/Highest`, `outline`, `outlineVariant`, `onSurfaceVariant`, `primary-fixed*`) and M3-only widgets (`NavigationBar` for DD-6 pill indicator, `FilledButton` in `admin-trusted-brands §4.6`). App currently has no `ColorScheme` mapping.
- **CHOSEN:** **Material 3 (`useMaterial3: true`)** is the canonical target for this spec set.
- **Required app-side wiring:**
  - `ThemeData(useMaterial3: true, colorScheme: …)` with the colour roles listed in `_components-glossary.md#material-3-adoption`.
  - Bottom nav uses `NavigationBar` (M3); `BottomNavigationBar` cannot reproduce the DD-6 pill indicator.
  - `FilledButton` is allowed (admin-trusted-brands) and need not be downgraded to `ElevatedButton`.
- **Rationale:** Every TBD token in the specs already maps cleanly to an M3 colour role; staying on M2 would force a custom palette layer and break DD-6.
- **Date:** 2026-05-20.

## DD-13 · Wizard / onboarding chip selected style

- **Element:** "selected" visual treatment for tappable allergen chips in the Add-Product wizard (steps 3 and 4) and the Onboarding allergen grid.
- **Conflict:** step-3 Stitch renders a solid `#00478D` fill with white icon+text; step-4 and onboarding render a bordered white card (2 pt `#00478D` border + `check_circle` badge, icon/label colours unchanged). Three screens, two styles.
- **CHOSEN:** **Bordered + `check_circle` badge wins everywhere** — `_components-glossary.md#allergen-chip` Variant C is updated to this canonical style. Step 3's earlier solid-fill rendering is a Stitch artifact; per-screen spec is realigned (`add-product-step-3-contains §4.2` updated).
- **Why bordered+badge:** preserves icon legibility and label colour parity across states, gives an unambiguous status indicator (the badge), and is consistent across all three screens that use the pattern.
- **Date:** 2026-05-20.

## DD-14 · Drawer footer brand text

- **Element:** brand/tagline string in the bottom of the navigation drawer (both user and admin variants).
- **Conflict:** `nav-drawer-user §4.4` and `nav-drawer-admin §4.4` render "אלרגיות בצלחת" — a secondary tagline that does not appear elsewhere and contradicts DD-8's canonical brand "בטוח לאכול".
- **CHOSEN:** **Drop the brand/tagline line from the drawer footer entirely.** Footer shows only the app version string (from `PackageInfo.fromPlatform()`), centred or trailing per the existing layout.
- **Rationale:** Cleanest resolution to a string that DD-8 doesn't cover. Avoids inventing a two-string brand system. Version-only footer is a common Material pattern and removes the brand-string drift surface.
- **Affected specs:** `nav-drawer-user.md §4.4` and §7.3, `nav-drawer-admin.md §4.4`.
- **Date:** 2026-05-20.

## DD-15 · App-bar variants closed at three

- **Element:** the canonical set of `_components-glossary.md#app-bar` variants.
- **Conflict:** `community-review §2.1/§7.1` introduced a "centred title + trailing `arrow_forward`" layout, and `report-success §7.1` introduced a "flow-title 'דיווח מועבר'" hybrid bar. Both flagged as candidate new variants.
- **CHOSEN:** **App-bar variant set stays closed at three: brand bar / detail bar / wizard bar.** Both community-review and report-success normalize to the **detail-bar** variant (right-aligned screen title, back-arrow leading on the RTL-trailing side, no centred title, no `arrow_forward` trailing icon, no `menu` hamburger). The Stitch renderings are artifacts.
- **Rationale:** Three variants already cover every legitimate role (main shell, pushed sub-screen, modal wizard); a fourth would dilute the canon without serving any structural need.
- **Affected specs:** `community-review.md §2.1, §3, §4.1, §7.1`; `report-success.md §3 item 1, §4, §7.1`.
- **Date:** 2026-05-20.

## DD-16 · New shared components promoted

- **Element:** which screen-specific patterns are promoted to shared components in `_components-glossary.md`.
- **Conflict:** three patterns recur across multiple screens but were specced inline each time — drift surface.
- **CHOSEN:** Promote the following to the glossary:
  - **`product-row`** — used in `home-dashboard` (Variant A, compact) and `active-search-results` (Variant B, detailed with status icon + thumbnail). Reusable on future saved-products / scan-history lists.
  - **`filter-chip`** — three-segment safe/caution/avoid row, used in `settings-profile`. Reuses the `status-pill` colour palette.
  - **`success-badge-pair`** — two-badge row below the headline on terminal success screens (`add-product-success`, `report-success`).
- **Effect:** Each affected screen's §3/§4 references the glossary entry; do not re-spec the structure inline.
- **Date:** 2026-05-20.

## DD-17 · status-pill padding

- **Element:** internal padding of the `status-pill` shared component.
- **Conflict:** glossary originally said "horizontal: 10, vertical: 4 (use 8 or 12; exact value TBD)" — off-grid value with an explicit "pick one" note.
- **CHOSEN:** **`EdgeInsets.symmetric(horizontal: 12, vertical: 4)`** — 3×4 / 1×4 on the 4 px grid. Glossary updated.
- **Rationale:** 12/4 leaves more breathing room around the fixed three-character labels (בטוח / זהירות / להימנע) and accommodates the 16 pt status icon comfortably; 8/4 felt cramped at the icon+label gap.
- **Date:** 2026-05-20.

---

### Cross-screen recurring artifacts (informational, no per-item decision)

Many screens' extracted HTML carry stale chrome: non-canonical bottom-nav tab
sets (→ DD-4), brand text (→ DD-8), `arrow_back`/`arrow_forward` instead of the
canonical `chevron_left` continue icon, and "בטיחות מזון"-style taglines. These
are Stitch generation artifacts. Specs reference the glossary/DD canon and note
the divergence as a §7 delta — they do NOT re-spec the artifact.
