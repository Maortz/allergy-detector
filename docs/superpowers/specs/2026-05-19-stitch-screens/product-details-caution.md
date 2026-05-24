# Product Details — Caution
Stitch screen: *(no Stitch screen — derived per `product-details-safe.md §5 'Caution state'`)*
Maps to: `app/lib/screens/product_details.dart` (Caution branch)

## 1. Purpose & context

The third allergen-status branch of the `product_details.dart` route. Renders
when `product.containsAllergens ∩ userAllergens = ∅` **and**
`product.mayContainAllergens ∩ userAllergens ≠ ∅` — the product may contain a
user allergen via cross-contamination, but does not definitively contain it.

Communication goal: an amber middle-state signal — visibly cautious without
the full Avoid red banner. Reuses the same screen skeleton as Safe and Avoid;
the differences are colour palette and copy.

## 2. Visual layout breakdown

Identical skeleton to `product-details-safe §2` with these substitutions:

| Element | Caution rendering |
|---|---|
| Status indicator below app bar | Compact `status-pill` Caution variant (`#FEF9C3` bg, `info` icon, label "זהירות" per DD-3) + adjacent text "עלול להכיל אלרגנים" (Inter Regular 13 pt `#A16207`) |
| "אלרגנים שזוהו" section chips | `allergen-chip` **Variant D** (caution) for `mayContain ∩ userAllergens` allergens; Variant A (display) for the user's other monitored allergens |
| Ingredients accordion | Same `ExpansionTile`; ingredient body **highlights** `mayContain` keywords in `#CA8A04` Inter Bold per `product-details-safe §7.8` resolution |
| Primary button (bottom) | **Dropped** per `product-details-safe §7.1` resolution. Report-error + share icon are the only bottom anchors, identical to Safe and Avoid |
| Share icon | Present on product image (per `product-details-safe §7.4`) |
| Bottom nav | Standard 4-tab; originating tab active |

App bar = detail-bar variant (DD-15) with title "פרטי מוצר" and back-arrow trailing.

## 3. Component inventory

| Element | Source |
|---|---|
| App bar | `_components-glossary.md#app-bar` — detail-bar |
| Caution status pill + adjacent text | `_components-glossary.md#status-pill` Caution variant + screen-specific adjacent `Text` |
| Allergen chip — caution | `_components-glossary.md#allergen-chip` Variant D |
| Allergen chip — display | `_components-glossary.md#allergen-chip` Variant A (for monitored allergens that are not in the mayContain set) |
| Ingredients accordion | Same as Safe/Avoid §4 — `ExpansionTile` with `TextSpan` highlights |
| Report-error row | Inter Regular 13 pt `#DC2626` text button with `report` icon |
| Bottom nav | Standard, DD-2/DD-6 |

## 4. Sub-components / element design

### 4.1 Caution status pill
- Background `#FEF9C3`, border-radius 20 pt, `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` per DD-17.
- Icon `info` 16 pt `#CA8A04` (RTL leading); 4 pt gap; label "זהירות" Inter SemiBold 12 pt `#A16207`.
- Placed inline below the app bar (not full-width — matches Safe pill placement).
- Adjacent text "עלול להכיל אלרגנים" — Inter Regular 13 pt `#A16207`, 8 pt to the left of the pill.

### 4.2 Allergen chips
- `mayContain ∩ userAllergens` allergens render as Variant D (caution chips).
- User's other monitored allergens (`selectedAllergenIds - containsAllergens - mayContainAllergens`) render as Variant A (display chips) to communicate "this allergen was checked and not found".
- Wrap layout with `spacing: 8`, `runSpacing: 8`, right-aligned (RTL).

### 4.3 Ingredient highlight
- Same `TextSpan`-based implementation as Avoid (`product-details-avoid §4`).
- Highlight color: `#CA8A04` (Caution) — distinct from Avoid's `#DC2626`.
- Keywords highlighted: Hebrew names of allergens in `mayContain ∩ userAllergens`.

## 5. States & interactions

| State | Trigger | Visual |
|---|---|---|
| Caution (default for this branch) | `containsAllergens ∩ userAllergens = ∅ ∧ mayContainAllergens ∩ userAllergens ≠ ∅` | Amber pill + adjacent text; mixed chip variants; amber ingredient highlights |
| Ingredients accordion expand/collapse | Same as other branches | Body text reveals; chevron rotates |
| Share tap | User taps `share` icon | Native share sheet via `share_plus` |
| Report-error tap | User taps "דווח על טעות" | Push report-issue flow |
| Back navigation | Tap back arrow | Pop route |

## 6. Data & controller contract

Identical to `product-details-safe §6` and `product-details-avoid §6`:
- Route arguments: `Product product` + `UserProfile userProfile`.
- `status` computed locally per the allergen-intersection rules.
- `cautionAllergens = product.mayContainAllergens ∩ userProfile.selectedAllergenIds`.
- No backend writes at load time.

### 6.1 Status-driven widget switching (cross-state)
```dart
Widget _buildStatusIndicator(AllergenStatus status) {
  switch (status) {
    case AllergenStatus.avoid:
      return AvoidBanner();                // full-width red, see product-details-avoid §4
    case AllergenStatus.caution:
      return Row([CautionPill(), AdjacentText('עלול להכיל אלרגנים')]);
    case AllergenStatus.safe:
      return Row([SafePill(), AdjacentText('ללא אלרגנים עבורך')]);
  }
}
```

## 7. Open questions / design-vs-app deltas

### 7.1 Derived spec — no Stitch screen
This branch was previously specced as a state of `product-details-safe.md §5`.
Promoted to its own file to give the implementation a single canonical
reference for the Caution rendering.

### 7.2 Adjacent text copy
"עלול להכיל אלרגנים" is the canonical adjacent text. If specific allergens are
known, the screen MAY append them: e.g. "עלול להכיל אלרגנים: אגוזים". The
list comes from `cautionAllergens`. Truncate to first 2 allergens + "ועוד" if
more than 2.

### 7.3 Implementation deltas — verification pass 2026-05-24

Spec-parity check of `app/lib/screens/product_details.dart` against this spec.
**Result: diverged — Verified remains ⬜.** Fixes deferred (no code change this
pass, per scope decision). Most deltas are shared with the Safe/Avoid branches
(Batch H) and with not-yet-built glossary widgets, so they belong to a single
product-details refactor rather than a caution-only patch.

| # | Spec requirement | Current code | Scope of fix |
|---|---|---|---|
| D1 | Compact `status-pill` (radius 20, `info` icon 16 pt, inline below app bar) | `_buildStatusBanner` renders a full-width centered `Container` with `Icons.warning` for all states | Shared with Safe (only Avoid keeps a full-width banner per glossary `#status-pill`) |
| D2 | Pill label = `"זהירות"` only; `"עלול להכיל אלרגנים"` is separate adjacent text (DD-3) | Merged into one label `"זהירות - עשוי להכיל"` | Shared with Safe label `"✓ בטוח - ללא אלרגנים עבורך"` |
| D3 | Amber tokens `#FEF9C3` bg / `#CA8A04` icon / `#A16207` text | `AppColors.cautionBackground` `#FEF7E0`, `cautionText` `#B05B00`; no `AppColors.caution` extension token | App-wide theme token (glossary "Material 3 adoption") |
| D4 | `allergen-chip` Variant D (caution) for `mayContain ∩ user` + Variant A (display) for other monitored allergens | Big row-cards (40 pt icon circle + name + label badge); renders only product allergens, not the user's other monitored allergens | Shared across all 3 branches; needs `AllergenChip` widget (glossary `#allergen-chip`) |
| D5 | Ingredients accordion highlights `mayContain` keywords in `#CA8A04` Inter Bold (`TextSpan`) | Plain ingredients `Text`, no highlight | Shared with Avoid |
| D6 | App-bar = detail-bar variant, title `"פרטי מוצר"` | Title = `product.nameHe` | Shared across all 3 branches |
| D7 | Share icon on the product image | Share icon in `AppBar` actions | Shared across all 3 branches |
| D8 | Allergen icon map per glossary (peanut=`park`, soy=`nutrition`, walnut=`energy_savings_leaf`, …) | `_getAllergenIcon` uses `spa` (nut/peanut), `eco` (soy) | Glossary-wide; `AllergenChip` should own the mapping |

§7.2's optional allergen-name append is also unimplemented (acceptable — it is
"MAY", not required).

**Recommended fix home:** roll D1–D8 into Batch H (`product-details-safe`,
`product-details-avoid`) so the shared `_buildStatusBanner`, allergen-section,
ingredients, and app-bar are reworked once across all three states, extracting
`StatusPill` and `AllergenChip` shared widgets at the same time.
