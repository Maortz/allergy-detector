# הוספת מוצר - שלב 1 / Add Product — Step 1 (Barcode)
Stitch screen: projects/16588854804615693446/screens/ffdb6626d62944548656cee7494af945
Maps to: app/lib/screens/add_product_screen.dart

## 1. Purpose & context

This is step 1 of a 4-step "Add New Product" wizard. It serves as the entry point for the community contribution flow — a user who has found a product not yet in the Supabase database can add it. Step 1 collects the barcode (via camera scan or manual entry), the product name, and the brand/manufacturer. Completing this step and tapping "המשך" advances to step 2 (ingredients/components — "רכיבים"), which then leads to step 3 (contains allergens) and step 4 (may-contain allergens).

The wizard is a modal flow; the standard main-app bottom navigation bar should **not** be present (see inconsistency note §7.1 and _components-glossary.md#bottom-nav).

The screen has two primary input paths that converge: camera-based barcode scanning populates the barcode field automatically; manual entry lets users type the barcode directly. Either path must populate the same wizard state before proceeding.

## 2. Visual layout breakdown

Canvas: 780 × 2044 px @2× (390 pt wide). Background: `#F8F9FA`.

### App bar (top)
- White background, `elevation: 0`, 56 pt tall, `border-b border-neutral-100` (1 pt bottom border `#F3F4F6`).
- **RTL leading (right):** `chevron_right` icon (`#005EB8` / `AppColors.primary`, 24 pt) + "הוספת מוצר - שלב 1" — Public Sans SemiBold 18 pt (matches `text-lg` / `font-h3` in HTML), `#1F2937` (on-surface), right-aligned.
- **RTL trailing (left):** `close` icon, `#6B7280` (neutral-500), 24 pt — exits the wizard entirely.
- The back arrow (`chevron_right`) navigates back within the wizard or dismisses if on the first step. See [_components-glossary.md#app-bar](_components-glossary.md#app-bar) for the wizard variant.

> Note: The app bar title on this screen includes the step number ("שלב 1") embedded in the title text, whereas step 3's title is "הוספת מוצר חדש" (no step number). This is a design inconsistency — see §7.2.

### Horizontal step stepper
- Located directly below the app bar, ~32 pt top margin (`pt-20` from body + `mb-8`).
- Three step circles connected by horizontal divider lines in a full-width `Row`.
- Each step circle: 32 × 32 pt, `border-radius: 50%`.
- Active step (1 — "פרטי מוצר"):
  - Circle background: `AppColors.primary` `#00478D`.
  - Circle label: "1" — Inter SemiBold 14 pt, `#FFFFFF`.
  - Sub-label: "פרטי מוצר" — Inter Medium 12 pt, `#00478D` (primary).
- Inactive steps (2 — "רכיבים", 3 — "אלרגנים"):
  - Circle background: `#E1E3E4` (`surface-container-highest`), opacity 40%.
  - Circle label: "2" / "3" — Inter SemiBold 14 pt, `#191C1D` (on-surface-variant, also opacity 40%).
  - Sub-label: "רכיבים" / "אלרגנים" — Inter Medium 12 pt, `#191C1D`, opacity 40%.
- Connector lines between circles: `height: 2px`, `#E7E8E9` (`surface-container-high`), vertically centred at circle mid-point (`mt-[-20px]`), flex-1 width.

> Note: Only 3 steps are rendered in the stepper circles, but the footer label reads "שלב 1 מתוך 4". The 4th step (may-contain allergens) is not shown in the stepper — see §7.3.

### Scanner card
- White card (`#FFFFFF`), `border-radius: 12 pt` (`rounded-xl`), `box-shadow: sm`, `border: 1pt solid #F3F4F6`, `overflow: hidden`.
- **Card header (text block):**
  - "סריקת ברקוד" — Public Sans SemiBold 20 pt (`font-h3 text-h3`), `#191C1D`, right-aligned, 16 pt horizontal padding, 16 pt top padding.
  - "כוון את המצלמה אל הברקוד שעל גבי אריזת המוצר" — Inter Medium 12 pt (`text-label-sm`), `#727783` (outline/on-surface-variant), right-aligned, ~4 pt below heading.
- **Camera viewport:**
  - `aspect-ratio: video` (16:9), black/dark background (`#171717` neutral-900), `opacity-80` on the camera image.
  - Scanning overlay: a rectangular bracketed frame positioned 20% from top/bottom, 10% from left/right, `border: 2px solid #005EB8`, `border-radius: 12pt`, with a dark scrim (`rgba(0,0,0,0.4)`) outside the frame.
  - Scanning line: horizontal, centred vertically within the frame region, `height: 2px`, `background: #005EB8`, `box-shadow: 0 0 15px #005EB8` (blue glow), spanning from ~15% to ~85% of viewport width.
  - **Camera overlay buttons** (bottom of viewport, absolutely positioned, `z-index: 30`):
    - Two circular icon buttons side by side, centred horizontally.
    - Style: `background: rgba(255,255,255,0.20)`, `backdrop-filter: blur(md)`, `border-radius: 50%`, 48 pt touch target (`p-3` + icon), white icon, hover → `rgba(255,255,255,0.30)`.
    - Left button: `flashlight_on` icon (torch toggle).
    - Right button: `photo_library` icon (open from gallery/photo library).

### Form fields (below scanner card)
- `gap: 24 pt` between fields (`space-y-6`), full-width within 20 pt horizontal margins.

#### Field 1 — Barcode number (manual entry)
- Label: "מספר ברקוד (ידני)" — Inter SemiBold 14 pt (`font-label-bold text-label-bold`), `#191C1D`, right-aligned, `pr-1` padding.
- Input: `TextField`, `height: 48 pt`, full-width, `border-radius: 8 pt` (`rounded-lg`), border color `#727783` (outline-variant), focus border `#00478D` + `ring: 1pt #00478D`, background `#FFFFFF`, text right-aligned.
- Placeholder: "הקלד או סרוק ברקוד" — (placeholder style, greyed).
- **Trailing icon (RTL left side):** `barcode` Material Symbol, `#727783` (outline color), 24 pt, absolutely positioned at left-centre of input (`absolute left-4 top-1/2 -translate-y-1/2`).

#### Field 2 — Product name
- Label: "שם המוצר" — Inter SemiBold 14 pt, `#191C1D`, right-aligned.
- Input: `TextField`, `height: 48 pt`, full-width, same styling as barcode field, no trailing icon.
- Placeholder: "לדוגמה: דגני בוקר קלאסיים".

#### Field 3 — Brand / manufacturer (dropdown)
- Label: "מותג / יצרן" — Inter SemiBold 14 pt, `#191C1D`, right-aligned.
- Control: `DropdownButton` / `<select>`, `height: 48 pt`, full-width, `border-radius: 8 pt`, border `#727783`, focus border `#00478D`, background `#FFFFFF`, text right-aligned (`text-right appearance-none`).
- Default placeholder option: "בחר מותג מהרשימה" (disabled/selected by default, value empty).
- Available options (pre-loaded): "תנובה", "שטראוס", "אסם", "יוניליוור", "אחר…".
- **Trailing icon:** `expand_more` Material Symbol, `#727783`, 24 pt, absolutely positioned at left-centre (`pointer-events-none`).

### Continue button
- Below form fields, `mt-48 pt` (`mt-12`), `mb-32 pt` (`mb-8`).
- Full-width: `w-full`, `height: 56 pt` (`py-4` + `text-h3`), `border-radius: 12 pt` (`rounded-xl`).
- Background: `AppColors.primary` `#00478D`.
- Label: "המשך" — Public Sans SemiBold 20 pt (`font-h3 text-h3`), `#FFFFFF`.
- Icon: `arrow_back` Material Symbol, `#FFFFFF`, 24 pt — positioned to the left of text (RTL trailing; `arrow_back` = left-pointing arrow = RTL "forward").
- Shadow: `shadow-lg`.
- Press: `active:scale-95 transition-transform` (95% scale spring).
- See [_components-glossary.md#primary-button](_components-glossary.md#primary-button) for shared button spec.

> Note: Step 3 uses `chevron_left` as the continue icon; step 1 uses `arrow_back`. Both are left-pointing (RTL "forward") but are different icons — see §7.4.

### Step counter footer label
- Below the continue button: "שלב 1 מתוך 4" — Inter Medium 12 pt (`text-label-sm`), `#727783` (`text-outline`), centre-aligned.

Resolved per _design-decisions.md#dd-5: wizard screens have NO bottom navigation bar. The bottom nav rendered in this screen's Stitch HTML is a Stitch artifact (§7 delta). See also _design-decisions.md#dd-4 for the non-canonical tab labels. Canonical wizard chrome is defined in `_components-glossary.md#wizard-chrome`.

## 3. Component inventory

| Element | Design-system token / colour | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary (wizard variant) | Public Sans SemiBold 18 pt | `chevron_right` (back), `close` (exit) | "הוספת מוצר - שלב 1" | Back icon colour: `#005EB8`; inconsistency §7.2 |
| Step circle — active | `AppColors.primary` `#00478D` bg | Inter SemiBold 14 pt | — | "1" | Sub-label: "פרטי מוצר", Inter Medium 12 pt, `#00478D` |
| Step circle — inactive | `#E1E3E4` bg, opacity 40% | Inter SemiBold 14 pt | — | "2", "3" | Sub-labels: "רכיבים", "אלרגנים", Inter Medium 12 pt, opacity 40% |
| Step connector | `#E7E8E9` | — | — | — | 2 pt height, flex-1 width |
| Scanner card heading | `#191C1D` | Public Sans SemiBold 20 pt | — | "סריקת ברקוד" | — |
| Scanner card sub-text | `#727783` | Inter Medium 12 pt | — | "כוון את המצלמה אל הברקוד שעל גבי אריזת המוצר" | — |
| Camera viewport | — | — | — | — | 16:9 aspect, dark bg, blue scan frame + line |
| Torch button | `rgba(255,255,255,0.20)` bg | — | `flashlight_on` | — | White icon, backdrop-blur |
| Gallery button | `rgba(255,255,255,0.20)` bg | — | `photo_library` | — | White icon, backdrop-blur |
| Field label — barcode | `#191C1D` | Inter SemiBold 14 pt | — | "מספר ברקוד (ידני)" | — |
| Barcode text input | `#FFFFFF` bg, border `#727783` | Inter Regular 16 pt | `barcode` (trailing) | placeholder: "הקלד או סרוק ברקוד" | h=48 pt, radius 8 pt |
| Field label — product name | `#191C1D` | Inter SemiBold 14 pt | — | "שם המוצר" | — |
| Product name text input | `#FFFFFF` bg, border `#727783` | Inter Regular 16 pt | — | placeholder: "לדוגמה: דגני בוקר קלאסיים" | h=48 pt, radius 8 pt |
| Field label — brand | `#191C1D` | Inter SemiBold 14 pt | — | "מותג / יצרן" | — |
| Brand dropdown | `#FFFFFF` bg, border `#727783` | Inter Regular 16 pt | `expand_more` (trailing) | placeholder: "בחר מותג מהרשימה" | h=48 pt, radius 8 pt |
| Brand options | — | Inter Regular 16 pt | — | "תנובה", "שטראוס", "אסם", "יוניליוור", "אחר…" | Supabase-loaded in production |
| Continue button | `AppColors.primary` `#00478D` | Public Sans SemiBold 20 pt | `arrow_back` | "המשך" | see glossary#primary-button; icon inconsistency §7.4 |
| Step counter footer | `#727783` | Inter Medium 12 pt | — | "שלב 1 מתוך 4" | Centre-aligned |

## 4. Sub-components / element design

### Horizontal step stepper
The step indicator on this screen is a **horizontal node stepper** — meaningfully different from the linear progress bar (track + percentage text) used on step 3. This is the primary structural inconsistency between these sibling screens.

```dart
Row(
  children: [
    // For each step i in [1, 2, 3]:
    //   Column(children: [stepCircle(i), stepLabel(i)])
    //   if not last: Expanded(child: Divider(height: 2, color: Color(0xFFE7E8E9)))
  ],
)
```

Active circle:
```dart
Container(
  width: 32, height: 32,
  decoration: BoxDecoration(
    color: Color(0xFF00478D),
    shape: BoxShape.circle,
  ),
  child: Center(child: Text('1',
    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600,
                     fontSize: 14, color: Colors.white))),
)
```

Inactive circle (with 40% opacity wrapper):
```dart
Opacity(
  opacity: 0.40,
  child: Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      color: Color(0xFFE1E3E4),
      shape: BoxShape.circle,
    ),
    child: Center(child: Text('2',
      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600,
                       fontSize: 14, color: Color(0xFF191C1D)))),
  ),
)
```

### Camera viewport / scanner card
- The scanner card is a `Card` / `Container` with `ClipRRect(borderRadius: BorderRadius.circular(12))`.
- The viewport `Stack`:
  1. `CameraPreview(...)` or `MobileScanner(...)` widget filling the 16:9 area.
  2. Scan-frame overlay: a custom painter or `CustomPaint` drawing the blue rounded-rect border and the dark scrim outside it.
  3. Scanning line: `AnimatedPositioned` (laser animation, see CLAUDE.md operational note — do NOT `pumpAndSettle` in tests for this screen).
  4. Overlay buttons row: `Positioned(bottom: 16, child: Row([torchButton, galleryButton]))`.

The scanning frame rectangle (CSS): `top: 20%, left: 10%, right: 10%, bottom: 20%` of the viewport. In Flutter, calculate absolute coordinates from the viewport size at render time.

The torch and gallery buttons:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(9999),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    child: Container(
      color: Colors.white.withOpacity(0.20),
      padding: EdgeInsets.all(12),
      child: Icon(Icons.flashlight_on, color: Colors.white, size: 24),
    ),
  ),
)
```

### Form fields (shared pattern)
All three fields follow the same Flutter structure:
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Padding(
      padding: EdgeInsets.only(right: 4),
      child: Text(label,
        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600,
                         fontSize: 14, color: Color(0xFF191C1D))),
    ),
    SizedBox(height: 8),
    Stack(children: [
      TextField(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: placeholder,
          filled: true, fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF727783)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF00478D), width: 1),
          ),
        ),
      ),
      // Trailing icon (barcode field and brand dropdown only):
      Positioned(
        left: 16, top: 0, bottom: 0,
        child: Icon(Icons.barcode_scanner /* or expand_more */,
                    color: Color(0xFF727783), size: 24),
      ),
    ]),
  ],
)
```

The brand dropdown (`DropdownButtonFormField` or `DropdownButton`) uses the same border/radius decoration. Options "תנובה" / "שטראוס" / "אסם" / "יוניליוור" / "אחר…" are shown in the Stitch design; in production these should be loaded from the Supabase `brands` table.

### Continue button
```dart
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _onContinue,
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF00478D),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),
    icon: Icon(Icons.arrow_back, size: 24),  // RTL trailing = "forward"
    label: Text('המשך',
      style: TextStyle(fontFamily: 'Public Sans', fontWeight: FontWeight.w600,
                       fontSize: 20)),
  ),
)
```

## 5. States & interactions

| State | Trigger | Visual change |
|---|---|---|
| Default / camera live | Screen loads | Camera preview active, scan line animating, barcode field empty |
| Scanning active | Camera sees barcode | Auto-populates barcode field; may auto-advance if product found in DB |
| Product already in DB | Barcode scan/entry matches existing product | Show in-screen alert/snackbar: product exists, offer to view instead of add (exact UX TBD — see §7.5) |
| Barcode field — focused | User taps field | Border → `#00478D` + 1 pt focus ring; keyboard opens |
| Barcode field — populated (auto) | Scanner detected barcode | Field text = detected barcode string; camera may pause/dim |
| Product name — focused | User taps field | Border → `#00478D`, keyboard opens |
| Brand — dropdown open | User taps dropdown | System/custom picker opens with option list |
| Brand — selected | User picks brand | Dropdown shows selected brand name |
| Torch toggled on | User taps `flashlight_on` | Button highlight increases (`rgba(255,255,255,0.40)`); device torch activates |
| Gallery tapped | User taps `photo_library` | OS image picker opens; selected image processed for barcode |
| Continue — valid | Barcode + product name filled, brand selected | Navigates to step 2 (ingredients/רכיבים) |
| Continue — invalid | Required fields empty | Inline validation errors shown below empty required fields (exact validation wording TBD — see §7.6) |
| Close tapped | User taps `close` (✕) | Confirmation dialog "לצאת מהוספת מוצר?" → dismisses wizard |
| Back tapped | User taps `chevron_right` | On step 1, same as close (first step, no prior wizard step to return to); or dismiss silently |

## 6. Data & controller contract

**Wizard state (accumulated across all 4 steps):**
- `String barcodeNumber` — populated on this step (auto from scanner or manual).
- `String productName` — entered on this step.
- `String? brandId` — selected brand's Supabase `brands.id`; "אחר…" maps to a free-text flow or `null` pending brand creation.
- `String? brandName` — display name of selected brand.
- `Set<String> containsAllergenIds` — populated on step 3.
- `Set<String> mayContainAllergenIds` — populated on step 4.

**Static / loaded data:**
- `List<Brand> brandList` — fetched from Supabase `brands` table at wizard start, populates the dropdown. The Stitch design shows five hard-coded options; production must load dynamically.
- `MobileScannerController` — controls camera lifecycle, torch state, and barcode detection callbacks.

**Callbacks / methods on wizard controller:**
- `onBarcodeScanned(String barcode)` — populates `barcodeNumber`, optionally checks if product exists.
- `onTorchToggled()` — toggles `MobileScannerController` torch.
- `onGallerySelected()` — opens image picker and processes for barcode.
- `onNext()` — validates required fields (barcode + name), persists step-1 data to wizard state, navigates to step 2.
- `onClose()` — exits wizard with confirmation dialog.

**On step completion:**
- Step-1 data (`barcodeNumber`, `productName`, `brandId`) saved to wizard state.
- Navigation → step 2 (ingredients screen, not yet specced).
- On final submit (step 4): `ProductService.addProduct(...)` writes to Supabase `products` + `product_allergens`.

**Camera lifecycle:**
- `MobileScannerController` must be started in `initState` and disposed in `dispose`.
- On web: camera access may be unavailable; the manual barcode entry field must still function. Scanner card should degrade gracefully (show a "camera not available" placeholder instead of the viewport).

## 7. Open questions / design-vs-app deltas

1. **Bottom nav on wizard screens:** Resolved per _design-decisions.md#dd-5 and DD-4. Wizard screens have NO bottom navigation bar; the bottom nav in step 1's Stitch HTML is a Stitch artifact. Do not implement. See `_components-glossary.md#wizard-chrome` and `_components-glossary.md#bottom-nav`.

2. **App bar title format — resolved per DD-5.** Canonical title = "הוספת מוצר חדש" + "שלב N מתוך 4" subtitle, all four steps. Step 1's "הוספת מוצר - שלב 1" embedding is a Stitch artifact.

3. **Stepper type — resolved per DD-5.** Canonical progress indicator is a **linear progress bar** on all four steps (see `_components-glossary.md#wizard-chrome`). Step 1's numbered-node stepper is a Stitch artifact.

4. **Continue icon — resolved per DD-5.** Canonical wizard continue icon is `chevron_left` (RTL forward) across all four steps. Step 1's `arrow_back` is a Stitch artifact; implement `chevron_left` per `_components-glossary.md#wizard-chrome`.

5. **Duplicate barcode — resolved (redirect with toast).** When a scanned or typed barcode matches an existing product, navigate to that product's detail screen via `Navigator.pushReplacement` and show a `SnackBar`: "המוצר כבר קיים במאגר. הנה הפרטים שלו." with a "דווח על טעות" action linking to the report-issue form. The wizard is dismissed; user can re-enter from Community Hub if they want to add a different product.

6. **Required field validation — resolved.** Required: **product name** (`productName.trim().isNotEmpty`) and **brand** (`brandId != null` OR "אחר..." selected with non-empty free-text). Optional: **barcode** (manual-entry path allowed without scan). Error copy below empty required field, Inter Regular 12 pt `#DC2626`: name → "נא למלא שם מוצר"; brand → "נא לבחור מותג". Continue button disabled until both required fields are valid.

7. **Brand "אחר..." flow — resolved.** Selecting "אחר…" reveals a free-text input field below the dropdown (animated `AnimatedSize` expansion). Label: "שם המותג" — Inter SemiBold 14 pt, `#191C1D`. Placeholder: "הקלד שם מותג חדש". On wizard submit (Step 4) the free-text creates a new row in `brands` with `is_verified = false` and `last_updated = now()`; the new brand's UUID is stored on the product. Required when "אחר..." is chosen.

8. **Camera not available — resolved.** When the camera is unavailable (web, emulator, or denied permission), the scanner viewport renders a static placeholder: a 16:9 `Container` with `#1F2937` background, `Icons.no_photography` 48 pt `#9CA3AF` centred, and a label "המצלמה לא זמינה" (Inter Regular 14 pt `#9CA3AF`) 8 pt below the icon. The manual barcode-entry `TextField` remains functional. On Android/iOS permission-denied: tapping the placeholder triggers `Permission.camera.request()` and re-attempts on grant.

9. **Step 2 dep — resolved.** Step 2 (`add-product-step-2-photos.md`) is specced; step 1's "המשך" advances via `_pageController.animateToPage(1)`.

### 7.10 Implementation deltas — verification pass 2026-05-24 <!-- DIVERGED -->

Spec-parity check of `app/lib/screens/add_product_screen.dart` (step 1 branch — `_buildStep1()`).
**Result: step 1 is substantially unimplemented; the barcode/camera flow is replaced by a placeholder Container.** Verified = ⚠. No code change this pass (documented only).

Aligned: `Directionality(rtl)` wraps the wizard; step state is tracked via `_currentStep`; barcode `TextEditingController` exists; brand `DropdownButtonFormField` exists.

| # | Spec requirement | Current code |
|---|---|---|
| S1-1 | App-bar title "הוספת מוצר חדש" (wizard-chrome canon) | `AppBar(title: Text('הוסף מוצר'))` — wrong copy, no step subtitle |
| S1-2 | Linear progress bar (wizard-chrome canon per DD-5) | `ProgressStepper` (numbered-node stepper widget) — wrong component type |
| S1-3 | Scanner card with live `MobileScanner` / `CameraPreview`, 16:9 viewport, blue scan-frame overlay, animated laser line | `Container(height: 200)` placeholder with `Icons.camera_alt` — no actual camera integration |
| S1-4 | Torch toggle button (`flashlight_on`) and gallery button (`photo_library`) inside camera viewport | Absent entirely |
| S1-5 | Barcode field label "מספר ברקוד (ידני)", placeholder "הקלד או סרוק ברקוד", trailing `barcode` icon | `labelText: 'ברקוד ידני'` (wrong), `prefixIcon: Icons.qr_code` (wrong position/icon — spec says RTL-left trailing `barcode`) |
| S1-6 | Product-name field label "שם המוצר", placeholder "לדוגמה: דגני בוקר קלאסיים", no icon | `labelText: 'שם המוצר *'` (has asterisk, wrong), `prefixIcon: Icons.shopping_bag` (extraneous icon) |
| S1-7 | Brand dropdown label "מותג / יצרן", placeholder "בחר מותג מהרשימה", trailing `expand_more`, options from Supabase brands table | `labelText: 'מותג'` (missing "/ יצרן"), placeholder "בחר מותג (אופציונלי)" (wrong), `prefixIcon: Icons.store` (extraneous, wrong position); options sourced from `widget.brands` (passed-in list — acceptable in principle but no Supabase fetch wired) |
| S1-8 | Continue button: `ElevatedButton.icon`, `chevron_left` icon, label "המשך", `#00478D` bg, 56 pt height, `border-radius: 12` | `ElevatedButton(child: Text('המשך'))` — no icon, default styling, no explicit color/size |
| S1-9 | Step-counter footer label "שלב 1 מתוך 4", Inter Medium 12 pt, `#727783`, centred | Absent |
| S1-10 | "חזרה" back / close icon in app bar, `close` icon (✕) in trailing | `AppBar` uses default back button (drawer icon) — no explicit close/back wiring |
| S1-11 | Field validation: product name + brand required; error copy below fields; continue disabled until valid | No validation logic; `_nextStep()` always advances |
| S1-12 | Duplicate-barcode detection: on match navigate to product detail with SnackBar | Not implemented |
| S1-13 | "אחר…" brand free-text expansion | Not implemented (no "אחר…" option in dropdown) |
| S1-14 | Camera unavailable degraded placeholder with `Icons.no_photography` | Not implemented (generic placeholder only, no camera-unavailable logic) |

**Priority / quick wins:** App-bar title (S1-1) and missing continue-button icon + styling (S1-8) are 5-minute fixes that immediately improve visual parity. Field label copy corrections (S1-5, S1-6, S1-7) are also fast. The camera integration (S1-3, S1-4) is the largest gap and should be tracked as its own implementation task.

## Resolved cross-screen note

Four inconsistencies were identified comparing this screen to its sibling `add-product-step-3-contains.md` and the shared component glossary. All are resolved by _design-decisions.md#dd-5 (canonical wizard chrome). Implement the canonical form; all Stitch-step-1 deviations are artifacts noted above as §7 deltas.

**A — Bottom nav presence (resolved per DD-5 + DD-4)**
Wizard screens have no bottom nav. The step-1 Stitch HTML rendering of a 4-tab nav (with non-canonical labels בית / סריקה / חיפוש / פרופיל) is a Stitch artifact. Do not implement.

**B — Progress indicator pattern (resolved per DD-5)**
Canonical wizard progress indicator = **linear progress bar** (filled track + step % label), all 4 steps. The horizontal node stepper on step 1 is a Stitch artifact. See `_components-glossary.md#wizard-chrome`.

**C — App bar title format (resolved per DD-5)**
Canonical app-bar title = **"הוספת מוצר חדש"** (fixed) + step subtitle "שלב N מתוך 4" below. The per-step embedding ("הוספת מוצר - שלב 1") is a Stitch artifact.

**D — Continue button icon (resolved per DD-5)**
Canonical continue icon = `chevron_left` (RTL forward). The `arrow_back` icon on step 1 is a Stitch artifact.
