# Shared Component Glossary
Design system: **Clinical Clarity RTL**
Stitch project: `16588854804615693446`
Last updated: 2026-05-19 — populated from exemplar screens: home-dashboard, product-details-avoid, add-product-step-3-contains.

> **How to use:** When a spec file references a shared component, write `see _components-glossary.md#<anchor>` instead of re-specifying. Update this file — not the individual specs — when a component changes.

---

## status-pill

A compact inline badge that communicates the safety verdict for a scanned product. Appears in product cards (Home Dashboard recent-activity list) and potentially in search results.

### Structure
- `Container` with `BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20))`.
- Padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` (4 px grid: 3×4 / 1×4 — canonical per DD-17).
- Internal `Row(mainAxisSize: MainAxisSize.min)`: icon (16 pt) → gap 4 pt → label text.
- Font: Inter SemiBold 12 pt.
- Appears right-aligned in RTL product card rows (leading/start side).

### Variants

| Variant | Background | Icon | Icon color | Text | Text color | Token |
|---|---|---|---|---|---|---|
| Safe / בטוח | `#DCFCE7` | `check_circle` | `#16A34A` | "בטוח" | `#15803D` | `AppColors.safe` (TBD) |
| Caution / זהירות | `#FEF9C3` | `info` | `#CA8A04` | "זהירות" | `#A16207` | `AppColors.caution` (TBD) |
| Avoid / להימנע | `#FEE2E2` | `warning` | `#DC2626` | "להימנע" | `#991B1B` | `AppColors.avoid` (TBD) |

### Label copy is FIXED (see _design-decisions.md#dd-3)
The pill text is ALWAYS exactly "בטוח" / "זהירות" / "להימנע" per the variant
table above. Longer contextual strings seen on some screens
("בטוח לצריכה", "בטוח - ללא אלרגנים עבורך", "מכיל אגוזי לוז", "חשש לגלוטן")
are **separate adjacent text elements**, NOT the pill — spec them in that
screen's §2/§3, never as a pill label.

### Props (Flutter widget interface)
```dart
StatusPill({
  required AllergenStatus status,  // safe | caution | avoid → fixes color+icon+label
})
```

### Where it appears (see _design-decisions.md#dd-1, revised)
- `home-dashboard` → recent-activity product cards (all variants).
- `product-details-safe` → **Safe** header uses the compact safe pill.
- Product detail **Caution** state → compact caution pill.
- `product-details-avoid` → **Avoid** header does NOT use the pill; it uses the
  full-width screen-specific **avoid-banner** ("הימנע – מכיל אלרגנים",
  documented in `product-details-avoid.md` §2/§4 — not a glossary component).
  Avoid is the ONLY state that replaces the pill with a banner.

---

## allergen-chip

A visual tag representing a single allergen. Appears in three distinct contexts with meaningfully different visual treatments. All three are documented here; implementors must use the correct variant.

### Variant A — Profile / display chip (Home Dashboard)
Read-only compact pill showing an allergen the user is monitoring.

- Shape: `BorderRadius.circular(20)` (fully rounded pill).
- Size: fits content, min-width ~56 pt, height ~28 pt.
- Background: `#EBF4FF` (light Medical-Blue tint).
- Border: 1 pt solid `#BFDBFE` (light blue).
- Icon: allergen-specific Material icon, 14 pt, `#00478D`.
- Label: Inter Medium 12 pt, `#00478D`.
- Padding: `EdgeInsets.symmetric(horizontal: 10, vertical: 4)`.
- Not tappable (or tappable only to navigate to allergen settings).
- Example: "בוטנים", "חלב", "ביצים", "אגוזים", "שומשום".

### Variant B — Detected allergen chip (Product Details — Avoid)
Read-only chip emphasising that this allergen was found in the product. High-danger styling.

- Shape: `BorderRadius.circular(20)` (fully rounded pill).
- Size: ~80 pt wide × 32 pt tall.
- Background: `#FEE2E2` (light red).
- Border: 1 pt solid `#DC2626` (red).
- Icon: allergen-specific Material icon, 16 pt, `#DC2626`.
- Label: Inter SemiBold 13 pt, `#991B1B`.
- Padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`.
- Not tappable.
- Example: "חלב", "אגוזים".

### Variant C — Wizard / onboarding selection chip (bordered + badge)
Interactive square-ish toggle card for selecting allergens in the Add-Product
wizard (steps 3 and 4) and the onboarding allergen-selection grid. Canonical
selected style per DD-13: **bordered + check_circle badge**, icon and label
colours unchanged between states.

- Shape: `BorderRadius.circular(12)`.
- Size: `(screenWidth - 48) / 2` wide (2-per-row grid with 16 pt margins and 8 pt gap), 72 pt tall.
  - Onboarding uses a 3-per-row grid (see `onboarding-allergen-selection.md §4.5`); width and aspect-ratio adjust accordingly, all other visuals identical.
- **Unselected:** Background `#FFFFFF`, border 1.5 pt solid `#E5E7EB`, icon 24 pt `#6B7280`, label Inter SemiBold 13 pt `#374151`.
- **Selected (canonical per DD-13):** Background `#FFFFFF` (unchanged), border 2 pt solid `#00478D`, icon 24 pt `#6B7280` (unchanged), label Inter SemiBold 13 pt `#374151` (unchanged), `check_circle` 18 pt `#00478D` badge positioned at the top-start corner of the card (RTL: top-right) via a `Stack` with `Positioned(top: 6, start: 6)`.
- Tappable toggle — `InkWell` or `GestureDetector` wrapping the container.
- Padding: `EdgeInsets.all(8)`, internal `Column(mainAxisAlignment: MainAxisAlignment.center)`.
- The earlier solid-fill selected style (background `#00478D`, white icon + text) seen in step-3's original Stitch render is superseded by DD-13 — implement the bordered+badge style across step-3, step-4, and onboarding.

### Variant D — Caution allergen chip (Product Details — Caution state)
Read-only chip for an allergen present as "may contain" / trace. Amber styling,
the caution analog of Variant B.

- Shape: `BorderRadius.circular(20)` (fully rounded pill).
- Background: `#FEF9C3` (light amber).
- Border: 1 pt solid `#CA8A04` (amber).
- Icon: allergen-specific Material icon, 16 pt, `#CA8A04`.
- Label: Inter SemiBold 13 pt, `#A16207`.
- Padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`.
- Not tappable. Used in the product-detail Caution state (no standalone Stitch
  screen; specced as a state in `product-details-safe.md` §5).

### Allergen icon mapping (all variants share the same icon per allergen)
| Allergen (HE) | Allergen (EN) | Material Icon |
|---|---|---|
| חלב | Milk | `water_drop` |
| ביצים | Eggs | `egg` |
| גלוטן | Gluten | `grass` |
| סויה | Soy | `nutrition` |
| בוטנים | Peanuts | `park` |
| אגוז מלך | Walnut | `energy_savings_leaf` |
| שקד | Almond | `nature` |
| קשיו | Cashew | `emoji_nature` |
| פיסטוק | Pistachio | `grain` |
| פקאן | Pecan | `local_florist` |
| אגוז לוז | Hazelnut | `spa` |
| צנובר | Pine nut | `eco` |
| שומשום | Sesame | (TBD — not confirmed from screenshots) |

### Props (Flutter widget interface — shared enum)
```dart
AllergenChip({
  required Allergen allergen,
  required AllergenChipVariant variant,  // display | detected | caution | wizardUnselected | wizardSelected
  VoidCallback? onTap,  // null for read-only variants
})
```

### Where each variant appears
| Variant | Screen |
|---|---|
| A — display | home-dashboard (hero card allergen row) |
| B — detected | product-details-avoid (allergen section) |
| C — wizard | add-product-step-3-contains (selection grid) |
| D — caution | product-detail Caution state (product-details-safe.md §5) |

---

## app-bar

The top application bar shared across all screens. Implements RTL layout with the app brand on the right (leading in RTL) and actions on the left (trailing in RTL).

### Structure
- Flutter: `AppBar` or custom `PreferredSizeWidget`, height 56 pt.
- Background: `#FFFFFF` (white), `elevation: 0` (no shadow in resting state; may add 2 pt shadow on scroll).
- **RTL leading (right side):** App logo text "בטוח לאכול" — Inter Medium 16 pt, `AppColors.primary` `#00478D`. OR screen-specific title text in Public Sans SemiBold 16 pt `#1F2937`.
- **RTL trailing (left side):** One or two icon buttons:
  - Standard: `menu` hamburger icon, `#374151`, 24 pt → opens drawer/menu.
  - With avatar: circular avatar widget, ~36 pt diameter, to the left of menu icon.
  - Close variant (wizard screens): `cancel` / `✕` icon, `#374151`, 24 pt → exits the current flow.

### Variants observed

| Variant | Right content | Left content | Screens |
|---|---|---|---|
| Home / brand bar | "בטוח לאכול" logo text | `menu` icon + avatar | home-dashboard |
| Detail bar | Back arrow or `cancel` ✕ | (none or menu) | product-details-avoid |
| Wizard bar | Screen step title ("הוספת מוצר חדש") | `cancel` ✕ only | add-product-step-3-contains |

### Token references
- Background: `AppColors.surface` or `Colors.white`.
- Title: `AppTypography.titleMedium` (Public Sans SemiBold 16 pt, `#1F2937`) for wizard/detail; `AppColors.primary` Inter Medium 16 pt for brand bar.
- Icon color: `AppColors.onSurfaceVariant` `#374151`.

### Notes
- The brand-bar variant uses the app name as a logo (no separate image asset observed in the Stitch design).
- The status banner below the app bar on `product-details-avoid` is **not** part of the AppBar widget — it is a separate sibling widget in the `Column`/`Scaffold` body.

---

## bottom-nav

The persistent bottom navigation bar visible on main content screens. Not shown on modal/wizard flows (add-product wizard has no bottom nav).

### Structure
- Flutter: `NavigationBar` (Material 3) or `BottomNavigationBar`.
- Height: ~56 pt + safe area inset.
- Background: `#FFFFFF`, top border 1 pt `#E5E7EB` (or `BoxShadow` upward).
- **4 tabs** in the app implementation; the Stitch design screenshots also show 4 tabs. (Note: the HTML text extraction mentioned a 5th "מועדפים" tab — this may be an artefact of the extraction. Visual screenshot confirms 4 tabs. See open question in home-dashboard.md §7.4.)

### Tabs (RTL order, right → left)

| Position (RTL) | Label | Icon (unselected) | Icon (selected) | Route/Index |
|---|---|---|---|---|
| 1 (rightmost) | "בית" | `home` outline | `home` filled | index 0 — HomeScreen |
| 2 | "סריקה" | `qr_code_scanner` outline | `qr_code_scanner` filled | index 1 — SearchScanScreen |
| 3 | "קהילה" | `groups` outline | `groups` filled | index 2 — CommunityScreen |
| 4 (leftmost) | "מועדפים" | `favorite_border` | `favorite` | index 3 — FavoritesScreen |

### Active state (pill indicator — see _design-decisions.md#dd-6)
- Active tab sits inside a **rounded-rectangle pill background** (Material-3
  `NavigationBar` indicator): radius ~12 pt, padding ~16 pt horiz / 6 pt vert,
  fill `AppColors.primary` @ ~40% (`primary-container` tint).
- Active tab icon: filled variant, `AppColors.primary` `#00478D`.
- Active tab label: Inter SemiBold 11 pt, `#00478D`.
- Inactive tab icon: outline variant, `#9CA3AF`; label Inter Regular 11 pt `#9CA3AF`.
- (Earlier specs that described a "flat, no pill" active style are superseded by
  DD-6 — they reference this glossary entry and inherit the pill.)

### Where it appears
- `home-dashboard` — "בית" active.
- `product-details-avoid` — "סריקה" active (product was reached via scan/search flow).
- `add-product-step-3-contains` — **NOT present** (wizard modal flow).

### Resolved: tab 4 = Favorites (see _design-decisions.md#dd-2)
Canonical bottom-nav is בית / סריקה / קהילה / **מועדפים** (Home / Scan /
Community / Favorites, index 0–3). **Settings is NOT a bottom-nav tab** — it is
reached via the navigation drawer (`nav-drawer-user`). Specs follow this Stitch
design intent; the app's current "Settings" tab 4 is a delta to realign.

---

## primary-button

The main call-to-action button. Full-width or near-full-width, always the most prominent interactive element on its screen section.

### Structure
- Flutter: `ElevatedButton` or `FilledButton`, height 48 pt, border-radius 12 pt.
- Width: full-width within 16 pt horizontal margins, or `(screenWidth - 48) / 2` in two-button rows.
- Font: Inter SemiBold 14 pt, `#FFFFFF`.
- Padding: `EdgeInsets.symmetric(horizontal: 24, vertical: 12)`.

### Variants observed

| Variant | Background | Border | Icon | Label | Screen |
|---|---|---|---|---|---|
| Primary / Continue | `#00478D` (AppColors.primary) | none | `chevron_left` (RTL trailing) | "המשך" | add-product-step-3-contains |
| Avoid / Danger | `#DC2626` (AppColors.avoid TBD) | none | `warning` | (exact label TBD — see product-details-avoid §7.1) | product-details-avoid |
| Standard CTA | `#00478D` | none | optional | varies | other screens |

### States
| State | Visual |
|---|---|
| Default | Filled background per variant |
| Pressed | `#003F7D` (darker primary) or `#B91C1C` (darker avoid) — 10% darkened |
| Disabled | Background `#D1D5DB`, text `#9CA3AF` |
| Loading | `CircularProgressIndicator(color: Colors.white, strokeWidth: 2)` replaces label |

### Where it appears
- `add-product-step-3-contains` — "המשך" (Continue), Primary variant.
- `product-details-avoid` — Avoid/Danger action, Avoid variant.
- Expected on other screens (onboarding, step 4, etc.) in Primary variant.

### Props
```dart
PrimaryButton({
  required String label,
  required VoidCallback? onPressed,  // null → disabled state
  IconData? leadingIcon,             // RTL leading (right side) — e.g. Icons.groups
  IconData? trailingIcon,            // RTL trailing (left side) — e.g. chevron_left
  PrimaryButtonVariant variant = PrimaryButtonVariant.standard,  // standard | avoid
  bool isLoading = false,
})
```

---

## wizard-chrome

Canonical shell for the 4-step Add-Product wizard (see _design-decisions.md#dd-5).
Steps disagree in Stitch; THIS is the canonical chrome — each step spec
references this entry and records its own Stitch delta in §7.

### Structure
- **App bar:** title "הוספת מוצר חדש" (Public Sans SemiBold 16 pt, `#1F2937`),
  with a step subtitle below it ("שלב N מתוך 4" or the step's name, Inter
  Regular 12 pt, `#6B7280`). RTL-trailing `cancel` ✕ exits the wizard. No
  bottom-nav anywhere in the wizard.
- **Progress:** a **linear progress bar** directly under the app bar — filled
  track `AppColors.primary` `#00478D`, unfilled `#E5E7EB`, height ~4 pt, fill =
  step/4. (NOT the numbered-node stepper seen on step 1.)
- **Footer nav row:** right→left in RTL —
  - "חזרה" outlined button (`#00478D` border+text, transparent bg) — present on
    steps **2, 3, 4**; absent on step 1.
  - "המשך" primary button (`#00478D` fill, white text) with `chevron_left`
    trailing icon (RTL forward). On step 4 the label is the step's submit verb.

### Props
```dart
WizardChrome({
  required int step,          // 1..4 → progress fill + back-button visibility
  required String stepName,   // subtitle
  required Widget body,
  required VoidCallback? onContinue,
  VoidCallback? onBack,       // null on step 1
  String continueLabel = 'המשך',
})
```

### Where it appears
- `add-product-step-1-barcode`, `-step-2-photos`, `-step-3-contains`,
  `-step-4-may-contain`. Step 3 already matches this canon (exemplar).

---

## product-row

A horizontal list-row card representing a single product in any list context: the
home-dashboard "פעילות אחרונה" feed, the active-search-results list, and any
future saved-products / scan-history list. Canonical per DD-16; specs reference
this entry instead of re-describing the row.

### Structure
- `Card` (`elevation: 0`) or `Container` with `BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0,2))])`.
- Padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 12)`. Row gap inside the list: 8 pt (or a 1 pt `#F3F4F6` divider).
- Internal `Row` (RTL leading → trailing):
  1. **Status pill** (RTL leading / right): `see #status-pill`. Always rendered, even for safe products. Per DD-3 the label is the fixed verdict text only.
  2. **Optional 24 pt status icon** (Variant B only — see below): filled `check_circle` / `info` / `warning` in the matching status color, between the pill and the text column.
  3. **Text column** (`Expanded`, `CrossAxisAlignment.end` for RTL): product name (Inter SemiBold 14–15 pt, `#1F2937`) on line 1; secondary line (Inter Regular 12–13 pt, `#9CA3AF`/`#6B7280`) on line 2.
  4. **Thumbnail** (RTL trailing / left): `ClipRRect(borderRadius: BorderRadius.circular(8))`, 40 × 40 pt (compact variant) or 56 × 56 pt (detailed variant), `BoxFit.cover`. Placeholder: grey `#E5E7EB` block with `Icons.fastfood` `#9CA3AF`.

### Variants

| Variant | Status icon | Thumbnail | Secondary line | Used on |
|---|---|---|---|---|
| **A — Compact (history/activity)** | none | 40 × 40 pt | timestamp ("לפני שעה", "אתמול") | `home-dashboard` recent-activity, future scan-history list |
| **B — Detailed (search/results)** | 24 pt filled status icon | 56 × 56 pt | brand · weight ("אסם • 80 גרם") + optional contextual text ("מכיל אגוזי לוז") below the pill | `active-search-results`, future saved-products |

The contextual text in Variant B sits as a separate `Text` widget below the status-pill within the text column — per DD-3 it is NOT part of the pill component.

### Props (Flutter widget interface)
```dart
ProductRow({
  required Product product,
  required UserProfile userProfile,   // drives status computation
  required ProductRowVariant variant, // compact | detailed
  String? timestampLabel,              // Variant A
  String? contextualText,              // Variant B (e.g. "מכיל אגוזי לוז")
  VoidCallback? onTap,
})
```

### Where it appears
- `home-dashboard` recent-activity → Variant A.
- `active-search-results` → Variant B.

---

## filter-chip

A segmented selector of three chip-pills representing the three allergen-safety
verdicts (avoid / caution / safe), reusing the `status-pill` color palette.
Canonical per DD-16; currently used in `settings-profile` for the "רמת סינון
מוצרים" preference, and reusable wherever a user filters a product list by
safety.

### Structure
- `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` containing three chip widgets, each `Expanded` (equal width) with 8 pt gap.
- Each chip:
  - Shape: `BorderRadius.circular(20)` (fully rounded pill).
  - Padding: `EdgeInsets.symmetric(horizontal: 8, vertical: 6)`.
  - Border: 1.5 pt solid (variant-specific colour when selected; `#E5E7EB` when unselected).
  - Label: Inter SemiBold 12 pt when selected, Inter Regular 12 pt when unselected, `TextAlign.center`.
  - Single-select within the row (radio semantics).

### Variants (selected state uses status-pill palette)

| Variant | Selected bg | Selected border | Selected text | Unselected style | Default label |
|---|---|---|---|---|---|
| Avoid / לא בטוח | `#FEE2E2` | `#DC2626` | `#991B1B` | white bg + `#E5E7EB` border + `#6B7280` text | "לא בטוח" |
| Caution / בטוח חלקית | `#FEF9C3` | `#CA8A04` | `#A16207` | same | "בטוח חלקית" |
| Safe / בטוח לחלוטין | `#DCFCE7` | `#16A34A` | `#15803D` | same | "בטוח לחלוטין" |

### Props
```dart
FilterChipRow({
  required AllergenStatus value,                // current selection
  required ValueChanged<AllergenStatus> onChanged,
})
```

### Where it appears
- `settings-profile` → "רמת סינון מוצרים" preference, default "בטוח חלקית".

---

## success-badge-pair

A horizontal pair of small inline badges shown below the headline on terminal
success screens. They communicate the *processing state* of the just-submitted
contribution (e.g. "pending approval" + "verification status") and are visually
distinct from `status-pill` (which encodes allergen safety verdicts). Canonical
per DD-16.

### Structure
- `Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min)` with two badges and an 8 pt gap.
- Each badge:
  - `Container` with `BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor, width: 1))`.
  - Padding: `EdgeInsets.symmetric(horizontal: 10, vertical: 4)`.
  - Internal `Row(mainAxisSize: MainAxisSize.min)`: 16 pt icon → gap 6 pt → label (Inter Medium 12 pt).

### Standard variants

| Badge role | Background | Border | Icon | Label color |
|---|---|---|---|---|
| Neutral / pending | `#F3F4F6` | none (or implicit) | `pending` / `schedule` | `#6B7280` |
| Brand / verified | `#EBF4FF` | `#BFDBFE` | `verified_user` / `shield` | `#00478D` |
| Success / community-safe | `#DCFCE7` (tint of `AppColors.success`) | `#86EFAC` | `verified` / `groups` | `#15803D` |

The two screens currently using this pair pick role pairs from the variants
above:

| Screen | Badge A | Badge B |
|---|---|---|
| `add-product-success` | Neutral "ממתין לאישור" (`pending`) | Brand "סטטוס בדיקה" (`verified_user`) |
| `report-success` | Success "נבדק ע״י מערכת" (`verified`) | Brand "קהילה בטוחה" (`groups`) |

### Props
```dart
SuccessBadgePair({
  required SuccessBadgeData first,
  required SuccessBadgeData second,
})

class SuccessBadgeData {
  final SuccessBadgeRole role; // neutral | brand | success
  final IconData icon;
  final String label;
}
```

### Where it appears
- `add-product-success` §4.5, `report-success` §4.4.

---

## Material 3 adoption

Per DD-12, this spec set targets **Material 3**. App-side requirements:

- `ThemeData(useMaterial3: true)`.
- A `ColorScheme` exposing the tokens referenced throughout these specs: `primary` `#00478D`, `primaryContainer` `#005EB8`, `onPrimary` `#FFFFFF`, `secondary` `#006B5B`, `secondaryContainer` `#78F8DD`, `surface` `#F8F9FA`, `surfaceContainerLow` `#F3F4F6`, `surfaceContainerHigh` `#E5E7EB`, `surfaceContainerHighest` `#E1E3E4`, `outline` `#727783`, `outlineVariant` `#E5E7EB`.
- App-specific extension tokens (outside the `ColorScheme`): `AppColors.safe` `#16A34A`, `AppColors.caution` `#CA8A04`, `AppColors.avoid` `#DC2626`, `AppColors.success` `#0D9488` (per DD-10), `AppColors.destructiveSubtle` `#FECDD3`, `AppColors.onDestructiveSubtle` `#9F1239` (logout button on drawers, per nav-drawer-user §7.2).
- Bottom-nav must use `NavigationBar` (M3) to get the DD-6 pill indicator; `BottomNavigationBar` (M2) cannot reproduce it.
- `FilledButton` (M3-only) appears in `admin-trusted-brands §4.6` and may be used wherever a non-full-width primary action is required.
