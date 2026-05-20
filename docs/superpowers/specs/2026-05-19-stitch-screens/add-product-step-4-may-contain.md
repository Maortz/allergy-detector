# הוספת מוצר - שלב 4 / Add Product — Step 4 (May Contain)
Stitch screen: projects/16588854804615693446/screens/723494ade01f454e96e9ae22524ca7cb
Maps to: app/lib/screens/add_product_screen.dart

## 1. Purpose & context

This is the final step (step 4 of 4) of the "Add New Product" community-contribution wizard. The user has already provided the barcode/name (step 1), brand/description (step 2), and "contains" allergens (step 3). Step 4 captures the **"may contain" / trace-level allergens** — those listed on product packaging under phrases such as "עלול להכיל" or "בסביבת עבודה שמעבדת" (may contain / produced in a facility that also processes).

This distinction is safety-critical: "contains" (step 3) drives the **Avoid** verdict; "may contain" (step 4) drives the **Caution** verdict in the allergen-status computation. The user should mark only allergens that are explicitly stated on the label as trace risks, not those already selected in step 3.

On completion the user submits the full product record to Supabase. The CTA therefore changes from "המשך" to "סיום ושליחה" (Finish & Send), signalling that this is the terminal action in the wizard.

## 2. Visual layout breakdown

Canvas: 780 × 2254 px @2× (390 pt wide). Background: `#F8F9FA`.

### App bar (top)
- White background, no elevation.
- **RTL leading (right):** "הוספת מוצר - שלב 4" — Public Sans SemiBold 16 pt, `#1F2937`. (Stitch renders the per-step title here, not "הוספת מוצר חדש" — see §7.1 for delta vs canonical wizard chrome.)
- **RTL trailing (left):** `cancel` / `✕` close icon, `#374151`, 24 pt — exits the wizard entirely.
- Also visible in Stitch: a `chevron_right` / `>` icon on the far left edge, rendered as the back affordance at app-bar level. This is a Stitch-specific artifact — see §7.1.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar).

### Progress indicator
- Below app bar, full-width, ~12 pt vertical padding, `#F8F9FA` background.
- Right-aligned text row:
  - "שלב 4 מתוך 4" — Inter Regular 12 pt, `#6B7280`.
  - "100% הושלם" — Inter SemiBold 12 pt, `#00478D`.
- Linear progress track: full-width, 4 pt height, background `#E5E7EB`, filled `#00478D` at **100%** (fully filled), border-radius 2 pt.
- See [_components-glossary.md#wizard-chrome](_components-glossary.md#wizard-chrome).

### Section heading block
- "האם יש חשש לעקבות?" — Public Sans Bold 18 pt, `#1F2937`, right-aligned, ~16 pt horizontal padding, ~16 pt top margin.
- Sub-instruction: "סמן אלרגנים המצוינים תחת 'עלול להכיל' או 'בסביבת עבודה'" — Inter Regular 13 pt, `#6B7280`, right-aligned, ~4 pt below heading.

### Allergen selection grid
Six allergen chips in a 2-column grid, rendered in 3 rows:

| Row | Right chip (RTL col 1) | Left chip (RTL col 2) |
|---|---|---|
| 1 | "חלב" (`water_drop`) — **selected** | "ביצים" (`egg`) — unselected |
| 2 | "גלוטן" (`grass`) — unselected | "אגוזים" (`nutrition`) — unselected |
| 3 | "בוטנים" (`spa`-icon variant) — **selected** | "דגים" (`set_meal`) — unselected |

Notes on this chip set vs step 3:
- The allergen set shown is a subset: only 6 items visible (חלב, ביצים, גלוטן, אגוזים, בוטנים, דגים). Step 3 showed 12–13 items across 3 sub-section groups. Step 4 does not have named sub-section headers — the grid is flat (no "חלב וביצים" / "גלוטן וקטניות" / "אגוזים וזרעים" category rows visible in the Stitch render).
- "אגוזים" (generic Nuts) appears in place of the individual nut breakdown from step 3. This may be a simplified subset for trace-allergen declaration. See §7.2.
- "דגים" (Fish, `set_meal` icon) appears in step 4 but was not visible in step 3. See §7.3.
- **Selected-chip visual**: In the Stitch screenshot, selected chips ("חלב", "בוטנים") render with a **white background, blue `#00478D` border (~1.5–2 pt), and a filled blue circle-check badge** (`check_circle`) overlaid at the top-left corner of the chip. Icon and label remain in their unselected color palette (`#6B7280` icon, `#374151` label). This is visually distinct from step 3's fully-filled blue card. See §7.4.

### Info / warning note
- Below grid, ~16 pt horizontal margin, ~12 pt top margin.
- Container background: amber/yellow tint `#FEF9C3` (caution amber, not the blue `#EBF4FF` used in step 3's info note). Border-radius 8 pt, padding 12 pt.
- `info` icon `#CA8A04` 16 pt on right.
- Title line: "שים לב" — Inter SemiBold 13 pt, `#92400E` (or nearest amber-800 token).
- Body text: Inter Regular 12 pt, `#374151`. Text (from HTML extraction): סמן "עלול להכיל" רק כשמצוין במפורש על האריזה — ודא שהמידע תואם את האריזה האמיתית.

### Navigation / submit area
- Pinned to bottom above system safe area; no standard bottom-nav in the canonical wizard modal pattern.
- **Single full-width primary button** "סיום ושליחה" with `send` trailing icon (or `arrow_forward` RTL-adapted) — `#00478D` background, white text Inter SemiBold 14 pt, height 48 pt, border-radius 12 pt.
- No separate "חזרה" (Back) button is visible in the Stitch render at this position. See §7.5.
- Stitch also renders a **bottom navigation bar** with 4 tabs (בית/`home`, סריקה/`barcode_scanner`, חיפוש/`search`, פרופיל/`person`). This contradicts the wizard-modal pattern. See §7.6.

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary | — | `cancel` (✕) | "הוספת מוצר - שלב 4" | delta vs canonical; see §7.1 |
| Progress step label | `#6B7280` | Inter Regular 12 pt | — | "שלב 4 מתוך 4" | — |
| Progress percent label | `AppColors.primary` `#00478D` | Inter SemiBold 12 pt | — | "100% הושלם" | step 3 used "הושלמו", step 4 uses "הושלם" |
| Progress bar | `#E5E7EB` bg / `#00478D` fill | — | — | — | 4 pt, border-radius 2 pt, 100% fill |
| Section title | `#1F2937` | Public Sans Bold 18 pt | — | "האם יש חשש לעקבות?" | — |
| Section sub-instruction | `#6B7280` | Inter Regular 13 pt | — | "סמן אלרגנים המצוינים תחת 'עלול להכיל' או 'בסביבת עבודה'" | — |
| Allergen chip — unselected | `#FFFFFF` bg, `#E5E7EB` border | Inter SemiBold 13 pt | per allergen | "ביצים", "גלוטן", "אגוזים", "דגים" | see _components-glossary.md#allergen-chip (Variant C) |
| Allergen chip — selected | `#FFFFFF` bg, `#00478D` border, `check_circle` badge | Inter SemiBold 13 pt | per allergen | "חלב", "בוטנים" | **differs from step 3 selected style** — see §4 and §7.4 |
| Info/warning note | `#FEF9C3` bg, `#CA8A04` icon | Inter Regular 12 pt / SemiBold 13 pt | `info` | "שים לב" + body | amber tint differs from step 3 blue note |
| Info note title | `#92400E` (token TBD) | Inter SemiBold 13 pt | — | "שים לב" | — |
| Info note body | `#374151` | Inter Regular 12 pt | — | סמן "עלול להכיל" רק כשמצוין במפורש על האריזה — ודא שהמידע תואם את האריזה האמיתית. | — |
| Submit button | `AppColors.primary` `#00478D` | Inter SemiBold 14 pt | `send` | "סיום ושליחה" | see _components-glossary.md#primary-button; terminal wizard action |
| Bottom nav | (stale Stitch artifact) | — | home / barcode_scanner / search / person | "בית" / "סריקה" / "חיפוש" / "פרופיל" | NOT canonical — see §7.6 |

## 4. Sub-components / element design

### Progress bar
Identical spec to step 3 but fill = 100%:
- `LinearProgressIndicator(value: 1.0, backgroundColor: Color(0xFFE5E7EB), color: Color(0xFF00478D))`.
- Wrapped in `ClipRRect(borderRadius: BorderRadius.circular(2))`.
- Text row: right-aligned `Row` → "שלב 4 מתוך 4" Inter Regular 12 pt `#6B7280` + "100% הושלם" Inter SemiBold 12 pt `#00478D`.

### Allergen selection chip — step-4 selected state
The selected chip in step 4 uses a **bordered card with a checkmark overlay**, not the solid-fill style from step 3. The canonical glossary Variant C defines the solid-fill style from step 3. Step 4 introduces a visual variant:

**Unselected (same as Variant C):**
```
Container(
  width: (screenWidth - 48) / 2,
  height: 72,
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Color(0xFFE5E7EB), width: 1.5),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(allergenIcon, size: 24, color: Color(0xFF6B7280)),
    SizedBox(height: 4),
    Text(label, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
  ]),
)
```

**Selected (step-4 variant — differs from Variant C):**
```
Stack(children: [
  Container(
    width: (screenWidth - 48) / 2,
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Color(0xFF00478D), width: 2.0),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(allergenIcon, size: 24, color: Color(0xFF6B7280)),  // icon unchanged
      SizedBox(height: 4),
      Text(label, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),  // label unchanged
    ]),
  ),
  Positioned(
    top: 6, left: 6,  // top-start in RTL = top-left rendered corner
    child: Icon(Icons.check_circle, size: 18, color: Color(0xFF00478D)),
  ),
])
```

> Note: Whether to align the checkmark badge to top-start or top-end in RTL context needs confirmation. The screenshot shows the badge at the top-left of the card which in RTL layout is the trailing/end side. Implementation should use `Positioned` within an RTL-aware `Stack`.

### Allergen icon mapping (step-4 allergen set)
| Allergen (HE) | Allergen (EN) | Material Icon |
|---|---|---|
| חלב | Milk | `water_drop` |
| ביצים | Eggs | `egg` |
| גלוטן | Gluten | `grass` |
| אגוזים | Nuts (generic) | `nutrition` |
| בוטנים | Peanuts | `park` (canonical per DD-9; Stitch step-4 renders `spa` — Stitch artifact, §7 delta) |
| דגים | Fish | `set_meal` |

### Info/warning note (amber variant)
Visually distinct from step 3's blue info note — this uses an amber/caution palette signalling higher-stakes instruction:
```
Container(
  decoration: BoxDecoration(
    color: Color(0xFFFEF9C3),   // amber-100
    borderRadius: BorderRadius.circular(8),
  ),
  padding: EdgeInsets.all(12),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(Icons.info, color: Color(0xFFCA8A04), size: 16),   // right side in RTL
    SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('שים לב', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF92400E))),
      SizedBox(height: 4),
      Text('סמן "עלול להכיל" רק כשמצוין במפורש על האריזה — ודא שהמידע תואם את האריזה האמיתית.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF374151))),
    ])),
  ]),
)
```

### Submit button
Terminal wizard CTA — uses the same `primary-button` component as "המשך" in prior steps but with a different label and icon:
- Label: "סיום ושליחה" — Inter SemiBold 14 pt, `#FFFFFF`.
- Icon: `send` (or `arrow_forward`), 18 pt, `#FFFFFF`, trailing (RTL: left side).
- Background: `#00478D`, border-radius 12 pt, height 48 pt, full-width (16 pt margins).
- Loading state: replaces label+icon with `CircularProgressIndicator(color: Colors.white, strokeWidth: 2)` during Supabase write.
- See [_components-glossary.md#primary-button](_components-glossary.md#primary-button).

### Navigation footer (canonical)
Per [_components-glossary.md#wizard-chrome](_components-glossary.md#wizard-chrome): no bottom navigation bar in the wizard modal. The canonical footer on step 4 is:
- "חזרה" outlined button (left in RTL, border `#00478D`, text `#00478D`, transparent bg, height 48 pt, border-radius 12 pt).
- "סיום ושליחה" primary button (right in RTL, as above).
The Stitch render shows only the submit button and a non-canonical nav bar — see §7.5 and §7.6.

## 5. States & interactions

| State | Trigger | Visual change |
|---|---|---|
| No allergens selected | Default / arrival from step 3 | All chips unselected (white bg, `#E5E7EB` border, grey icon) |
| Chip selected | User taps chip | Chip border → `#00478D` 2 pt; `check_circle` `#00478D` badge appears at top corner; icon+label colors unchanged |
| Chip deselected | User taps selected chip | Border reverts to `#E5E7EB`; badge disappears |
| Multiple selected | Multiple taps | Multiple chips show blue-border + badge simultaneously |
| Submit tapped (valid) | User taps "סיום ושליחה" | Button enters loading state; `ProductService.addProduct(...)` called; on success → wizard dismissed, success toast/snackbar shown, user returned to previous screen (Home or Search/Scan) |
| Submit tapped (error) | Supabase write fails | Loading resolves to error; inline error message or `SnackBar` shown; user can retry |
| Zero selected | Default (valid) | "סיום ושליחה" remains enabled — zero may-contain allergens is a valid state for a product |
| Back tapped | User taps "חזרה" | Navigates to step 3, preserving current step-4 selections |
| Close tapped | User taps `✕` | Confirmation dialog ("לצאת מהוספת מוצר?") then dismisses wizard, discards all wizard state |
| Scroll | Grid taller than viewport | Full page scroll; submit button/nav row remain at bottom (sticky, above system bar) |

## 6. Data & controller contract

**Wizard state (accumulated across all 4 steps):**
- `String productName` — from step 1.
- `String barcode` — from step 1 (if scanned).
- `String brandName` — from step 2.
- `String productDescription` — from step 2 (optional).
- `Set<String> containsAllergenIds` — from step 3.
- `Set<String> mayContainAllergenIds` — built on this step; may overlap with step 3 selections in principle but UX should guide against it.

**Static data:**
- `List<Allergen> allergenCatalog` — same catalog fetched at wizard start; presented as a flat list (no sub-section categories, unlike step 3). Step 4 shows 6 allergens in Stitch; the canonical implementation should show the full catalog to be complete (see §7.2).
- Pre-filtering: allergens already marked "contains" in step 3 may optionally be hidden or disabled in step 4 to prevent double-selection (design intent not confirmed — see §7.2).

**On submission:**
- `ProductService.addProduct(productName, barcode, brandName, description, containsAllergenIds, mayContainAllergenIds)` writes:
  1. `products` table: name, barcode, brand_id, description, created_by (anonymous/device ID for MVP).
  2. `product_allergens` table: one row per allergen ID with `relation_type = 'contains'` (from step 3) and one row per with `relation_type = 'may_contain'` (from step 4).
- On success: dismiss wizard, navigate back, optionally trigger a cache invalidation on `SearchCache` so the new product appears in searches.

**Callbacks / methods:**
- `onAllergenToggled(String allergenId)` — toggles membership in `mayContainAllergenIds`.
- `onSubmit()` — validates, calls service, handles success/error.
- `onBack()` — returns to step 3, preserving current selections.
- `onClose()` — exits wizard with confirmation dialog.

## 7. Open questions / design-vs-app deltas

### 7.1 App-bar title delta (DD-5 ref)
The Stitch screen renders the app-bar title as **"הוספת מוצר - שלב 4"** (per-step variant) with a `chevron_right` back affordance inside the bar. The canonical wizard chrome ([_components-glossary.md#wizard-chrome](_components-glossary.md#wizard-chrome), DD-5) specifies **"הוספת מוצר חדש"** as the fixed title with a "שלב N מתוך 4" subtitle below the app bar, and back navigation in the footer row (not the app bar). Implement the canonical form; the Stitch render is a known inconsistency covered by DD-5 — do not re-flag.

### 7.2 Step-4 allergen set: subset vs full catalog
The Stitch render shows only 6 allergens (חלב, ביצים, גלוטן, אגוזים, בוטנים, דגים) without sub-section grouping. Step 3 showed 12–13 allergens in 3 named categories. Two open questions:
- a) Should step 4 display the **full allergen catalog** (same as step 3) or a reduced "common trace allergens" subset? The Stitch mock likely abbreviates for layout space. Recommend full catalog for completeness.
- b) Should allergens already selected as "contains" in step 3 be **hidden, disabled, or still shown** in step 4? Best practice: show them as disabled/greyed to indicate the user has already declared them; allow override if needed. Design does not specify this — confirm with PM.

### 7.3 Icon and allergen discrepancies vs step 3
- "דגים" (Fish) with icon `set_meal` appears in step 4 but was absent from the step-3 grid. If the same allergen catalog drives both steps, Fish must also appear in step 3. Confirm catalog completeness.
- "בוטנים" (Peanuts): resolved per _design-decisions.md#dd-9. Canonical icon = `park` (matches step-3 exemplar and the glossary icon-mapping table). The `spa`-like rendering in this step-4 Stitch screenshot is a Stitch artifact (§7 delta). Implement `park` for בוטנים across all screens.
- "אגוזים" (generic Nuts, `nutrition`) in step 4 replaces the granular nut breakdown from step 3 (אגוז מלך, שקד, קשיו, פיסטוק, פקאן, אגוז לוז, צנובר). For "may contain" declarations on packaging, a generic "nuts" label is common. Confirm whether the allergen catalog has a generic "אגוזים" entry distinct from the individual nut entries.

### 7.4 Selected-chip style delta vs Variant C
Step 3 selected chips use a **solid `#00478D` fill** with white icon+text (Variant C as specced in glossary). Step 4 selected chips use a **white background + blue border + `check_circle` badge** with unchanged icon+label colours. If both step 3 and step 4 share `AllergenChip` Variant C, the implementation must parameterize the selected style, or introduce a **Variant C2** for step 4. Recommend updating the glossary to add `wizardSelectedBordered` to the variant enum once confirmed with PM/designer.

### 7.5 Missing "חזרה" back button in Stitch render
The canonical wizard chrome requires a "חזרה" outlined back button on steps 2–4 ([_components-glossary.md#wizard-chrome](_components-glossary.md#wizard-chrome)). The Stitch render shows only the "סיום ושליחה" submit button in the footer. Implement the canonical two-button footer (חזרה + סיום ושליחה); the Stitch omission is a rendering artifact covered by DD-5.

### 7.6 Bottom navigation bar in Stitch render
The Stitch screenshot shows a 4-tab bottom nav (בית/סריקה/חיפוש/פרופיל) below the submit button. Per DD-4 and the wizard-chrome canon, **no bottom navigation bar** appears in wizard modal flows. The tab labels also differ from the canonical set (DD-2: בית/סריקה/קהילה/מועדפים). This is a known Stitch artifact; do not render a bottom nav in the wizard implementation.

### 7.7 Info note color: amber vs blue
Step 3 uses a **blue** (`#EBF4FF`) info note; step 4 uses an **amber** (`#FEF9C3`) warning note. The semantic distinction is intentional: step 3 is informational (which ingredients to look at); step 4 is cautionary (accuracy of trace declarations affects user safety). Confirm whether this amber note should use a dedicated `CautionNote` widget variant distinct from the blue `InfoNote` used in step 3, or whether a single `NoteCard(variant: info | caution)` component suffices.

### 7.8 Success flow after submission
The design does not show the post-submission state (success screen, toast, or navigation target). Confirm: after a successful `addProduct` call, does the wizard close and show a success `SnackBar` on the previous screen, or navigate to a dedicated "product added" confirmation screen?
