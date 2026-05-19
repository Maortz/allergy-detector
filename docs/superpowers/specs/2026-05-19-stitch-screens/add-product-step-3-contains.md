# הוספת מוצר - שלב 3 / Add Product — Step 3 (Contains Allergens)
Stitch screen: projects/16588854804615693446/screens/0161b2a94e354831baac041620b68d6d
Maps to: app/lib/screens/add_product_screen.dart

## 1. Purpose & context

This is step 3 of a 4-step "Add New Product" wizard. The user has already entered the product name/barcode (step 1) and brand/description (step 2); now they must identify which allergens the product **contains** (as listed in the ingredients). Step 4 will capture the "may contain" allergens. This is a data-contribution flow — community members add products not yet in the Supabase database.

The screen must be efficient: the full allergen catalog (~13 items visible) must be browsable without scrolling confusion, and the selected-vs-unselected state must be unambiguous.

## 2. Visual layout breakdown

Canvas: 780 × 3092 px @2× (390 pt wide). Background: `#F8F9FA`.

### App bar (top)
- White background, no elevation.
- **RTL leading (right):** "הוספת מוצר חדש" — Public Sans SemiBold 16 pt, `#1F2937` (screen title).
- **RTL trailing (left):** `cancel` / `✕` close icon, `#374151`, 24 pt — exits the wizard entirely.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar).

### Progress indicator
- Below app bar, full-width, ~12 pt vertical padding, `#F8F9FA` background.
- "שלב 3 מתוך 4" — Inter Regular 12 pt, `#6B7280`, right-aligned.
- "75% הושלמו" — Inter SemiBold 12 pt, `#00478D`, right-aligned (same line or next).
- Linear progress track: full-width, 4 pt height, background `#E5E7EB`, filled portion `#00478D` at 75%, border-radius 2 pt.

### Section heading block
- "מהם האלרגנים במוצר?" — Public Sans Bold 18 pt, `#1F2937`, right-aligned, ~16 pt horizontal padding, ~16 pt top margin.
- Sub-instruction: "סמן את כל המרכיבים שמופיעים ברשימת הרכיבים" — Inter Regular 13 pt, `#6B7280`, right-aligned, ~4 pt below heading.

### Allergen selection grid — "חלב וביצים" (Dairy & Eggs)
- Sub-section header: "חלב וביצים" — Inter SemiBold 14 pt, `#374151`, right-aligned, ~12 pt top margin.
- Two chips in a row:
  - "חלב" (Milk) — `water_drop` icon — **unselected** in screenshot.
  - "ביצים" (Eggs) — `egg` icon — **unselected**.

### Allergen selection grid — "גלוטן וקטניות" (Gluten & Legumes)
- Sub-section header: "גלוטן וקטניות" — Inter SemiBold 14 pt, `#374151`.
- Chips: "גלוטן" (`grass`), "סויה" (`nutrition`), "בוטנים" (`park`).
- "גלוטן" appears **selected** in the screenshot (filled `#00478D` background, white icon and text).

### Allergen selection grid — "אגוזים וזרעים" (Nuts & Seeds)
- Sub-section header: "אגוזים וזרעים" — Inter SemiBold 14 pt, `#374151`.
- Chips (2×4 grid or wrapped rows): "אגוז מלך" (`energy_savings_leaf`), "שקד" (`nature`), "קשיו" (`emoji_nature`), "פיסטוק" (`grain`), "פקאן" (`local_florist`), "אגוז לוז" (`spa`), "צנובר" (`eco`).

### Allergen chip layout (per chip)
- Grid: 2 chips per row with ~8 pt gap, full-width within horizontal padding of 16 pt.
- Each chip is a square-ish card: ~(screen_width/2 - 20) pt wide, ~72 pt tall.
- Unselected: white background `#FFFFFF`, border 1.5 pt solid `#E5E7EB`, border-radius 12 pt. Icon 24 pt `#6B7280`, label Inter SemiBold 13 pt `#374151`, icon on top, label below, vertically centred.
- Selected: background `#00478D` (AppColors.primary), no border (or same border in primary), icon white, label white.
- (This is distinct from the read-only allergen chips in the profile/home screens — see glossary conflict note.)

### Info note
- Below grid, ~16 pt horizontal margin, ~12 pt top margin.
- Light-blue container `#EBF4FF`, border-radius 8 pt, padding 12 pt.
- `info` icon `#00478D` 16 pt on right + body text Inter Regular 12 pt `#374151`.
- Text (from HTML, paraphrased): note about marking allergens exactly as listed in the ingredients.

### Navigation buttons row
- Pinned to bottom of screen above bottom system bar (not inside bottom nav — wizard modal pattern, no bottom nav visible).
- Two buttons side by side:
  - **Back / Previous:** outlined button, "חזרה" or `chevron_right` label — left button in RTL = "forward" arrow, right button = "back" arrow. Width: ~(screen_width/2 - 20) pt.
  - **Continue / Next:** `primary-button` filled, "המשך" + `chevron_left` icon (RTL trailing) — `#00478D` background, white text, border-radius 12 pt.
- See [_components-glossary.md#primary-button](_components-glossary.md#primary-button).
- No standard bottom navigation bar on this screen — it is a modal wizard flow.

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary | — | `cancel` (✕) | "הוספת מוצר חדש" | see _components-glossary.md#app-bar |
| Progress step label | `#6B7280` | Inter Regular 12 pt | — | "שלב 3 מתוך 4" | — |
| Progress percent label | `AppColors.primary` `#00478D` | Inter SemiBold 12 pt | — | "75% הושלמו" | — |
| Progress bar track | `#E5E7EB` bg / `#00478D` fill | — | — | — | 4 pt height, border-radius 2 pt, 75% fill |
| Section title | `#1F2937` | Public Sans Bold 18 pt | — | "מהם האלרגנים במוצר?" | — |
| Section sub-instruction | `#6B7280` | Inter Regular 13 pt | — | "סמן את כל המרכיבים שמופיעים ברשימת הרכיבים" | — |
| Sub-section header — dairy | `#374151` | Inter SemiBold 14 pt | — | "חלב וביצים" | — |
| Sub-section header — gluten | `#374151` | Inter SemiBold 14 pt | — | "גלוטן וקטניות" | — |
| Sub-section header — nuts | `#374151` | Inter SemiBold 14 pt | — | "אגוזים וזרעים" | — |
| Allergen chip — unselected | `#FFFFFF` bg, `#E5E7EB` border | Inter SemiBold 13 pt | per allergen (see §4) | "חלב", "ביצים", "גלוטן"… | see _components-glossary.md#allergen-chip (wizard variant) |
| Allergen chip — selected | `#00478D` bg, white icon/text | Inter SemiBold 13 pt | per allergen | — | Primary fill on selection |
| Info note | `#EBF4FF` bg | Inter Regular 12 pt | `info` | (paraphrased allergen note) | — |
| Back button | outlined, `#374151` border | Inter SemiBold 14 pt | `chevron_right` | "חזרה" | — |
| Continue button | see glossary | Inter SemiBold 14 pt | `chevron_left` | "המשך" | see _components-glossary.md#primary-button |

## 4. Sub-components / element design

### Progress bar
- `LinearProgressIndicator(value: 0.75, backgroundColor: Color(0xFFE5E7EB), color: Color(0xFF00478D))`.
- Wrapped in `ClipRRect(borderRadius: BorderRadius.circular(2))` for rounded ends.
- Preceded by right-aligned `Row` with step label + percentage label.

### Wizard allergen chip (toggle card)
This variant differs meaningfully from the read-only profile allergen chip (see glossary). It is a **tappable square card**, not a compact inline pill.

- Unselected:
  ```
  Container(
    width: (screenWidth - 48) / 2,  // 16 margin + 8 gap + 16 margin
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Color(0xFFE5E7EB), width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(allergenIcon, size: 24, color: Color(0xFF6B7280)),
      SizedBox(height: 4),
      Text(allergenLabel, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
    ]),
  )
  ```
- Selected: `color: Color(0xFF00478D)`, icon+text color `Colors.white`, border removed (or matched to fill).

### Allergen icon mapping (observed)
| Allergen | Icon name |
|---|---|
| חלב | `water_drop` |
| ביצים | `egg` |
| גלוטן | `grass` |
| סויה | `nutrition` |
| בוטנים | `park` |
| אגוז מלך | `energy_savings_leaf` |
| שקד | `nature` |
| קשיו | `emoji_nature` |
| פיסטוק | `grain` |
| פקאן | `local_florist` |
| אגוז לוז | `spa` |
| צנובר | `eco` |
| שומשום | `local_florist` (TBD — not confirmed on this screen) |

### Navigation button row
- `Row` with `MainAxisAlignment.spaceEvenly`, `CrossAxisAlignment.center`, pinned with `SafeArea` bottom.
- Back button: `OutlinedButton(onPressed: wizard.previousStep, ...)`, height 48 pt, border-radius 12 pt, border color `#D1D5DB`.
- Continue button: `ElevatedButton(onPressed: wizard.nextStep, ...)`, `#00478D` bg, white text, height 48 pt, border-radius 12 pt. Icon `chevron_left` 18 pt on the left (RTL trailing).

### Info note
- `Container(decoration: BoxDecoration(color: Color(0xFFEBF4FF), borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.all(12))`.
- `Row`: `Icon(Icons.info, color: Color(0xFF00478D), size: 16)` on right + `Expanded(child: Text(...))`.

## 5. States & interactions

| State | Trigger | Visual change |
|---|---|---|
| No allergens selected | Default | All chips unselected (white bg, grey border, grey icon) |
| Chip selected | User taps chip | Chip background → `#00478D`, icon+text → white; chip is toggleable (tap again to deselect) |
| Multiple selected | Multiple taps | Multiple chips show selected state simultaneously |
| Continue tapped | User taps "המשך" | Validates (can proceed with zero selections — no mandatory allergen), saves selected allergens to wizard state, navigates to step 4 |
| Back tapped | User taps "חזרה" | Navigates to step 2, preserving current selections |
| Close tapped | User taps `✕` | Confirms exit dialog ("לצאת מהוספת מוצר?") then dismisses wizard |
| Scroll | Grid taller than viewport | Full page scroll; nav buttons remain at bottom of scroll content (not sticky — subject to open question §7.1) |

## 6. Data & controller contract

**Wizard state (passed between steps, e.g. via `AddProductController` or route arguments map):**
- `String productName` — from step 1.
- `String brandName` — from step 2.
- `Set<String> containsAllergenIds` — built on this step; passed to step 4.

**Static data:**
- `List<Allergen> allergenCatalog` — fetched from Supabase at wizard start; grouped by category in UI.
- Category grouping: Dairy & Eggs / Gluten & Legumes / Nuts & Seeds — this grouping is UI-only (not in the `allergens` table schema as of current review; the app may hard-code groups or add a `category` column).

**On step completion:**
- `containsAllergenIds` saved to wizard state → passed to step 4 (may_contain selection).
- On final wizard submit (step 4): `ProductService.addProduct(...)` writes to Supabase `products` + `product_allergens` tables.

**Callbacks / methods:**
- `onAllergenToggled(String allergenId)` — toggles membership in `containsAllergenIds`.
- `onNext()` — advances to step 4.
- `onBack()` — returns to step 2.
- `onClose()` — exits wizard with confirmation.

## 7. Open questions / design-vs-app deltas

1. **Sticky vs. scroll-following nav buttons** — the "חזרה" / "המשך" button row may need to be `sticky` (pinned above keyboard / system bar) or scroll with content. On tall grids (13+ items) the buttons scroll off-screen if not sticky. Recommend `Scaffold(bottomNavigationBar: ...)` pattern for sticky placement.
2. **Allergen category grouping** — the Supabase `allergens` table has no `category` column in the current schema. The UI groups allergens into 3 Hebrew categories. Either add `category` to the schema or hard-code a map in the app.
3. **Icon library** — icons like `emoji_nature`, `energy_savings_leaf`, `grain`, `local_florist`, `spa` are used as allergen icons. These exist in the Material Icons font but the exact icon-to-allergen mapping must be locked in a `const Map<String, IconData>` in the app to prevent drift.
4. **שומשום (Sesame)** — Sesame appears in the Home Dashboard allergen list as one of the 5 monitored allergens, but is not visible in the add-product grid screenshot. Confirm if it appears in a lower scroll position (possibly under "זרעים" sub-section) or is missing from the wizard.
5. **Wizard navigation pattern** — `add_product_screen.dart` exists in the app but the multi-step wizard routing is not confirmed. Is each step a separate named route, a `PageView`, or a `StatefulWidget` with an `_stepIndex`? The spec assumes controller-based state; implementation may differ.
6. **Zero allergens valid?** — can a user proceed from step 3 with zero allergens selected? If a product genuinely contains no common allergens, the user must be allowed to continue. The design shows no mandatory-selection validation state; confirm with PM.
7. **"May contain" step 4** — a `add-product-step-4-may-contain` Stitch screen should be specced separately; this screen's "המשך" button leads there.
