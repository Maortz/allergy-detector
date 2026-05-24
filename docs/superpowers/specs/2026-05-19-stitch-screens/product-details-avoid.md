# פרטי מוצר - הימנע / Product Details — Avoid
Stitch screen: projects/16588854804615693446/screens/9aa55d9704a849468749a219d7e81dc7
Maps to: app/lib/screens/product_details.dart

## 1. Purpose & context

This screen shows the full detail page for a scanned or searched product when the result is **Avoid** — i.e., the product `containsAllergens` set intersects with the user's selected allergens. The primary communication goal is an unmistakable red danger signal at the top, followed by which specific allergens were detected, the full ingredients list, and lightweight community-feedback controls. This is the most safety-critical screen in the app; visual hierarchy must make the Avoid verdict impossible to miss.

## 2. Visual layout breakdown

Canvas: 780 × 2874 px @2× (390 pt wide). Background: `#F8F9FA` with a white scrollable body below the hero image.

### App bar (top)
- White background, no elevation in resting state.
- **RTL leading (right):** back-arrow / "בחזרה לאכול" app-brand text — in the screenshot the app bar shows "בטוח לאכול" logo text on the right and a `menu` hamburger on the left. A separate close/back control (`cancel ✕` / `X`) is also present per the HTML.
- **Status banner** immediately below app bar: a full-width pill/banner with red background (`#DC2626` or close — `AppColors.avoid`, token TBD).
  - RTL layout: `⊗` cancel icon on the right → "הימנע – מכיל אלרגנים" bold text → right-chevron (`chevron_right`) on the left.
  - Text: Inter SemiBold 14 pt, white `#FFFFFF`.
  - Height: ~40 pt, no border-radius (full-bleed band), horizontal padding 16 pt.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar) for standard app-bar spec; the status banner is a **screen-specific addition** below the standard bar.

### Product hero image
- Full-width image area, ~200 pt tall, `BoxFit.contain`, white background.
- Shows the product image (Milk Chocolate Bar wrapper photo).
- No overlay, no gradient.

### Product identity block
- Below image, ~16 pt horizontal padding, ~12 pt top padding.
- Product English name: "Milk Chocolate Bar" — Public Sans Bold 22 pt, `#1F2937`, right-aligned (RTL).
- Product Hebrew sub-title: "שוקולד חלב איכותי - 100 גרם" — Inter Regular 14 pt, `#6B7280`, right-aligned.

### "אלרגנים שזוהו" (Detected Allergens) section
- Section label: "אלרגנים שזוהו" — Public Sans SemiBold 16 pt, `#1F2937`, right-aligned, ~16 pt top margin.
- Below label: a horizontal row (or `Wrap`) of **allergen chips** — at least two visible: "אגוזים" and "חלב".
- In the Avoid state these chips render in the **active/detected** variant — red-tinted background `#FEE2E2`, red border `#DC2626`, red icon, red label text `#991B1B`.
- See [_components-glossary.md#allergen-chip](_components-glossary.md#allergen-chip).

### Nutrition / macros row (optional)
- A horizontal row of 2–3 data cells (icons + label + value), likely `water_drop` / `nutrition` icons.
- Separated from allergen section by a thin `#E5E7EB` divider line.
- Values sourced from product data (calories, protein, etc.).

### "רשימת רכיבים" (Ingredients List) section
- Accordion / expandable section header: `list_alt` icon + "רשימת רכיבים" — Inter SemiBold 15 pt, `#1F2937` + `expand_more` chevron on the left (RTL trailing).
- Expanded body (shown expanded in screenshot): full ingredient text paragraph, Inter Regular 13 pt, `#374151`, line-height ~20 pt, horizontal padding 16 pt.
- Exact ingredient text (from HTML): "סוכר, חמאת קקאו, אבקת חלב מלא, עיסת קקאו, אבקת חלב רזה, לקטוז, תמצית לתת שעורה, חומרי טעם וריח. עשוי להכיל עקבות של אגוזי לוז, שקדים ואגוזים אחרים."
- Allergen keywords within text are **highlighted** (bold or coloured `#DC2626`) — design intent; confirm in implementation.

### Community feedback row
- Thin horizontal divider `#E5E7EB` before row.
- Label: "האם המידע היה מועיל?" — Inter Regular 14 pt, `#374151`.
- Two icon-buttons: `thumb_up` and `thumb_down`, outlined style, `#6B7280` idle.
- "דווח על טעות" text button: `report_problem` icon + text, Inter Regular 13 pt, `#DC2626` (red, secondary action).

### Primary action button — dropped (per §7.1 resolution)

The Avoid screen does **not** render a generic primary action button. The
report-error row + thumbs-feedback row (§"Community feedback row") is the
bottom anchor; the avoid signal is delivered by the full-width red banner at
the top (`avoid-banner`) + the red allergen-chips. Removing the redundant
"הימנע מוצר זה" CTA simplifies the screen and matches the Safe pattern
(no generic CTA there either).

### Bottom navigation bar
- Standard 4-tab bar, "סריקה" tab active (index 1).
- See [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav).

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary | — | `menu`, `cancel` | "בטוח לאכול" | see _components-glossary.md#app-bar |
| Avoid status banner | `AppColors.avoid` `#DC2626` bg, `#FFFFFF` text | Inter SemiBold 14 pt | `cancel` (✕) | "הימנע – מכיל אלרגנים" | Screen-specific; full-width below app bar |
| Product image | — | — | — | — | `BoxFit.contain`, white bg, ~200 pt height |
| Product name (EN) | `#1F2937` | Public Sans Bold 22 pt | — | "Milk Chocolate Bar" | English product name from DB |
| Product sub-title (HE) | `#6B7280` | Inter Regular 14 pt | — | "שוקולד חלב איכותי - 100 גרם" | Hebrew description + weight |
| Allergens section header | `#1F2937` | Public Sans SemiBold 16 pt | — | "אלרגנים שזוהו" | — |
| Allergen chips (avoid) | `#FEE2E2` bg, `#DC2626` border+icon+text | — | per allergen | "חלב", "אגוזים" | see _components-glossary.md#allergen-chip |
| Nutrition row | — | Inter Regular 12 pt | `water_drop`, `nutrition` | — | Optional; values from product data |
| Ingredients accordion | `#1F2937` header | Inter SemiBold 15 pt | `list_alt`, `expand_more` | "רשימת רכיבים" | Expandable; full ingredient text inside |
| Ingredients text | `#374151` | Inter Regular 13 pt | — | "סוכר, חמאת קקאו, אבקת חלב מלא…" | Allergen terms highlighted |
| Feedback label | `#374151` | Inter Regular 14 pt | — | "האם המידע היה מועיל?" | — |
| Thumbs up/down | `#6B7280` idle | — | `thumb_up`, `thumb_down` | — | Toggle on tap |
| Report error | `#DC2626` | Inter Regular 13 pt | `report_problem` | "דווח על טעות" | — |
| Primary button (Avoid) | — | — | — | — | **Dropped per §7.1.** Avoid signal delivered by top banner + red chips; report-error + thumbs row is the bottom anchor |
| Bottom nav | see glossary | — | home, scanner, groups, favorite | בית / סריקה / קהילה / מועדפים | see _components-glossary.md#bottom-nav |

## 4. Sub-components / element design

### Avoid status banner
- `Container(color: Color(0xFFDC2626), height: 40, padding: EdgeInsets.symmetric(horizontal: 16))`.
- Internal `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)`: `Icon(Icons.cancel, color: Colors.white, size: 20)` on right (RTL leading), `Text("הימנע – מכיל אלרגנים")` in center, `Icon(Icons.chevron_right, color: Colors.white, size: 20)` on left (RTL trailing — may be a nav indicator to avoid-details or simply decorative).
- This banner is NOT a standard status pill (it is full-bleed, larger, and always Avoid colour on this screen).

### Allergen detected chip (Avoid variant)
- Background: `#FEE2E2`, border: 1 pt solid `#DC2626`, border-radius: 20 pt (fully rounded).
- Padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`.
- Icon (allergen-specific, 16 pt, `#DC2626`) + label (Inter SemiBold 13 pt, `#991B1B`), gap 4 pt.

### Ingredients accordion
- `ExpansionTile`-like widget. Header row: right-aligned label, left-trailing `expand_more`/`expand_less`.
- Body: `Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: SelectableText(...))`.
- Allergen term highlights: `TextSpan` with `FontWeight.bold` or `TextStyle(color: Color(0xFFDC2626))` for matched words.

### Community feedback row
- `Row` with `MainAxisAlignment.spaceBetween`, top/bottom padding 12 pt.
- Thumb buttons: `OutlinedButton.icon` with `BorderSide(color: Color(0xFFD1D5DB))`, border-radius 8 pt, icon 20 pt.
- Tapped state: filled background — `thumb_up` → `#DCFCE7` green tint, `thumb_down` → `#FEE2E2` red tint.

## 5. States & interactions

| State | Trigger | Visual change |
|---|---|---|
| Avoid (default on this screen) | `product.containsAllergens ∩ userAllergens ≠ ∅` | Red banner, red allergen chips, red primary button |
| Ingredients collapsed | Default | Shows only accordion header |
| Ingredients expanded | Tap accordion | Body text revealed; chevron rotates 180° |
| Thumb up tapped | User taps 👍 | Button fills green `#DCFCE7`, `thumb_up` icon fills; 👎 resets |
| Thumb down tapped | User taps 👎 | Button fills red `#FEE2E2`; 👍 resets |
| Report error tapped | User taps "דווח על טעות" | Opens report dialog or form (behaviour TBD) |
| Primary button tapped | User taps red Avoid button | Adds product to avoid list / dismisses screen (behaviour TBD) |
| Back navigation | Tap back / `✕` | Pops route back to previous screen |

## 6. Data & controller contract

**Route arguments:**
- `Product product` — full product object including `id`, `name`, `hebrewDescription`, `imageUrl`, `containsAllergens`, `mayContainAllergens`, `ingredients` (text string), `nutritionData`.
- `UserProfile userProfile` — for computing status and highlighting allergen chips.

**Computed locally:**
- `detectedAllergens`: `product.containsAllergens ∩ userProfile.selectedAllergenIds` — drives the allergen chip row.
- Status: always **Avoid** on this screen variant (a separate `product-details-safe` / `product-details-caution` screen variant exists for other statuses).

**Services called:**
- None at load time (data passed via route arguments).
- `ProductService.reportError(productId, feedback)` — on report-error tap (future).
- `ProductService.submitFeedback(productId, isHelpful)` — on thumb tap (future).

**State held locally:**
- `_isIngredientsExpanded` (bool) — controls accordion.
- `_feedbackState` (enum: none/helpful/notHelpful) — controls thumb button appearance.

## 7. Open questions / design-vs-app deltas

1. **Primary button — resolved (dropped).** Avoid screen has no generic CTA. Top banner + red chips deliver the avoid signal; report-error + thumbs row is the bottom anchor. The "הימנע מוצר זה" button rendered by Stitch is removed. Add the share-image overlay (`share` icon) per `product-details-safe §7.4` resolution.
2. **Status banner chevron — resolved (decorative).** The `chevron_right` on the left of the avoid banner is decorative; no navigation. Implement as a non-tappable child of the banner `Row`.
3. **Ingredient highlight — resolved (in scope per product-details-safe §7.8).** Implement `TextSpan` keyword highlighting: `#DC2626` Inter Bold for `containsAllergens ∩ userAllergens` matches; Caution state uses `#CA8A04`.
4. **Nutrition row** — `water_drop` / `nutrition` icons visible in HTML but not in current `Product` model. Nutrition data fields are not in `supabase/schema.sql`. Either the row is decorative/placeholder or schema needs extending.
5. **English product name** — "Milk Chocolate Bar" is in English. The app targets a Hebrew audience; confirm whether product names from OpenFoodFacts are stored as-is (English) or transliterated.
6. **Community feedback persistence** — no backend endpoint exists for `thumb_up`/`thumb_down`/`report_problem`. These controls are design aspirations only in MVP.
7. **Bottom nav active tab** — Stitch renders "סריקה" active (index 1) because product-details is typically reached via scan/search. Implementation should preserve the originating-tab highlight (whichever IndexedStack index was active when ProductDetails was pushed). Pill indicator per DD-6 applies.

### 7.8 Implementation deltas — verification pass 2026-05-24 <!-- SEVERE -->

Spec-parity check of `app/lib/screens/product_details.dart` (Avoid state).
**Result: severely diverged — avoid-banner colour is wrong (light tint instead of solid red), banner text is white-on-dark instead of white-on-red, feedback thumbs row absent, allergen section shows wrong allergens, and all shared structural defects from caution §7.3 apply.** Verified = ⚠. No code change this pass (documented only).

Aligned: `_computeStatus` correctly returns `AllergenStatus.avoid` when `containsAllergens ∩ userAllergens ≠ ∅`; `Directionality(rtl)` present; `ExpansionTile` used for ingredients; full-width layout of banner widget (shape correct, colours wrong).

| # | Spec requirement | Current code |
|---|---|---|
| AV1 | Full-width avoid-banner: solid `#DC2626` background, white `#FFFFFF` text, Inter SemiBold 14 pt; `cancel` icon (✕) right (RTL leading), label center, `chevron_right` left (RTL trailing) | `_buildStatusBanner` for avoid: `color: AppColors.avoidBackground` = `#FCE8E6` (light red tint — completely wrong, banner must be solid `#DC2626`); text color `AppColors.avoidText` = `#D93025` (dark red on light background — illegible); icon `Icons.dangerous` 24 pt; no `chevron_right`; label `'הימנע - מכיל אלרגנים שלך'` (hyphen vs em-dash; extra `שלך`) |
| AV2 | Allergen chips = Variant B (detected): `#FEE2E2` bg, `#DC2626` border + icon, `#991B1B` label, radius 20 pt, compact pill; shows only `containsAllergens ∩ userAllergens` (detected allergens) | Row-card containers (radius 12, `surfaceContainerLow` bg, 40 pt circle icon); shows ALL `allProductAllergens` (contains + may_contain combined regardless of user match); wrong chip shape/colours (shared — see caution §7.3 D4) |
| AV3 | App bar title `"פרטי מוצר"` | `AppBar(title: Text(product.nameHe))` — product name used (shared — see caution §7.3 D6) |
| AV4 | Share icon overlaid at trailing edge of product image | `IconButton(Icons.share)` in `AppBar.actions` (shared — see caution §7.3 D7) |
| AV5 | Community feedback row: `"האם המידע היה מועיל?"` label + `thumb_up` / `thumb_down` `OutlinedButton.icon` widgets | No thumbs row anywhere in the code; no `_feedbackState` variable; not implemented |
| AV6 | Ingredients section header `"רשימת רכיבים"` with `list_alt` icon; allergen keywords highlighted `#DC2626` Inter Bold via `TextSpan` | Header = `Text('רכיבים')`; accordion title = `'לחץ להצגת רכיבים'`; plain `Text(product.ingredients!)` — no `TextSpan` highlight (shared — see caution §7.3 D5 for highlight; SF7 for header copy) |
| AV7 | Report-error: `report_problem` icon + `"דווח על טעות"`, red `#DC2626` text button | `OutlinedButton.icon(Icons.flag, 'דיווח על טעות')` — wrong icon, wrong copy, wrong widget/color (same as SF8) |
| AV8 | Bottom nav: `"סריקה"` tab active (index 1) | `BottomNavBar(currentIndex: 0)` — Home tab hardcoded |
| AV9 | Allergen icon mapping per glossary (peanut=`park`, soy=`nutrition`, walnut=`energy_savings_leaf`, …) | `_getAllergenIcon`: soy → `Icons.eco`; nut/peanut → `Icons.spa`; sesame → `Icons.grain` (correct by coincidence); others partially correct (shared — see caution §7.3 D8) |

**Priority / quick wins:** AV1 is the highest-severity user-facing bug — the avoid-banner displays as a light-pink tint rather than the solid red warning colour, making the danger signal fail its core purpose. Fix: replace `AppColors.avoidBackground`/`avoidText` with hardcoded `Color(0xFFDC2626)` background and `Colors.white` text, and swap the `dangerous` icon for `Icons.cancel`. AV5 (missing feedback thumbs) is a visible functional gap on the most safety-critical screen.
