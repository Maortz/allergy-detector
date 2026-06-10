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

### Utility cards row — dropped from MVP (see §7.3)

The Stitch design rendered two utility cards ("טיפים לעזרה ראשונה" and
"מסעדות בטוחות בסביבה") below the recent-activity section. These are dropped
from MVP per §7.3 — no backing routes or data sources. The Recent Activity
section is therefore the last block above the bottom nav.

### Bottom navigation bar
- 4 tabs (canonical per DD-2/DD-4). See [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav).
- Active tab: בית (Home) — tab 0. Pill indicator per DD-6.

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

1. **Named greeting — resolved.** Add a `displayName` field to `UserProfile` (persisted via SharedPreferences key `display_name`). Greeting renders `"שלום, ${profile.displayName}"`; fallback to `"שלום!"` if `displayName` is null/empty. Name capture: onboarding step 2 (notifications/permissions screen) collects it, and Settings → "ערוך פרופיל" can edit it.
2. **Time-of-day greeting — resolved.** Derived locally from `DateTime.now().hour`: 5–11 → "בוקר טוב", 12–16 → "צהריים טובים", 17–4 → "ערב טוב". No data dep; implement inline in `home_screen.dart`.
3. **Utility cards ("טיפים לעזרה ראשונה" / "מסעדות בטוחות") — dropped from MVP.** No corresponding routes or data sources exist; treated as design aspirations beyond MVP. Remove these cards from the implementation — the Recent Activity section becomes the last block above the bottom nav.
4. **Bottom nav tab set — resolved per DD-2 + DD-4.** Canonical 4-tab nav is בית / סריקה / קהילה / מועדפים. Visual confirms 4 tabs; the HTML extraction's "5 tabs" hint was an extraction artifact. The app's current "Settings" tab is a delta to realign to "מועדפים" — Settings reached via drawer (DD-11).
5. **Quick-scan band replaces the FAB — resolved.** Implement the band as specced in §2 ("Quick-scan CTA band") and remove the Home FAB. Tapping the band navigates to `SearchScanScreen` (same target as the FAB had).
6. **Profile avatar source — resolved.** MVP: local avatar only (image picker → SharedPreferences base64 under key `avatar_data`). If `avatar_data` is null, fall back to the **initials** of `displayName` (e.g., "ד" for "דניאל") on a `#EBF4FF` circle with `#00478D` text, Inter SemiBold 18 pt.

### Implementation deltas — verification pass 2026-05-24 <!-- DIVERGED -->

Spec-parity check of `app/lib/screens/home_screen.dart`.
**Result: diverged.** Verified = ⚠. No code change this pass (documented only).
App-bar + bottom-nav are provided by `MainContainer` (this widget is a tab body).

| # | Spec requirement | Current code |
|---|---|---|
| HD1 | Greeting "שלום, {displayName}" + time line; fallback "שלום!" (§7.1) | name **hardcoded `'משתמש'`**; no "שלום," prefix; reads time line only |
| HD2 | White hero greeting card (radius 12, shadow) wrapping greeting + profile-status + allergen summary | greeting is bare `Text` widgets, no card wrapper |
| HD3 | Profile-status row inside the white hero card | rendered in a **separate green card** (`safeBackground`) |
| HD4 | Allergen count label "ניטור פעיל של {N} אלרגנים" above the chip row | absent — jumps straight to chips / "לא נבחרו אלרגנים" |
| HD5 | Quick-scan band: bg `#EBF4FF`, `photo_camera` icon, `chevron_left` trailing | bg `primaryFixed` `#D6E3FF`, `qr_code_scanner` icon, `arrow_forward_ios` trailing |
| HD6 | Recent activity from `recentActivity` (AppShell); product-row 40 pt thumb + status-pill + timestamp | ✅ **FIXED 2026-06-09** — `MainContainer` passes `recentActivity: const []`; empty state "טרם סרקת מוצרים" shown per spec §5. Real data pending ScanHistory wiring (ROADMAP #5) |
| HD7 | (none — utility cards dropped per §7.3; Recent Activity is the last block) | ✅ **FIXED 2026-06-09** — `_buildBentoGrid()` removed; Recent Activity is now the last block |
| HD8 | Allergen chips = glossary `allergen-chip` Variant A (display) | `AllergenChip(isSelected: true)` — verify it renders Variant A styling separately |

**Remaining:** HD1 (hardcoded "משתמש"), HD2/HD3/HD4 (white hero card structure), HD5 (quick-scan band colors), HD8 (chip variant). HD6/HD7 resolved 2026-06-09.
