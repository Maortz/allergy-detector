# פרטי מוצר - בטוח / Product Details — Safe
Stitch screen: projects/16588854804615693446/screens/eda2fffaccee4c059519033acc27e842
Maps to: app/lib/screens/product_details.dart

## 1. Purpose & context

This screen shows the full detail page for a scanned or searched product when the result is **Safe** — i.e., neither `product.containsAllergens` nor `product.mayContainAllergens` intersects with the user's selected allergen IDs. The primary communication goal is immediate positive reassurance: the user can see at a glance that this product is clear, then optionally review allergen chips (shown in the neutral/display style), scan the ingredients text, and provide community feedback. Because no danger signal is required, the visual hierarchy is calmer than the Avoid screen — no full-width red banner, no red primary action. This is the same `product_details.dart` route as the Avoid variant; the status-dependent rendering is driven by the computed `AllergenStatus` value passed in.

**Exemplar product shown in Stitch:** "חלב אורגני 3%" (Organic Milk 3%), 700 מ״ל — a product that contains no allergens matching the user profile.

## 2. Visual layout breakdown

Canvas: 780 × 2142 px @2× (390 pt wide). Background: `#F8F9FA` with a white scrollable body below the hero image. Total height is shorter than the Avoid screen (2142 vs 2874 px), consistent with the absence of the large full-width avoid-banner.

### App bar (top)
- White background, `elevation: 0`.
- **RTL leading (right):** Screen title "פרטי מוצר" — Public Sans SemiBold 16 pt, `#1F2937` — with a `arrow_forward` (or equivalent back-arrow) icon immediately to its right, indicating a back action in RTL navigation.
- **RTL trailing (left):** `menu` hamburger icon, `#374151`, 24 pt.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar) — this is the **Detail bar** variant.

### Safe status indicator (below app bar)
- A compact inline status pill, **not** a full-width banner (contrast: Avoid screen uses a full-width banner; see [_design-decisions.md#dd-1](_design-decisions.md#dd-1)).
- The pill appears directly below the app bar, horizontally left-aligned (RTL trailing side — toward the left edge of the screen).
- Pill label (from screenshot): "בטוח - ללא אלרגנים עבורך" ("Safe — no allergens for you").
- `check_circle` icon, green, on the right side of the pill text (RTL leading).
- Background: `#DCFCE7`, border: none visible (may have subtle border), text color `#15803D`, icon color `#16A34A`.
- Font: Inter SemiBold 12 pt (matches status-pill spec).
- See [_components-glossary.md#status-pill](_components-glossary.md#status-pill) — Safe variant. Note: this is the pill used **on the detail screen itself** (detail screens do NOT use the compact pill per DD-1 for Avoid; Safe uses the pill because no full-width banner exists for Safe state).

> <!-- PENDING DECISION: DD-1 states "Detail screens never render the compact pill" — but the Safe screen clearly shows a compact pill below the app bar, not a full-width banner. The Avoid screen uses a full-width banner exclusively. The Safe screen contradicts the broad DD-1 statement. Either DD-1 should be narrowed to "Avoid detail screens use the banner; Safe/Caution detail screens use the pill" or a new safe-banner component is needed. -->

### Product hero image
- Full-width image area, approximately 160–180 pt tall, `BoxFit.contain`, white background.
- Shows the product image (milk bottle in a glass bottle).
- No overlay, no gradient.
- A `share` icon button (`share`, 24 pt, `#374151`) is visible at the bottom-left corner of the image area (RTL trailing), suggesting a share action for the product.

### Product identity block
- Below image, ~16 pt horizontal padding, ~12 pt top padding.
- Product name: "חלב אורגני 3%" — Public Sans Bold 22 pt, `#1F2937`, right-aligned (RTL).
- Volume/weight sub-title: "700 מ״ל" — Inter Regular 14 pt, `#6B7280`, right-aligned.

### "אלרגנים שזוהו" (Detected Allergens) section
- Section label: "אלרגנים שזוהו" — Public Sans SemiBold 16 pt, `#1F2937`, right-aligned, ~16 pt top margin.
- Below label: a horizontal `Wrap` of **allergen chips**.
- In the Safe state the chips render in the **display / neutral (Variant A)** style — blue-tinted background `#EBF4FF`, border `#BFDBFE`, icon and text `#00478D`.
- Two chips visible in the screenshot: "ביצים" and "חלב" — rendered with their respective icons (`egg` and `water_drop`) in the display variant.
- These chips represent allergens that the **user monitors** but that are **not present** in the product; they are shown to give the user full context.
- See [_components-glossary.md#allergen-chip](_components-glossary.md#allergen-chip) — Variant A.

### "רשימת רכיבים" (Ingredients List) section
- Accordion / expandable section header: `list_alt` icon + "רשימת רכיבים" — Inter SemiBold 15 pt, `#1F2937` + `expand_more` chevron on the left (RTL trailing).
- Shown collapsed in the screenshot (body text not visible in the fold).
- Expanded body (from HTML extraction): ingredient text paragraph, Inter Regular 13 pt, `#374151`, line-height ~20 pt, horizontal padding 16 pt.
- Exact ingredient text (from HTML): "חלב אורגני מפוסטר, ויטמין D." — no allergen keyword highlighting needed for the Safe state (no user-allergen matches).
- See `product-details-avoid.md §4` for the `ExpansionTile` implementation pattern; the Safe screen uses the same accordion widget with the same structure, but without allergen-highlight `TextSpan` colouring.

### Community feedback / Report row
- `report` icon + "דווח על טעות" text button — Inter Regular 13 pt, `#DC2626` (red, secondary action).
- Appears below the ingredients section, left-aligned (RTL trailing).
- No thumb-up/thumb-down buttons visible in the screenshot for the Safe state (may be omitted or scrolled out of view in the Stitch canvas; see open questions §7.3).

### Primary action / bottom row
- A full-width light-grey button is visible near the bottom of the content area; it does not carry the strong red of the Avoid screen.
- Label appears to be "דווח על טעות" or a neutral action label — exact text unclear from screenshot rendering; likely "שתף מוצר" (Share product) or a neutral CTA (token TBD).
- Background: `#F3F4F6` (light grey) or `#E5E7EB`; text: `#374151`; no danger coloring.
- See [_components-glossary.md#primary-button](_components-glossary.md#primary-button) — Standard variant applies; exact label TBD (see §7.1).

### Bottom navigation bar
- Standard 4-tab bar, "סריקה" tab active (index 1) — same as Avoid screen; product details are typically reached from the scan/search flow.
- See [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav).

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary | — | `arrow_forward`, `menu` | "פרטי מוצר" | Detail bar variant; see _components-glossary.md#app-bar |
| Safe status pill | `AppColors.safe` (TBD) `#DCFCE7` bg, `#15803D` text | Inter SemiBold 12 pt | `check_circle` | "בטוח - ללא אלרגנים עבורך" | Compact pill, NOT a full-width banner; see DD-1 PENDING DECISION |
| Product image | — | — | — | — | `BoxFit.contain`, white bg, ~170 pt height |
| Share icon button | `#374151` | — | `share` | — | Bottom-left of image area (RTL trailing) |
| Product name | `#1F2937` | Public Sans Bold 22 pt | — | "חלב אורגני 3%" | Right-aligned (RTL) |
| Product sub-title | `#6B7280` | Inter Regular 14 pt | — | "700 מ״ל" | Right-aligned |
| Allergens section header | `#1F2937` | Public Sans SemiBold 16 pt | — | "אלרגנים שזוהו" | — |
| Allergen chips (safe/display) | `#EBF4FF` bg, `#BFDBFE` border, `#00478D` icon+text | — | per allergen | "ביצים", "חלב" | Display variant A; see _components-glossary.md#allergen-chip |
| Ingredients accordion | `#1F2937` header | Inter SemiBold 15 pt | `list_alt`, `expand_more` | "רשימת רכיבים" | Expandable; shown collapsed in screenshot |
| Ingredients text | `#374151` | Inter Regular 13 pt | — | "חלב אורגני מפוסטר, ויטמין D." | No highlight needed in Safe state |
| Report error | `#DC2626` | Inter Regular 13 pt | `report` | "דווח על טעות" | Secondary action |
| Primary button (Safe) | `#F3F4F6` bg, `#374151` text (token TBD) | Inter SemiBold 14 pt | (TBD) | (exact label TBD) | Neutral/standard variant; see §7.1 |
| Bottom nav | see glossary | — | home, qr_code_scanner, groups, favorite_border | בית / סריקה / קהילה / מועדפים | see _components-glossary.md#bottom-nav; סריקה active |

## 4. Sub-components / element design

### Safe status pill (detail-screen placement)
- See [_components-glossary.md#status-pill](_components-glossary.md#status-pill) for the canonical pill spec.
- On the product-details-safe screen the pill is placed **inline**, left-of-centre below the app bar (RTL trailing), as a slim badge rather than spanning full width.
- Width: fits content (min ~120 pt to accommodate the longer label "בטוח - ללא אלרגנים עבורך").
- The label on this screen is longer than the compact "בטוח" card label — it includes the full "- ללא אלרגנים עבורך" suffix, which is a detail-screen-only extension of the pill copy.
- Implementation note: this may be a separate `SafeDetailBanner` widget rather than the card `StatusPill`, as the copy differs. Alternatively, `StatusPill` could accept an optional `subtitle` string. Decision needed (see §7.2).

### Allergen chips — display variant (Safe state)
- The chips on the Safe screen show the user's monitored allergens in the neutral blue display style (Variant A), confirming to the user that these allergens were checked and not found.
- Same pill shape and icon mapping as Variant A per [_components-glossary.md#allergen-chip](_components-glossary.md#allergen-chip).
- `Wrap` layout with `spacing: 8, runSpacing: 8`, right-aligned (RTL).

### Ingredients accordion (Safe state)
- Same `ExpansionTile`-pattern as the Avoid screen (see `product-details-avoid.md §4`).
- No allergen-term `TextSpan` highlighting required in Safe state — all ingredient text renders uniformly in `#374151`.
- Default state: **collapsed** (unlike the Avoid screen where the accordion appears expanded in the Stitch canvas).

### Share button
- `IconButton(icon: Icon(Icons.share), color: Color(0xFF374151), iconSize: 24)`.
- Positioned at the trailing edge (left in RTL) of the product image area — possibly overlaid as a `Positioned` widget within a `Stack`, or placed in a row below the image.
- Behaviour: native share sheet (`Share.share(...)` from `share_plus` package, or equivalent). Not currently in `product_details.dart` — design aspiration (see §7.4).

## 5. States & interactions

### Safe state (default on this screen)

| State | Trigger | Visual |
|---|---|---|
| Safe (default) | `product.containsAllergens ∩ userAllergens = ∅` AND `product.mayContainAllergens ∩ userAllergens = ∅` | Green status pill, blue display-variant allergen chips, neutral/grey primary button |
| Ingredients collapsed | Default | Shows only accordion header with `expand_more` |
| Ingredients expanded | Tap accordion | Body text revealed; chevron rotates 180° |
| Share tapped | User taps `share` icon | Native OS share sheet opens with product name + URL/barcode |
| Report error tapped | User taps "דווח על טעות" | Opens report dialog or form (behaviour TBD) |
| Primary button tapped | User taps neutral CTA | Behaviour TBD (see §7.1) — likely "שתף מוצר" or adds to favourites |
| Back navigation | Tap back / `arrow_forward` in RTL | Pops route back to previous screen |

### Caution state (no standalone Stitch screen — spec'd here as a state of product_details.dart)

The **Caution** verdict applies when `product.containsAllergens ∩ userAllergens = ∅` but `product.mayContainAllergens ∩ userAllergens ≠ ∅` — i.e., the product may contain a user allergen (cross-contamination risk) but does not definitively contain it.

**Design intent:** Caution sits between Safe and Avoid. There is no full-width Avoid-style banner. Instead:

| Element | Safe rendering | Caution rendering |
|---|---|---|
| Status pill | Green `#DCFCE7`, `check_circle`, "בטוח - ללא אלרגנים עבורך" | Yellow `#FEF9C3`, `info`, "זהירות - עלול להכיל אלרגנים" |
| Allergen chips | Blue display variant (Variant A) for monitored allergens | Mix: Variant A for safe allergens; yellow/amber **caution variant** for `mayContain` allergens (see note below) |
| Primary button | Neutral/grey | Amber/yellow — `AppColors.caution` (token TBD); label TBD (e.g., "נהג בזהירות") |
| Ingredients text | No highlighting | `mayContain` allergen keywords highlighted in amber `#CA8A04` / bold |

**Caution allergen chip variant** (not yet in _components-glossary.md — needed):
- Background: `#FEF9C3` (light yellow), border: 1 pt solid `#CA8A04` (amber), icon color `#CA8A04`, label color `#A16207` (Inter SemiBold 13 pt).
- Same shape (fully rounded, 20 pt radius) and padding as Variant B.
- Distinct from both Variant A (blue — safe display) and Variant B (red — detected/avoid).

> Note: No Stitch screen exists for the Caution state. The above is derived from the `status-pill` Caution variant spec in [_components-glossary.md#status-pill](_components-glossary.md#status-pill) and by analogy with the Avoid/Safe pattern. Implementation should confirm with design before building.

### Relationship to the Avoid screen

The Safe screen and Avoid screen share the same `product_details.dart` route and the same overall layout skeleton. The key structural delta is:

| Element | Safe | Avoid |
|---|---|---|
| Status indicator | Compact green status pill (inline, below app bar) | Full-width red `avoid-banner` (full-bleed, below app bar) |
| Allergen chips | Display/neutral Variant A (blue) | Detected Variant B (red) |
| Primary button | Neutral/grey (token TBD) | Red danger variant `#DC2626` |
| Ingredient highlighting | None | `#DC2626` on matched allergen terms |
| Feedback row (thumbs) | Not visible in Safe Stitch screen (possibly omitted or below fold) | `thumb_up` / `thumb_down` icon buttons present |
| Screen height | 2142 px (shorter) | 2874 px (taller — banner + longer content) |

## 6. Data & controller contract

**Route arguments** (same as Avoid variant):
- `Product product` — full product object including `id`, `name`, `hebrewDescription`, `imageUrl`, `containsAllergens`, `mayContainAllergens`, `ingredients` (text string), `nutritionData`.
- `UserProfile userProfile` — for computing status and selecting allergen chip variant.

**Computed locally:**
- `status`: `AllergenStatus.safe` when this screen variant is shown.
  - `safe`:    `product.containsAllergens ∩ userProfile.selectedAllergenIds = ∅` AND `product.mayContainAllergens ∩ userProfile.selectedAllergenIds = ∅`.
  - `caution`: `product.containsAllergens ∩ userProfile.selectedAllergenIds = ∅` AND `product.mayContainAllergens ∩ userProfile.selectedAllergenIds ≠ ∅`.
  - `avoid`:   `product.containsAllergens ∩ userProfile.selectedAllergenIds ≠ ∅`.
- `monitoredAllergens`: `userProfile.selectedAllergenIds` — drives the allergen chip row in Safe state (all chips shown in display Variant A).
- `cautionAllergens`: `product.mayContainAllergens ∩ userProfile.selectedAllergenIds` — used in Caution state for the amber chip variant.

**Services called:**
- None at load time (data passed via route arguments).
- `ProductService.reportError(productId, feedback)` — on report-error tap (future).
- `ProductService.submitFeedback(productId, isHelpful)` — on thumb tap, if present (future).

**State held locally:**
- `_isIngredientsExpanded` (bool) — controls accordion open/closed.
- `_feedbackState` (enum: none/helpful/notHelpful) — controls thumb button appearance if feedback row is present.

**Status-driven widget switching** (same `product_details.dart` file):
```dart
// Pseudocode
Widget _buildStatusIndicator(AllergenStatus status) {
  switch (status) {
    case AllergenStatus.avoid:
      return AvoidBanner();         // full-width red banner
    case AllergenStatus.caution:
      return StatusPill(status: status);  // inline yellow pill
    case AllergenStatus.safe:
      return StatusPill(status: status);  // inline green pill
  }
}
```

## 7. Open questions / design-vs-app deltas

1. **Primary button exact label and behaviour** — the neutral-grey button at the bottom of the Safe screen is partially legible in the screenshot. Possible labels: "שתף מוצר" (Share product), "הוסף למועדפים" (Add to favourites), or "חזור לסריקה" (Return to scan). The `share` icon button already appears on the image — if both are share actions they would be redundant. Needs PM/design confirmation.

2. **Status pill copy on detail screen vs. card** — the pill label on this detail screen reads "בטוח - ללא אלרגנים עבורך" (with the suffix "- ללא אלרגנים עבורך"), whereas the compact card pill in `home-dashboard` reads just "בטוח". Either `StatusPill` needs an optional long-form label parameter, or a `SafeDetailIndicator` variant is warranted. Decision needed before implementation.

3. **Feedback thumbs row presence** — the `thumb_up` / `thumb_down` row is clearly present in the Avoid screen but not visible in the Safe screen screenshot. This may be: (a) the Safe design intentionally omits it, (b) it is below the Stitch canvas fold, or (c) an oversight. Confirm with design before conditionally hiding the feedback row.

4. **Share button in `product_details.dart`** — no share functionality exists in the current `product_details.dart`. The Stitch design shows a `share` icon overlaid on the product image. Requires adding `share_plus` (or equivalent) and a new `IconButton` to the image area.

5. **Caution allergen chip variant** — the amber/yellow caution chip (yellow bg `#FEF9C3`, amber border `#CA8A04`) is not defined in `_components-glossary.md`. A Variant D entry should be added to the glossary when the Caution state is formally designed (no Stitch screen yet exists).

6. **Allergen chip meaning in Safe state** — the display-variant chips on the Safe screen appear to represent the user's **monitored** allergens (present in the user profile), shown to reassure the user that these specific allergens were checked and not found. This is semantically different from the Avoid screen where chips represent **detected** allergens. The section heading "אלרגנים שזוהו" ("Detected Allergens") is therefore misleading for the Safe state — it shows allergens that were NOT detected. A different heading such as "אלרגנים שנבדקו" ("Allergens Checked") may be more accurate. Design review needed.

7. **Bottom nav active tab** — same open question as the Avoid screen: whether ProductDetails is pushed over the Scan tab or Home tab determines which tab appears active. The Stitch screenshot shows Scan active (index 1); this should be consistent across both Safe and Avoid variants.

8. **Ingredient text highlight in Caution state** — the Caution state calls for amber `#CA8A04` highlighting of `mayContain` allergen keywords within the ingredients `Text` widget. This requires the same `TextSpan`-based implementation as the Avoid state but with a different highlight colour. Not currently in `product_details.dart`.
