# דף הבית / Home Dashboard
Stitch screen: projects/16588854804615693446/screens/4cbae145a6a34837ab47bdec527b10df
Maps to: app/lib/screens/home_screen.dart

## 1. Purpose & context

The Home Dashboard is the landing screen for returning users (i.e., `has_completed_onboarding == true`). It provides a personalised safety summary — who is logged in, how many allergens are being tracked, and a chip-row of the active allergens — then surfaces the quick-scan CTA and a timestamped feed of recently-scanned products. Secondary utility cards (first-aid tips, nearby restaurants) sit below the feed. This screen is the root of tab 0 in `MainContainer`'s `IndexedStack`.

## 2. Visual layout breakdown

Canvas: 780 × 2192 px @2× (390 pt wide logical). Background: `#F8F9FA` (off-white surface, token TBD — near `AppColors.surface`).

### App bar (top)
- Height: ~56 pt. White background, no elevation shadow visible.
- **Right side (RTL leading):** App logo text "בטוח לאכול" — Inter Medium ~16 pt, `#00478D` (AppColors.primary).
- **Left side (RTL trailing):** hamburger / menu icon (`menu`, Material), `#374151`; avatar circle ~36 pt diameter, light blue-grey fill, initials or photo (shows a person silhouette in the screenshot).
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar).

### Hero greeting card (below app bar)
- White card, full-width, ~16 pt horizontal padding, ~16 pt vertical padding, border-radius 12 pt, subtle drop-shadow (0 2 8 rgba(0,0,0,0.06)).
- **Right-aligned text block:**
  - "שלום, דניאל" — Public Sans Bold ~20 pt, `#1F2937`.
  - "בוקר טוב!" — Public Sans Regular ~14 pt, `#6B7280`.
- **Profile status row** (below greeting, RTL): `verified_user` shield icon (`#00478D`) + "הפרופיל שלך פעיל" — Inter Regular 13 pt, `#374151`.
- **Allergen monitoring summary** (below status row):
  - Label: "ניטור פעיל של 5 אלרגנים" — Inter SemiBold 14 pt, `#1F2937`.
  - Allergen chip row (horizontal scroll, RTL): five chips — בוטנים, חלב, ביצים, אגוזים, שומשום.
  - See [_components-glossary.md#allergen-chip](_components-glossary.md#allergen-chip).

### Quick-scan CTA band
- Horizontal band below the hero card, ~12 pt top margin.
- Background: `#EBF4FF` (light Medical-Blue tint, token TBD).
- Height: ~64 pt, border-radius 12 pt, horizontal padding 16 pt.
- **Right (RTL):** `photo_camera` icon `#00478D`, 24 pt.
- **Center:** "סריקה מהירה" — Inter SemiBold 14 pt, `#00478D`.
- **Left (RTL trailing):** `chevron_left` icon `#00478D`, 20 pt (RTL flip → points right toward action).
- Tappable; entire band is the touch target; no visible border.
- Sub-label below main label: "בדוק מוצר חדש עכשיו" — Inter Regular 12 pt, `#6B7280`.

### "פעילות אחרונה" (Recent Activity) section
- Section header: "פעילות אחרונה" — Public Sans SemiBold 16 pt, `#1F2937`. Right-aligned. ~16 pt top margin, ~16 pt horizontal margin.
- Scrollable vertical list of **ProductCards** (not horizontally scrolled), each with ~8 pt vertical gap.
- Three example entries visible:
  1. יוגורט יווני טבעי — status **בטוח** (Safe, green)
  2. חטיף אנרגיה אגוזים — status **להימנע** (Avoid, red)
  3. דגני בוקר קוואקר — status **זהירות** (Caution, orange)
- Each card: white background, border-radius 12 pt, horizontal padding 12 pt, vertical padding 12 pt, subtle shadow.
  - **RTL layout within card:** status pill on the right → product thumbnail (40×40 pt, border-radius 8 pt) on the left, product name + timestamp centre-left.
  - Product name: Inter SemiBold 14 pt, `#1F2937`.
  - Timestamp: Inter Regular 12 pt, `#9CA3AF` — e.g. "לפני שעה", "אתמול", "לפני יומיים".
  - Status pill: see [_components-glossary.md#status-pill](_components-glossary.md#status-pill).

### Utility cards row (below activity)
- Two equal-width cards side-by-side, ~8 pt gap, ~16 pt horizontal margin, ~16 pt top margin.
- **Card A — "טיפים לעזרה ראשונה":** icon `restaurant_menu` (or similar), Medical-Blue icon, white card, border-radius 12 pt.
- **Card B — "מסעדות בטוחות בסביבה":** icon (map-pin variant), white card, border-radius 12 pt.
- Each card: ~80 pt height, icon top-right, label Inter SemiBold 13 pt `#1F2937`, no explicit CTA button — whole card is tappable.

### Bottom navigation bar
- 5 tabs. See [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav).
- Active tab: בית (Home) — tab 0.

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary | — | `menu`, avatar | "בטוח לאכול" | see _components-glossary.md#app-bar |
| Greeting name | `AppColors.onSurface` `#1F2937` | Public Sans Bold 20 pt | — | "שלום, דניאל" | Personalised from `UserProfile.name` |
| Time greeting | `AppColors.onSurfaceVariant` `#6B7280` | Public Sans Regular 14 pt | — | "בוקר טוב!" | Time-of-day conditional |
| Profile status | `AppColors.primary` `#00478D` | Inter Regular 13 pt | `verified_user` | "הפרופיל שלך פעיל" | — |
| Allergen count label | `#1F2937` | Inter SemiBold 14 pt | — | "ניטור פעיל של 5 אלרגנים" | Count from `userProfile.selectedAllergenIds.length` |
| Allergen chips | see glossary | — | — | בוטנים, חלב, ביצים, אגוזים, שומשום | see _components-glossary.md#allergen-chip |
| Quick-scan band | `#EBF4FF` bg | Inter SemiBold 14 pt | `photo_camera`, `chevron_left` | "סריקה מהירה" / "בדוק מוצר חדש עכשיו" | Navigates to SearchScanScreen |
| Section header | `#1F2937` | Public Sans SemiBold 16 pt | — | "פעילות אחרונה" | — |
| Product card — name | `#1F2937` | Inter SemiBold 14 pt | — | e.g. "יוגורט יווני טבעי" | — |
| Product card — timestamp | `#9CA3AF` | Inter Regular 12 pt | — | "לפני שעה" / "אתמול" / "לפני יומיים" | — |
| Status pill | see glossary | — | `check_circle` / `warning` / `info` | "בטוח" / "להימנע" / "זהירות" | see _components-glossary.md#status-pill |
| Utility card A | `#FFFFFF` bg | Inter SemiBold 13 pt | `restaurant_menu` (TBD) | "טיפים לעזרה ראשונה" | — |
| Utility card B | `#FFFFFF` bg | Inter SemiBold 13 pt | map-pin (TBD) | "מסעדות בטוחות בסביבה" | — |
| Bottom nav | see glossary | — | home, scanner, groups, favorite | בית / סריקה / קהילה / מועדפים | see _components-glossary.md#bottom-nav |

## 4. Sub-components / element design

### Hero greeting card
- Container: `BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0,2))])`.
- Padding: `EdgeInsets.all(16)` — 4px grid × 4.
- Profile status row uses a `Row` with `MainAxisAlignment.end` (RTL) and 6 pt gap between icon and text.
- Allergen chip row: horizontal `Wrap` or `SingleChildScrollView(scrollDirection: Axis.horizontal)`, chips spaced 8 pt apart (AppSpacing.sm × 2), right-to-left order matching allergen selection order.

### Quick-scan CTA band
- `InkWell`-wrapped `Container`, `BorderRadius.circular(12)`, background `#EBF4FF`.
- Internal layout: `Row` with `MainAxisAlignment.spaceBetween`, icon on right, text column in center, chevron on left.
- Entire band margin: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`.

### Product activity card
- `Card(elevation: 0)` with custom `BoxDecoration` shadow.
- Internal `Row`: status pill widget (right/leading in RTL) → `Expanded` text column → thumbnail `ClipRRect` (left/trailing in RTL).
- Name truncates at 1 line (`overflow: TextOverflow.ellipsis`).
- Thumbnail: 40×40 pt, `border-radius: 8 pt`, `BoxFit.cover`. Placeholder: grey `#E5E7EB`.

## 5. States & interactions

| State | Trigger | Visual change |
|---|---|---|
| Default (loaded) | Profile exists, activity fetched | Full layout as described |
| Loading | App startup, data fetch in progress | Shimmer skeletons replace hero card and activity list |
| Empty activity | No scans yet | "פעילות אחרונה" section shows empty-state illustration + "טרם סרקת מוצרים" label |
| Tap quick-scan band | User taps the band | Navigates to `SearchScanScreen` (tab 1 or pushed route) |
| Tap product card | User taps any activity card | Navigates to `ProductDetails` for that product |
| Tap utility card A | User taps "טיפים לעזרה ראשונה" | Opens in-app first-aid tips sheet or external link (behaviour unconfirmed) |
| Tap utility card B | User taps "מסעדות בטוחות" | Opens map or restaurant list (behaviour unconfirmed) |
| Bottom nav tap | User taps non-home tab | `MainContainer` switches `IndexedStack` index |

## 6. Data & controller contract

**Inputs from `AppShell`:**
- `UserProfile profile` — provides `name`, `selectedAllergenIds`.
- `List<Allergen> allergenCatalog` — maps IDs to display names (Hebrew).
- `List<ScannedProduct> recentActivity` — last N scanned products, ordered newest-first.

**Computed locally:**
- Active allergen count: `profile.selectedAllergenIds.length`.
- Allergen chip labels: resolved from `allergenCatalog` by ID.
- Product status per card: `ProductCard.status` (contains/mayContain intersection with `selectedAllergenIds`).
- Time-of-day greeting: derived from `DateTime.now()` — "בוקר טוב" / "צהריים טובים" / "ערב טוב".

**Callbacks:**
- `onScanTap` → navigates to SearchScanScreen.
- `onProductTap(Product)` → navigates to ProductDetails.

**Services called:** None directly — data arrives via constructor params from `AppShell`. `RecentActivity` may be read from `SearchCache` (SharedPreferences).

## 7. Open questions / design-vs-app deltas

1. **"דניאל" hard-coded?** The Stitch design shows "שלום, דניאל" as a named user, but the MVP has no authentication — profile name is not in `UserProfile` per the current SharedPreferences schema. Either the name field needs adding, or the greeting should be generic ("שלום!").
2. **Time-of-day greeting** ("בוקר טוב!") — not present in `home_screen.dart` as of last review. Needs implementation.
3. **Utility cards** ("טיפים לעזרה ראשונה", "מסעדות בטוחות בסביבה") — no corresponding routes or data sources exist in the app. These are design aspirations only.
4. **Bottom nav has 4 tabs in app, 5 visible in this design?** The HTML extraction mentions 5 nav icons including "מועדפים" (Favorites); the app `MainContainer` has 4 tabs (Home, Scan, Community, Settings). Confirm whether "מועדפים" replaces "Settings" or is an additional tab.
5. **Quick-scan band label** — Stitch shows "סריקה מהירה" as a section label but the app uses an FAB on Home to reach Search/Scan. The band may replace the FAB in the target design.
6. **Profile avatar** — avatar source (initials vs photo) not specified; needs decision before implementation.
