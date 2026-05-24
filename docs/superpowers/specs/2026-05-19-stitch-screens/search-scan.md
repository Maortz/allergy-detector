# חיפוש וסריקה / Search & Scan
Stitch screen: projects/16588854804615693446/screens/b075f5753b7948a9bb115786f1b922ed
Maps to: app/lib/screens/search_scan_screen.dart

## 1. Purpose & context

The Search & Scan screen is the primary product-identification surface of the app. It serves two complementary entry points to a safety verdict:

1. **Barcode scan** — a full-screen-height camera viewfinder lets the user point at a barcode; detection is automatic (no shutter button). A blue corner-frame overlay and the instruction text "יש ליישר את הברקוד בתוך המסגרת" guide alignment.
2. **Text search** — a search bar at the top of the screen allows typing a product name or brand; this overlays the `ActiveSearchScreen` (not designed in this Stitch screen — covered by a separate spec).

Below the viewfinder the screen surfaces two utility areas:
- **"נסרק לאחרונה"** (Recently Scanned) — a single-row entry linking to the last scanned product.
- **Two info/tip cards** — "טיפ בטיחות" (Safety Tip) and "סריקה מהירה" (Quick Scan), giving contextual guidance.

This screen is tab 1 in `MainContainer`'s `IndexedStack`. It is also reachable via the FAB on the Home Dashboard. The bottom-nav "סריקה" tab is the active tab while this screen is in focus.

---

## 2. Visual layout breakdown

Canvas: 780 × 1768 px @2× (390 pt wide logical). Background: `#F8F9FA` (off-white, token TBD — near `AppColors.surface`).

### App bar (top)
- Height: ~56 pt. White background, `elevation: 0`.
- **Right side (RTL leading):** App logo text "בטוח לאכול" — Inter Medium ~16 pt, `#00478D` (AppColors.primary).
- **Left side (RTL trailing):** hamburger icon (`menu`, Material), `#374151`, 24 pt; circular avatar, ~36 pt diameter.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar).

### Search bar (below app bar)
- Full-width input field with ~16 pt horizontal margin and ~8 pt top margin.
- Height: ~44 pt, border-radius ~12 pt.
- Background: `#FFFFFF`, border: 1 pt solid `#E5E7EB` (token TBD — near `AppColors.outline`).
- Leading icon (RTL right side): `search`, ~20 pt, `#9CA3AF`.
- Placeholder text: "חפש מוצר או מותג..." — Inter Regular 14 pt, `#9CA3AF`.
- Tapping the field navigates to / overlays `ActiveSearchScreen`.

### Camera viewfinder (main body, below search bar)
- Width: full bleed (no horizontal margin), height: ~320 pt.
- Background: dark photo/camera feed — the screenshot shows a grocery-shelf image (dark-toned) acting as the live camera preview placeholder.
- **Scan-frame overlay:** blue rounded-corner bracket frame centred in the viewfinder. Corners are `#1A8CF8` (light blue, token TBD). The frame appears animated in the live app via `_laserController` (a horizontal laser line sweeping top→bottom, see operational note in CLAUDE.md).
- **Instruction label** — centred overlay pill inside the viewfinder, near the bottom of the frame:
  - Background: semi-transparent dark `rgba(0,0,0,0.55)` (token TBD).
  - Text: "יש ליישר את הברקוד בתוך המסגרת" — Inter Regular ~13 pt, `#FFFFFF`.
  - Padding: ~`EdgeInsets.symmetric(horizontal: 12, vertical: 6)`, border-radius ~20 pt.
- **Viewfinder action buttons** — two circular icon buttons, centred horizontally, positioned below the instruction label, still inside the viewfinder area:
  - Left button: `photo_library` icon, `#FFFFFF`, 24 pt — opens device photo gallery to scan from image.
  - Right button: `flash_on` icon, `#FFFFFF`, 24 pt — toggles camera torch/flash.
  - Button background: semi-transparent circle `rgba(255,255,255,0.20)`, diameter ~40 pt.
  - Gap between buttons: ~16 pt.

### "נסרק לאחרונה" row (recently scanned, below viewfinder)
- Full-width row, background `#FFFFFF`, ~12 pt vertical padding, ~16 pt horizontal padding, 1 pt bottom divider `#E5E7EB`.
- **Right (RTL):** `history` icon, ~20 pt, `#00478D` (AppColors.primary).
- **Centre-right:** Two-line text block:
  - Line 1: "נסרק לאחרונה" — Inter SemiBold 13 pt, `#374151` (section label).
  - Line 2: "יוגורט יווני, 500 גרם" — Inter Regular 13 pt, `#6B7280` (last product name).
- **Left (RTL trailing):** `chevron_left` icon, ~18 pt, `#9CA3AF` (tappable — navigates to that product's detail screen).
- Entire row is tappable.

### Info / tip cards row (below recently-scanned row)
- Two equal-width cards side-by-side, ~8 pt gap, ~16 pt horizontal margin, ~12 pt top margin.
- Each card: `#FFFFFF` background, border-radius 12 pt, ~12 pt internal padding, subtle drop-shadow (0 2 8 `rgba(0,0,0,0.06)`), height ~96 pt.

**Card A — "טיפ בטיחות" (Safety Tip)**
- **Top-right icon:** `info`, ~20 pt, `#00478D` (AppColors.primary).
- **Heading:** "טיפ בטיחות" — Inter SemiBold 13 pt, `#1F2937`.
- **Body text:** "תמיד כדאי לבדוק את רשימת הרכיבים המלאה" — Inter Regular 12 pt, `#6B7280`. Text wraps to 2 lines within the card width.

**Card B — "סריקה מהירה" (Quick Scan)**
- **Top-right icon:** `barcode_reader` (or `qr_code_scanner`), ~20 pt, `#00478D` (AppColors.primary). Exact icon name TBD from HTML — visually resembles a stylised barcode/scanner glyph.
- **Heading:** "סריקה מהירה" — Inter SemiBold 13 pt, `#1F2937`.
- **Body text:** "החזק את הטלפון במרחק 15 ס״מ" — Inter Regular 12 pt, `#6B7280`.

### Bottom navigation bar
- "סריקה" tab (index 1) is the **active** tab on this screen.
- See [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav).
- Tabs visible (RTL right → left): "בית" | "סריקה" (active) | "קהילה" | "מועדפים".

### Scroll behaviour
- The viewfinder is fixed / non-scrolling in practice (it fills the interactive camera area).
- The "נסרק לאחרונה" row and info cards below it scroll within a `SingleChildScrollView` or equivalent if the device height is short. On typical devices (390 pt × 844 pt logical) all content fits without scrolling.
- No FAB is present on this screen (FAB lives on Home Dashboard only).

---

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | `AppColors.surface` / white bg | Inter Medium 16 pt | `menu`, `account_circle` | "בטוח לאכול" | see _components-glossary.md#app-bar |
| Search bar | `AppColors.outline` border (TBD) | Inter Regular 14 pt | `search` | "חפש מוצר או מותג..." (placeholder) | Tap → ActiveSearchScreen overlay |
| Scan-frame corners | `#1A8CF8` (token TBD) | — | — | — | Animated laser line via `_laserController` |
| Instruction label | `rgba(0,0,0,0.55)` bg (token TBD) | Inter Regular 13 pt | — | "יש ליישר את הברקוד בתוך המסגרת" | Semi-transparent pill overlay |
| Flash button | `rgba(255,255,255,0.20)` bg | — | `flash_on` | — | Toggles `ScannerService` torch |
| Gallery button | `rgba(255,255,255,0.20)` bg | — | `photo_library` | — | Opens image picker |
| Recently-scanned row — label | `#374151` (token TBD) | Inter SemiBold 13 pt | `history` (`#00478D`) | "נסרק לאחרונה" | Tappable row |
| Recently-scanned row — value | `#6B7280` (token TBD) | Inter Regular 13 pt | `chevron_left` | "יוגורט יווני, 500 גרם" | Example last product |
| Safety Tip card — heading | `#1F2937` (`AppColors.onSurface` TBD) | Inter SemiBold 13 pt | `info` (`#00478D`) | "טיפ בטיחות" | White card, radius 12 pt |
| Safety Tip card — body | `#6B7280` (token TBD) | Inter Regular 12 pt | — | "תמיד כדאי לבדוק את רשימת הרכיבים המלאה" | 2-line wrap |
| Quick Scan card — heading | `#1F2937` (`AppColors.onSurface` TBD) | Inter SemiBold 13 pt | `barcode_reader` / `qr_code_scanner` (`#00478D`) | "סריקה מהירה" | Icon name TBD |
| Quick Scan card — body | `#6B7280` (token TBD) | Inter Regular 12 pt | — | "החזק את הטלפון במרחק 15 ס״מ" | ס״מ = cm (geresh) |
| Bottom nav | see glossary | Inter 11 pt | `home`, `qr_code_scanner`, `groups`, `favorite` | "בית" / "סריקה" / "קהילה" / "מועדפים" | "סריקה" active |

---

## 4. Sub-components / element design

### 4.1 Camera viewfinder widget
The viewfinder is the dominant element of the screen, occupying approximately 320 pt of height. It is implemented via `ScannerService` (wrapping `mobile_scanner`) which provides a platform-aware widget. On web it renders a disabled/placeholder state; on Android/iOS it renders the live camera feed.

- The outer container is full-bleed (no horizontal padding, no border-radius on the left/right).
- The scan-frame is a four-corner bracket overlay drawn via `CustomPaint` or a stack of positioned containers. Corners: `#1A8CF8`, stroke width ~3 pt, corner length ~24 pt, border-radius on each corner ~4 pt.
- The laser animation: a 2 pt tall horizontal bar, gradient `#1A8CF8` → transparent → `#1A8CF8`, animates top→bottom within the frame using `_laserController` (repeating with `reverse: true`). **Do not `pumpAndSettle` in tests — this animation never completes.**
- The instruction pill sits inside the viewfinder, centred horizontally, ~16 pt above the bottom edge of the viewfinder area.
- The two icon buttons (`photo_library`, `flash_on`) are stacked below the instruction pill, still within the camera area. They appear on a single row, centred horizontally, separated by ~16 pt.

### 4.2 Search bar
A single-row `TextField` or `GestureDetector`-wrapped `Container`. The field itself may be read-only (acting as a tap target that navigates to `ActiveSearchScreen`) rather than a fully editable field at this view level — consistent with the pattern in `SearchScanScreen` where the active search is a separate overlay route.

### 4.3 Recently-scanned row
A `ListTile`-style row reading from `SearchCache` (last scanned product). If no product has been scanned yet, this row should be hidden or show a "אין מוצרים שנסרקו עדיין" empty-state label (not visible in this design — assume row is conditionally rendered).

- The `history` icon and product label are right-aligned in RTL.
- The `chevron_left` is left-aligned trailing in RTL — in a left-to-right physical position, pointing visually toward the navigation direction.

### 4.4 Info cards
Two side-by-side cards built with `Row` + two `Expanded` children (or fixed `(screenWidth - 48) / 2` width each). These are **static / non-tappable** info-only tiles as designed — no navigation action observed. If the app makes them tappable, that is a delta (see §7).

- Internal layout: `Column` with `CrossAxisAlignment.start`, icon top-right (in RTL — actually top-leading = top-right), heading, body text.
- No divider or bottom CTA within the cards.

---

## 5. States & interactions

| State | Trigger | Visual change |
|---|---|---|
| **Default / camera active** | Screen loads | Viewfinder shows live camera feed; laser animates; recently-scanned row visible if cache non-empty |
| **Camera permission denied** | OS denies camera access | `ScannerService` renders a permission-error widget (platform-defined); viewfinder placeholder shown |
| **Web / unsupported platform** | Running on web | `ScannerService` web-safe fallback — viewfinder shows static placeholder image (no live feed) |
| **Barcode detected** | `mobile_scanner` fires `BarcodeCapture` | App navigates to product-detail screen (or shows a result card); scanner is paused |
| **Flash toggled on** | Tap `flash_on` button | Icon changes to `flash_off`; `ScannerService.toggleTorch()` called |
| **Search bar tapped** | Tap anywhere on search field | `ActiveSearchScreen` overlay slides in from top (or pushes as a route); viewfinder pauses |
| **Recently-scanned row tapped** | Tap the row | Navigate to the product-detail screen for the last cached product |
| **No recent scan** | Cache empty on first launch | Recently-scanned row hidden (conditional render); info cards shift up |

---

## 6. Data & controller contract

### SearchScanScreen (stateful)

**AnimationController**
```dart
late AnimationController _laserController;
// initState:
_laserController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
)..repeat(reverse: true);
// dispose: _laserController.dispose();
```
This controller drives the laser sweep animation. Never call `pumpAndSettle` in tests for this screen.

**ScannerService** (`app/lib/services/`)
- Instantiated inline in the screen (not a singleton).
- Receives a `SupabaseClient` if product lookups are triggered from the scan result.
- Exposes: `startScanning()`, `stopScanning()`, `toggleTorch()`, `scanFromGallery()`.
- On barcode detected → calls `ProductService.searchProducts(barcode: code)` → navigates to product detail.

**SearchCache** (`app/lib/services/`)
- Provides `lastScannedProduct` (nullable `Product`) for the recently-scanned row.
- TTL 30 min, SharedPreferences-backed.

**Search bar**
- Does **not** own a `TextEditingController` at this level.
- Tap gesture → `Navigator.push` or overlay to `ActiveSearchScreen`, which owns its own `TextEditingController` and calls `ProductService.searchProducts(query: text)`.

**UserProfile** (from AppShell)
- Passed down for allergen comparison; used by any `ProductCard` rendered within this screen's scope.
- Not directly read in the viewfinder widget — only consumed when a scan result is displayed.

---

## 7. Open questions / design-vs-app deltas

### 7.1 App-bar variant — title vs. brand logo
The design shows the brand logo text "בטוח לאכול" (same as Home Dashboard), not a screen-specific "חיפוש וסריקה" title. The app's current implementation may render a different title. **Follow the Stitch design: use the brand-bar variant of app-bar (logo + menu + avatar).**

### 7.2 Bottom-nav tab 4 label — resolved per DD-2
Resolved per _design-decisions.md#dd-2. Canonical bottom-nav tab 4 = "מועדפים".
App must be realigned (replace current "הגדרות" tab with "מועדפים"; Settings
reached via drawer per DD-11).

### 7.3 Info-card tappability — resolved (tappable; destinations deferred)
Both info cards ("טיפ בטיחות" + "סריקה מהירה") are tappable. On tap they push a
`HelpTipsScreen` (new sub-screen, not specced in this batch — out of scope).
Until that screen exists, the cards `onTap` shows a "בקרוב" `SnackBar` toast.

### 7.4 Recently-scanned empty state — resolved
When `SearchCache.lastScannedProduct == null` the row is hidden entirely (no
empty-state label). Info cards shift up to fill the space.

### 7.5 Quick-scan card icon — resolved
Use `qr_code_scanner` (Material canon). The HTML extraction's `barcode_reader`
is an artifact.

### 7.6 Search bar — resolved (passive)
The search field on this screen is **passive** — a tap-target with no
`TextEditingController` at this level. Tap → `Navigator.push` overlay to
`ActiveSearchScreen` which owns the controller and live query state.

### 7.7 App-bar avatar — resolved
The brand-bar variant (logo + menu + avatar) is the canonical app-bar across
all four main tabs (Home, Scan, Community, Favorites). Avatar shows the user's
initials (per `home-dashboard §7.6`) or photo if uploaded.

### 7.8 Implementation deltas — verification pass 2026-05-24 <!-- DIVERGED -->

Spec-parity check of `app/lib/screens/search_scan_screen.dart`.
**Result: diverged.** Verified = ⚠. No code change this pass (documented only).
App-bar + bottom-nav are provided by `MainContainer` (this widget is a tab body),
so those are out of scope here.

| # | Spec requirement | Current code |
|---|---|---|
| SS1 | Scan-frame corners `#1A8CF8` (blue) | `Colors.red` corners |
| SS2 | Laser line blue `#1A8CF8` gradient | red bar + red glow |
| SS3 | Instruction pill "יש ליישר את הברקוד בתוך המסגרת" on `rgba(0,0,0,0.55)` | centered plain text "הצמד את הברקוד למצלמה", no pill |
| SS4 | Two in-viewfinder buttons: `photo_library` (gallery) + `flash_on` (torch) | both absent |
| SS5 | Full-bleed viewfinder ~320 pt, no heading above it | 1:1 rounded black box with a "סריקת ברקוד" heading above |
| SS6 | Recently-scanned: single row from `SearchCache.lastScannedProduct`, `history` icon, 2-line, `chevron_left`, hidden when empty (§7.4) | header **typo "נסרק לארכונה"** (should be "נסרק לאחרונה"), `archive_outlined` icon, **2 mock rows** (`_mockRecentScans`), no chevron, always shown |
| SS7 | Two info cards side-by-side: "טיפ בטיחות" + "סריקה מהירה", tappable → "בקרוב" toast (§7.3/§7.5) | only "טיפ בטיחות" (full-width, rotating tip); "סריקה מהירה" card missing; not tappable |
| SS8 | Search hint "חפש מוצר או מותג..."; passive tap-target → `ActiveSearchScreen` overlay (§7.6) | hint "חפש מוצר או מרכיב..."; verify the field navigates to the overlay |

**Quick wins:** SS6 header typo "לארכונה"→"לאחרונה" (user-facing Hebrew bug) and
SS1/SS2 red→blue are small, isolated fixes. SS4/SS7 are real feature gaps.
(Web build keeps a manual-barcode-entry fallback — acceptable, web-safe.)
