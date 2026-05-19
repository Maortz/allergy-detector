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
- Padding: `EdgeInsets.symmetric(horizontal: 10, vertical: 4)` (AppSpacing: 10 = 2.5×4 px, use 8 or 12; exact value TBD).
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

### Variant C — Wizard selection chip (Add Product Step 3)
Interactive square-ish toggle card for selecting which allergens a product contains.

- Shape: `BorderRadius.circular(12)`.
- Size: `(screenWidth - 48) / 2` wide (2-per-row grid with 16 pt margins and 8 pt gap), 72 pt tall.
- **Unselected:** Background `#FFFFFF`, border 1.5 pt solid `#E5E7EB`, icon 24 pt `#6B7280`, label Inter SemiBold 13 pt `#374151`.
- **Selected:** Background `#00478D`, no border, icon 24 pt `#FFFFFF`, label Inter SemiBold 13 pt `#FFFFFF`.
- Tappable toggle — `InkWell` or `GestureDetector` wrapping the container.
- Padding: `EdgeInsets.all(8)`, internal `Column(mainAxisAlignment: MainAxisAlignment.center)`.

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
  IconData? trailingIcon,
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
