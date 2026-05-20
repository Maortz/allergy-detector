# חיפוש פעיל - תוצאות / Active Search
Stitch screen: projects/16588854804615693446/screens/45d081ae18b143ca8e15b12469468d9a
Maps to: app/lib/screens/search_screen.dart

---

## 1. Purpose & context

This screen is the **active search results overlay** — displayed when the user types a query in the search bar on the Search/Scan tab. It shows a filtered list of products matching the query, each annotated with the user's allergen-safety verdict derived from their profile. It is the primary product-discovery surface; the user never has to scan a barcode to reach it.

**Flow position:**
- Entry: user taps the search bar on `SearchScanScreen` and starts typing; the overlay slides in on top.
- Exit: user taps a product row → navigates to the relevant product-detail screen (e.g. `product-details-avoid`); or clears / backs out of the search input → overlay dismisses.
- The screen is rendered inside the app shell (app-bar + bottom-nav visible). It is not a modal route — it is an overlay on `SearchScanScreen`.

**Primary jobs:**
1. Present a ranked list of products matching the live query string.
2. Surface each product's allergen verdict (Safe / Caution / Avoid) immediately, without requiring the user to open each product.
3. Show the specific allergen reason when a product is Caution or Avoid, saving the user a tap.

---

## 2. Visual layout breakdown

Canvas: 390 × 844 pt logical (standard iPhone-class). RTL throughout.

### 2.1 App bar — top, h ≈ 56 pt
See `_components-glossary.md#app-bar` — "Search / title bar" variant.

Right side (RTL leading): circular avatar icon (`account_circle`, ~36 pt, `#374151`).
Center: screen title "חיפוש מוצרים" — Public Sans SemiBold 16 pt, `#1F2937`.
Left side (RTL trailing): hamburger menu icon (`menu`, 24 pt, `#374151`).

Background: `#FFFFFF`, `elevation: 0`.

### 2.2 Search input row — below app bar, h ≈ 48 pt, horizontal margin 16 pt
A single `TextField`-style search bar spanning the full width (minus 16 pt margins each side).

- Background: `#F9FAFB` (near-white surface) or `#FFFFFF` with border.
- Border: 1.5 pt solid `#D1D5DB` (light grey), `BorderRadius.circular(12)`.
- **Content (RTL):** text is entered right-to-left; active query "במבה" displayed in Inter Regular 14 pt, `#1F2937`.
- **Left (RTL trailing) side of field:** barcode/scan icon — appears as a square QR/barcode icon badge in a red-orange container (~28 × 28 pt, `#DC2626` or `#EF4444` background, white icon `qr_code`, `BorderRadius.circular(8)`). This is a tap target to switch to barcode-scan mode.
- **Right (RTL leading) side of field:** search affordance — a small circular `search` / `magnification` icon (`#9CA3AF`), 20 pt.
- Vertical padding within the field: 12 pt top + bottom (total field height ≈ 48 pt on the 4 px grid → 48 = 12 × 4).

### 2.3 Results subtitle — below search row, h ≈ 32 pt, horizontal margin 16 pt
Single-line text describing the active query and the filter in effect.

Exact Hebrew copy: **"מציג תוצאות עבור "במבה" בהתאם לפרופיל האלרגיות שלך"**
Font: Inter Regular 12 pt, `#6B7280` (muted/secondary).
Alignment: RTL (right-aligned).

Gap above this text from search row: 8 pt (2 × 4 px grid).

### 2.4 Product results list — scrollable, takes remaining height above bottom-nav
A `ListView` of product rows. No section headers in this view (contrast with `HomeScreen` recent-activity section). Rows are separated by a 1 pt divider `#F3F4F6` or an 8 pt gap.

Each row: h ≈ 80 pt. Horizontal margin 16 pt. Internal structure (RTL, right → left):

```
[Status icon 24 pt] [gap 12] [Text column flex] [Product thumbnail 56×56 pt]
```

**RTL leading (right):** 24 pt circular status icon — either `check_circle` (green, Safe) or `warning` / `error` (red, Avoid/Caution). The icon sits vertically centred.

**Center text column (flex, grows):**
- Line 1: Product name — Inter SemiBold 15 pt, `#1F2937`. Example: "במבה קלאסית".
- Line 2: Brand + weight — Inter Regular 13 pt, `#6B7280`. Example: "אסם • 80 גרם".
- Line 3: Status label pill — see §3 and §4 for variants. Sits 4 pt below line 2.

**RTL trailing (left):** Product thumbnail image, 56 × 56 pt, `BorderRadius.circular(8)`, `BoxFit.cover`. Shows actual product photo (rendered from Stitch placeholder — golden snack bag, round orange product, red packet).

Gap between rows: 0 pt divider (1 pt `#F3F4F6` line) or 8 pt whitespace — screenshot suggests whitespace separation with no visible hard lines.

### 2.5 Bottom navigation bar — fixed, bottom
Resolved per _design-decisions.md#dd-4: the canonical nav (בית / סריקה / קהילה / מועדפים, index 0–3) applies on this screen. See `_components-glossary.md#bottom-nav`.

Tab order observed in this screen's screenshot (RTL, right → left):
1. "חיפוש" — `search` icon, **active** (filled `#00478D`)
2. "סריקה" — `qr_code_scanner` icon, inactive
3. "מועדפים" — (heart / `favorite_border`) icon, inactive
4. "הגדרות" — `settings` / `search_gear` icon, inactive (leftmost)

This differs from the canonical 4-tab set (§7 delta — Stitch artifact).

---

## 3. Component inventory

| Element | Design-system token | Font | Icon | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App-bar title | `AppTypography.titleMedium` | Public Sans SemiBold 16 pt | — | "חיפוש מוצרים" | Center-aligned; see _components-glossary.md#app-bar |
| App-bar avatar | `AppColors.onSurfaceVariant` `#374151` | — | `account_circle` 36 pt | — | RTL leading (right side) |
| App-bar menu | `AppColors.onSurfaceVariant` `#374151` | — | `menu` 24 pt | — | RTL trailing (left side) |
| Search input field | Background `#F9FAFB`, border `#D1D5DB` | Inter Regular 14 pt `#1F2937` | `search` (leading) | "במבה" (live query) | `BorderRadius.circular(12)`, h 48 pt |
| Scan-mode badge (in search bar) | Background `#DC2626` (token TBD) | — | `qr_code` 16 pt white | — | 28×28 pt, radius 8, tap → barcode scan |
| Results subtitle | (token TBD) — `#6B7280` | Inter Regular 12 pt | — | "מציג תוצאות עבור "במבה" בהתאם לפרופיל האלרגיות שלך" | Secondary/muted text |
| Product row — name | `AppTypography.bodyMedium` (token TBD) | Inter SemiBold 15 pt `#1F2937` | — | e.g. "במבה קלאסית" | Line 1 of text column |
| Product row — brand/weight | `AppTypography.bodySmall` (token TBD) | Inter Regular 13 pt `#6B7280` | — | e.g. "אסם • 80 גרם" | Line 2 of text column |
| Status icon — Safe | `AppColors.safe` (token TBD) `#16A34A` | — | `check_circle` 24 pt | — | RTL leading in row; green filled circle-check |
| Status icon — Avoid | `AppColors.avoid` (token TBD) `#DC2626` | — | `warning` or `error` 24 pt | — | RTL leading in row; red warning shape |
| Status pill — Safe | Resolved per _design-decisions.md#dd-3: pill fixed label = "בטוח"; separate adjacent text = "בטוח לצריכה". Background `#DCFCE7`, text `#15803D` | Inter SemiBold 12 pt | `check_circle` 16 pt | status-pill (fixed label per DD-3) + separate context text: «בטוח לצריכה» | Context text is a distinct adjacent element, not part of the pill |
| Status pill — Avoid detail | Resolved per _design-decisions.md#dd-3: pill fixed label = "להימנע"; separate adjacent text = allergen name. Background `#FEE2E2`, text `#991B1B` | Inter SemiBold 12 pt | `warning` 16 pt | status-pill (fixed label per DD-3) + separate context text: «מכיל אגוזי לוז» | Context text is a distinct adjacent element, not part of the pill |
| Status pill — Caution detail | Resolved per _design-decisions.md#dd-3: pill fixed label = "זהירות"; separate adjacent text = allergen concern. Background `#FEF9C3`, text `#A16207` | Inter SemiBold 12 pt | `info` 16 pt | status-pill (fixed label per DD-3) + separate context text: «חשש לגלוטן» | Context text is a distinct adjacent element, not part of the pill |
| Product thumbnail | `BorderRadius.circular(8)` | — | — | — | 56×56 pt, `BoxFit.cover`; RTL trailing (left) |
| Bottom nav | see _components-glossary.md#bottom-nav | Inter 11 pt | varies | "סריקה" active (canonical) | Stitch renders non-canonical tabs — §7 delta per DD-4 |

---

## 4. Sub-components / element design

### 4.1 Search input bar (SearchActiveBar)
The search input on this screen is the **active/filled state** of the search bar. It is not a mere placeholder — a query is in progress.

- Container: `TextField` inside a `Container` with `BoxDecoration(color: #F9FAFB, borderRadius: BorderRadius.circular(12), border: Border.all(color: #D1D5DB, width: 1.5))`.
- Padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 12)` — aligns to 4 px grid.
- RTL text direction: `TextDirection.rtl`.
- Prefix (RTL right side): `Icon(Icons.search, color: #9CA3AF, size: 20)`.
- Suffix (RTL left side): a custom badge widget — `Container(width: 28, height: 28, decoration: BoxDecoration(color: #DC2626, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.qr_code, color: Colors.white, size: 16))`. Tapping this exits text-search and activates the barcode scanner.
- No separate clear/✕ button visible in the Stitch design (may be omitted in the spec; app may add one).

### 4.2 Results subtitle bar
A single `Text` widget in a `Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8))`. Dynamically constructed: `"מציג תוצאות עבור "${query}" בהתאם לפרופיל האלרגיות שלך"`. The query substring ("במבה") is embedded verbatim inside the sentence.

### 4.3 Product result row
A `ListTile`-equivalent custom row:

```
Row(
  children: [
    // RTL leading: status icon
    Icon(statusIcon, color: statusColor, size: 24),
    SizedBox(width: 12),
    // Center: text column
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,  // RTL right-align
        children: [
          Text(productName, style: InterSemiBold15),
          SizedBox(height: 2),
          Text('${brand} • ${weight}', style: InterRegular13),
          SizedBox(height: 4),
          StatusDetailPill(status: status, detailText: detailText),
        ],
      ),
    ),
    SizedBox(width: 12),
    // RTL trailing: product thumbnail
    ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
    ),
  ],
)
```

Row padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`. Total row height ≈ 80 pt.

### 4.4 Status detail pill (this screen's variant)
This screen renders a **status-detail pill** — a variant of status-pill that shows an allergen-specific reason string rather than the generic verdict label. See `_components-glossary.md#status-pill` for the base structure.

Structure is identical to status-pill (same `BoxDecoration`, same `Row` with icon + text, same padding), but:
- **Safe row:** label = "בטוח לצריכה" (not "בטוח" as in glossary).
- **Avoid row:** label = allergen name e.g. "מכיל אגוזי לוז" (not "להימנע").
- **Caution row:** label = allergen concern e.g. "חשש לגלוטן" (not "זהירות").

Whether this is a distinct `StatusDetailPill` widget or a parameterised `StatusPill(detailLabel: ...)` is an open question (see §7.1).

### 4.5 Status icon (row-leading indicator)
A large 24 pt icon to the RTL-right of each row, giving an at-a-glance verdict before reading the pill:

| Verdict | Icon | Color |
|---|---|---|
| Safe | `check_circle` (filled) | `#16A34A` |
| Avoid | `warning` or `error` (filled) | `#DC2626` |
| Caution | `info` (filled) | `#CA8A04` |

This icon is separate from the smaller 16 pt icon inside the status pill.

---

## 5. States & interactions

### 5.1 Loading state
When the query is first submitted (or on each keystroke with debounce), results should show a loading indicator. Design does not explicitly render a loading state; suggested implementation:
- Replace product list with `ListView` of 4 shimmer-style placeholder rows (same 80 pt row height, grey shimmer blocks for text and thumbnail).
- Or: `CircularProgressIndicator(color: AppColors.primary)` centered below the subtitle.

### 5.2 Results populated (shown state)
The primary state depicted in the Stitch design. 4 product rows with mixed Safe/Avoid/Caution verdicts. Rows are tappable — tap anywhere on a row navigates to the product detail screen.

Tap feedback: `InkWell` ripple or `ListTile`-equivalent with `splashColor`.

### 5.3 Empty state (no results)
Not shown in Stitch design. Suggested:
- Icon: `search_off`, 48 pt, `#9CA3AF`.
- Heading: "לא נמצאו תוצאות" — Inter SemiBold 16 pt `#1F2937`.
- Body: "נסה מילת חיפוש אחרת או סרוק ברקוד" — Inter Regular 14 pt `#6B7280`.
- Centered vertically in the list area.

### 5.4 Error state
Not shown in Stitch design. Suggested:
- Icon: `wifi_off` or `error_outline`, 48 pt, `#9CA3AF`.
- Heading: "שגיאה בטעינת תוצאות" — Inter SemiBold 16 pt `#1F2937`.
- Body: "בדוק חיבור אינטרנט ונסה שנית" — Inter Regular 14 pt `#6B7280`.
- Retry button: see `_components-glossary.md#primary-button`.

### 5.5 Search input interactions
- **Typing:** each keystroke (with ~300 ms debounce) triggers a new search; subtitle updates with live query string.
- **Clear input:** clears results list; if implemented as a clear ✕ icon in the field, it should appear only when text is present.
- **Tap scan badge (QR icon):** switches to barcode-scan mode (opens camera via `ScannerService`); search overlay closes.
- **Back / dismiss:** tapping outside or pressing back dismisses the overlay and returns to `SearchScanScreen`.

### 5.6 Scroll behaviour
The result list scrolls freely under the fixed search-bar + subtitle row (which remain pinned). App bar and bottom nav remain pinned. If results exceed viewport, user scrolls the `ListView`.

---

## 6. Data & controller contract

### 6.1 Input
- `query: String` — the live search string from the text field controller.
- `userProfile: UserProfile` — the user's selected allergen IDs (from SharedPreferences via `AppShell`).

### 6.2 Output / actions
- `onProductTap: ValueChanged<Product>` — navigates to the product detail screen for the tapped product.
- `onScanModeTap: VoidCallback` — switches to barcode-scan mode.
- `onQueryChanged: ValueChanged<String>` — feeds updated query string back to parent if the search bar is owned by the parent (`SearchScanScreen`).

### 6.3 Service calls
`ProductService.searchProducts(query)` — queries Supabase `products` joined with `brands`, then fetches `product_allergens` for returned product IDs. Cached in `SearchCache` (30-min TTL, SharedPreferences-backed).

The screen (or its parent `ActiveSearchScreen` widget) owns:
- `TextEditingController` for the search field.
- Debounce timer (suggested: `Timer(Duration(milliseconds: 300), ...)` ).
- `List<Product> results` state.
- `SearchStatus status` enum: `idle | loading | loaded | error`.

### 6.4 Allergen verdict computation (per row)
For each product in `results`, the row widget computes:
- `containsMatch = product.containsAllergens.any((a) => userProfile.selectedAllergenIds.contains(a.id))`
- `mayContainMatch = product.mayContainAllergens.any((a) => userProfile.selectedAllergenIds.contains(a.id))`
- Verdict: `containsMatch` → **Avoid**; else `mayContainMatch` → **Caution**; else → **Safe**.
- `detailText`: first matched allergen name (Hebrew), e.g. "מכיל אגוזי לוז" or "חשש לגלוטן"; if Safe → "בטוח לצריכה".

### 6.5 Row data model (per result item)
```dart
class SearchResultRow {
  final Product product;
  final String brandName;       // brand.name
  final String weightLabel;     // e.g. "80 גרם"
  final AllergenStatus status;  // safe | caution | avoid
  final String detailText;      // Hebrew detail string for pill
  final String? imageUrl;       // nullable — fallback to placeholder
}
```

---

## 7. Open questions / design-vs-app deltas

### 7.1 StatusPill label model (resolved)
Resolved per _design-decisions.md#dd-3: `status-pill` ALWAYS shows the fixed
labels "בטוח" / "זהירות" / "להימנע". The longer strings observed here
("בטוח לצריכה", "מכיל אגוזי לוז", "חשש לגלוטן") are **separate adjacent text
elements**, not pill labels. The shared `StatusPill` interface is unchanged.

### 7.2 Bottom-nav tab set delta (resolved)
Resolved per _design-decisions.md#dd-2 + #dd-4: canonical bottom-nav is
בית / סריקה / קהילה / מועדפים (index 0–3). This screen's extracted tab set
(חיפוש / סריקה / מועדפים / הגדרות) is a stale Stitch artifact, recorded here
as a delta. The implementation follows the glossary `#bottom-nav` canon —
this screen is reached as an overlay over the Home/Scan tab (per §7.8), not
as its own nav tab.

### 7.3 "חיפוש" vs. "סריקה" tabs (resolved)
Resolved per _design-decisions.md#dd-4: there is no separate "חיפוש" nav tab.
Search is an overlay opened from the Home/Scan flow. The "חיפוש" tab appearing
in this screen's extracted HTML is part of the same DD-4 artifact set; the
canonical nav has only one scan/search entry at index 1 ("סריקה").

### 7.4 Scan-mode badge color token
The QR/barcode badge inside the search field appears in a red container (`#DC2626`). This reuses the Avoid color. A dedicated `AppColors.scanBadge` token (or a neutral `AppColors.primary` blue badge) may be more appropriate. Pending design decision.

### 7.5 Product thumbnail — real images vs. placeholder
The Stitch design renders realistic product photos (snack bag, orange product, red packet). The app must handle missing images gracefully. A fallback placeholder asset (e.g. a generic product silhouette or initials box) should be specified; not addressed in the Stitch design.

### 7.6 Row separator style
The Stitch design does not show explicit dividers between rows — rows are separated by whitespace. The app currently uses a `ListView` with implicit separators. Preferred: `ListView.separated` with `SizedBox(height: 8)` separators, or `Divider(color: #F3F4F6, thickness: 1)`. Design intent not fully clear.

### 7.7 Debounce vs. on-submit search
The app's `SearchCache` and `ProductService` suggest a debounced per-keystroke query. The Stitch design does not prescribe this. Confirm debounce duration (suggested 300 ms) with product owner.

### 7.8 App maps to `search_screen.dart` — verify overlay vs. route
The mapping says `app/lib/screens/search_screen.dart`. In the CLAUDE.md architecture, the overlay is `ActiveSearchScreen`. Confirm whether `search_screen.dart` is the same file, a rename, or a separate full-screen route.

---

## Resolved cross-screen note

### INC-1 · Status pill label text (resolved per DD-3)

Resolved per _design-decisions.md#dd-3. The `status-pill` always shows fixed short labels only: "בטוח" / "זהירות" / "להימנע". The contextual strings rendered by this screen ("בטוח לצריכה", "מכיל אגוזי לוז", "חשש לגלוטן") are **separate adjacent text elements**, not part of the pill itself. The component inventory table above has been updated accordingly. No new StatusDetailPill component type is needed — the pill is unchanged; only the adjacent copy is screen-specific.

### INC-2 · Bottom-nav tab set and active tab identity (resolved per DD-4)

Resolved per _design-decisions.md#dd-4. The canonical bottom nav is בית / סריקה / קהילה / מועדפים (index 0–3) per DD-2. The divergent tab set in this screen's Stitch HTML (חיפוש / סריקה / מועדפים / הגדרות) is a stale Stitch artifact. Implement the canonical tab set; do not re-spec the artifact. See `_components-glossary.md#bottom-nav`. This delta is noted in §7 for traceability.
