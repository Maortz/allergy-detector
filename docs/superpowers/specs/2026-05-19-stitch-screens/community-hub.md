# Community Hub / מרכז הקהילה
Stitch screen: projects/16588854804615693446/screens/a8c9931205604870a6ecee4456c6e808
Maps to: app/lib/screens/community_screen.dart

## 1. Purpose & context

The Community Hub is the social contribution layer of the app. It surfaces the signed-in user's impact on the shared allergen database, motivates peer-review actions, and broadcasts community insights. It is reached via bottom-nav tab 3 ("קהילה", index 2 in the canonical `בית / סריקה / קהילה / מועדפים` set).

The screen has **no product safety verdict** — it is purely motivational and editorial. It does not require authentication in the MVP (stats are local/cached); however its content (verified count, added count, pending reviews) is dynamic and must be fetched from Supabase on mount.

Primary user jobs-to-be-done:
1. See personal contribution stats at a glance (verified products, added products).
2. Discover there are products awaiting peer review and jump into the review flow.
3. Add a brand-new product to the database.
4. Read a community insight card (weekly tip or active discussion link).

---

## 2. Visual layout breakdown

Viewport: 780 × 2390 px (mobile, RTL, Hebrew). Top-to-bottom column, no horizontal scroll.

```
┌─────────────────────────────────┐  h ≈ 64 pt  (sticky)
│  AppBar: "קהילת בטיחות מזון"    │
├─────────────────────────────────┤
│  Intro block                    │  ~72 pt
│  h1 "הכוח שלנו הוא בידע"        │
│  body "עזרו לאחרים..."          │
├────────────────┬────────────────┤
│  Stats card L  │  Stats card R  │  ~120 pt  (2-col grid, gap 16 pt)
│  "5 / אומתו   │  "2 / מוצרים   │
│  בהצלחה"      │  נוספו"        │
├─────────────────────────────────┤
│  Bento-Large: "עזרו לקהילה"     │  min 220 pt
│  (image + gradient overlay)     │
│  CTA button "הוספת מוצר חדש"    │
├─────────────────────────────────┤
│  Bento-Medium: "בקרת עמיתים"    │  ~200 pt
│  icon / h3 / body / CTA button  │
├─────────────────────────────────┤
│  Insight card 1: "טיפ השבוע"    │  ~88 pt
├─────────────────────────────────┤
│  Insight card 2: "דיון פעיל"    │  ~88 pt
├─────────────────────────────────┤  h ≈ 56 pt + safe area  (fixed)
│  BottomNav — "קהילה" active      │
└─────────────────────────────────┘
```

Horizontal margins: 20 pt (`px-margin`). Vertical padding inside `<main>`: top 32 pt, bottom 128 pt (to clear fixed nav bar). Gap between sections: 16 pt.

---

## 3. Component inventory

| # | Component | Source | Notes |
|---|---|---|---|
| 1 | AppBar — community variant | see `_components-glossary.md#app-bar` | Title "קהילת בטיחות מזון", `menu` icon right-trailing; no avatar in this screen |
| 2 | Intro block | screen-specific | h1 + body paragraph, right-aligned |
| 3 | Impact stats row | screen-specific | 2-col grid of `StatCard` widgets |
| 4 | Bento-Large hero card ("עזרו לקהילה") | screen-specific | Image + gradient overlay + CTA |
| 5 | Bento-Medium peer-review card ("בקרת עמיתים") | screen-specific | Icon tile + CTA button |
| 6 | Insight card — weekly tip | screen-specific | Tinted row with icon + text |
| 7 | Insight card — active discussion | screen-specific | Neutral row with icon + text |
| 8 | BottomNav — "קהילה" active | see `_components-glossary.md#bottom-nav` | Tab index 2, `groups` filled icon |

---

## 4. Sub-components / element design

### 4.1 AppBar — community variant

see `_components-glossary.md#app-bar`

Specific values for this screen:
- **RTL leading (right):** text "קהילת בטיחות מזון" — Public Sans SemiBold 20 pt (h3 scale), `AppColors.primary` `#00478D`. Centred horizontally between spacer and menu button.
- **RTL trailing (left):** `menu` icon 24 pt, `AppColors.primary` `#00478D` (note: the Stitch HTML colours the menu icon `text-primary` here, unlike the `#374151` standard; this may be a Stitch artifact — see §7.1).
- No avatar visible.
- Background `#FFFFFF`, bottom border 1 pt `#F1F5F9` (`slate-100`), `BoxShadow` `elevation: 1` (subtle).
- Sticky / `pinned` (does not scroll away).

### 4.2 Intro block

Right-aligned text block, 8 pt bottom margin.

- **Heading:** "הכוח שלנו הוא בידע" — Public Sans Bold 30 pt (h1), `#191C1D` (`AppColors.onSurface`).
- **Subtext:** "עזרו לאחרים לגלוש בביטחה ולגלות מוצרים חדשים." — Inter Regular 16 pt (body-md), `#424752` (`AppColors.onSurfaceVariant`).

### 4.3 StatCard (shared sub-component, used twice)

A white rounded card showing a single numeric contribution metric.

Structure:
- `Container` — background `#FFFFFF`, `BorderRadius.circular(16)` (rounded-2xl), `BoxShadow` sm (elevation ~2 pt), border 1 pt `#F1F5F9`.
- Padding: 16 pt all sides.
- Internal `Column(mainAxisAlignment: center, crossAxisAlignment: center, textAlign: center)`:
  1. **Number label** — Public Sans Bold 30 pt (h1 scale).
  2. **Description label** — Inter Medium 12 pt (label-sm), `#424752` (`AppColors.onSurfaceVariant`).
  3. **Icon** — Material Symbol filled, 24 pt, 8 pt top margin.

Layout: `GridView` / `Row` with 2 columns, gap 16 pt, equal widths.

Variants used on this screen:

| Field | Verified card | Added card |
|---|---|---|
| Number | 5 | 2 |
| Number color | `#006B5B` (secondary, green) | `#00478D` (primary, Medical Blue) |
| Description | "אומתו בהצלחה" | "מוצרים נוספו" |
| Icon | `verified` (filled) | `add_circle` (filled) |
| Icon color | `#006B5B` (secondary) | `#00478D` (primary) |

> The "5" / "2" values are dynamic — see §6 for the data contract.

### 4.4 Bento-Large hero card — "עזרו לקהילה"

A full-width hero promotional card that motivates users to add new products.

Structure:
- Outer `Container` — background `AppColors.primary` `#00478D`, `BorderRadius.circular(24)` (rounded-3xl), padding 24 pt, `BoxShadow` md, `min-height` 220 pt, `clipBehavior: Clip.hardEdge`.
- **Background layer (Stack, positioned):**
  - `Image.network` — stock photo of fresh food ingredients, `BoxFit.cover`, `opacity: 0.30`.
  - Gradient overlay: `LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, primary.withOpacity(0.60), primary])`.
- **Foreground layer (Column, mainAxisAlignment: end, crossAxisAlignment: start):**
  1. **Heading:** "עזרו לקהילה" — Public Sans SemiBold 24 pt (h2), `#FFFFFF`.
  2. **Body:** "מצאתם מוצר חדש? הוסיפו אותו כדי שכולם יוכלו לדעת אם הוא בטוח." — Inter Regular 16 pt, `#FFFFFF`, opacity 0.90, `maxWidth` ~85 % of card width, 24 pt bottom margin.
  3. **CTA button:** "הוספת מוצר חדש" with `add` icon (Material Symbol, 24 pt).

CTA button spec:
- `ElevatedButton` or `TextButton` with custom decoration.
- Background `#FFFFFF`, text `AppColors.primary` `#00478D`.
- Font: Inter SemiBold 14 pt (label-bold).
- Padding: `EdgeInsets.symmetric(horizontal: 24, vertical: 12)`.
- Border-radius: 12 pt (rounded-xl).
- Icon: `add` 24 pt `#00478D`, positioned RTL-leading (left in RTL = appears to the right of text visually in a Row).
- `BoxShadow` sm.
- Active: `scale: 0.95` press animation.
- Tap: navigates to Add-Product wizard (step 1).

### 4.5 Bento-Medium peer-review card — "בקרת עמיתים"

A white card with centered content that exposes the pending peer-review queue.

Structure:
- `Container` — background `#FFFFFF`, `BorderRadius.circular(24)` (rounded-3xl), padding 24 pt, `BoxShadow` sm, border 1 pt `#F1F5F9`.
- Internal `Column(mainAxisAlignment: center, crossAxisAlignment: center, spacing: 16)`:
  1. **Icon tile:** `Container` 64×64 pt, `BorderRadius.circular(16)` (rounded-2xl), background `#D6E3FF` at 30 % opacity (`primary-container/30`). Child: `rate_review` Material Symbol filled, 32 pt, `AppColors.primary` `#00478D`.
  2. **Text block (Column):**
     - Title: "בקרת עמיתים" — Public Sans SemiBold 20 pt (h3), `#191C1D`.
     - Body: "ישנם " + **"12 מוצרים"** + " הממתינים לבדיקה שלך" — Inter Regular 16 pt, `#424752`. The bold count ("12 מוצרים") is `#00478D` Inter Bold 16 pt (inline `RichText`/`TextSpan`).
  3. **Primary CTA button:** "התחל בבדיקה" — full-width, height ~52 pt (py-4), `AppColors.primary` fill, white text Inter SemiBold 14 pt, `BorderRadius.circular(12)`, `BoxShadow` md. Active: `scale: 0.95`. Tap: navigates to peer-review queue screen.

> "12" is dynamic — see §6.

### 4.6 Insight cards

Two stacked cards, each a horizontal `Row` with a leading icon and trailing text block. Right-aligned text in RTL means the text `Column` is on the right and the icon is on the left (trailing in LTR reading order, leading in RTL layout).

**Card 1 — "טיפ השבוע" (Weekly tip)**
- Background: `#006B5B` at 5 % opacity (secondary/5), border 1 pt `#006B5B` at 10 %.
- Icon: `lightbulb` Material Symbol outlined, 24 pt, `#006B5B` (secondary color).
- Title: "טיפ השבוע" — Inter SemiBold 14 pt (label-bold), `#006B5B`.
- Body: "איך לקרוא תוויות של יצרנים בינלאומיים בצורה בטוחה ומדויקת." — Inter Regular 14 pt (`text-sm`), `#424752`, leading relaxed.
- `BorderRadius.circular(16)`, padding 24 pt, gap between icon and text 16 pt.
- Not explicitly tappable in Stitch; implementor may add navigation if a tips screen exists (see §7.2).

**Card 2 — "דיון פעיל" (Active discussion)**
- Background: `#F1F5F9` at 50 % (`slate-100/50`), border 1 pt `#E2E8F0` at 50 %.
- Icon: `groups` Material Symbol outlined, 24 pt, `#475569` (`slate-600`).
- Title: "דיון פעיל" — Inter SemiBold 14 pt (label-bold), `#191C1D` (onSurface).
- Body: "תחליפי חלב חדשים בשוק - האם הם בטוחים לאלרגיים לחלבון חלב?" — Inter Regular 14 pt, `#424752`, leading relaxed.
- `BorderRadius.circular(16)`, padding 24 pt, gap 16 pt.
- Not explicitly tappable in Stitch (see §7.2).

### 4.7 BottomNav — "קהילה" active

see `_components-glossary.md#bottom-nav`

Active tab: "קהילה" (index 2). Active indicator in this screen uses a **pill background** on the icon+label pair: `Container` with background `#D6E3FF` at 40 % (primary-container/40), `BorderRadius.circular(12)` (rounded-xl), `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6)`. Icon: `groups` filled, `#00478D`. Label: "קהילה" Inter SemiBold Bold 11 pt, `#00478D`. This pill indicator is now the **canonical** active-tab style per _design-decisions.md#dd-6; `_components-glossary.md#bottom-nav` has been updated to reflect this.

---

## 5. States & interactions

### 5.1 Default / loaded state
All sections render with real data (stats, pending count, tip text). This is the normal state shown in the Stitch design.

### 5.2 Loading state
On initial mount while awaiting Supabase data:
- `StatCard` numbers show `--` or a `CircularProgressIndicator` (size 20 pt) in place of the digit.
- Peer-review body shows "..." or skeleton text in place of the count.
- Hero card and insight cards are static (no dynamic content — they render immediately).

### 5.3 Error / offline state
If Supabase fetch fails:
- `StatCard` numbers remain at last cached values (or `--` if no cache).
- Peer-review count shows last cached value or `?`.
- A non-blocking `SnackBar` may appear: "לא ניתן לטעון נתונים — בדוק חיבור לאינטרנט."

### 5.4 Zero-contribution state
When user has never contributed (stats = 0):
- `StatCard` shows "0" with same styling.
- No special empty-state treatment observed in Stitch.

### 5.5 Button interactions

| Button | Default tap | Active (pressed) |
|---|---|---|
| "הוספת מוצר חדש" | Navigate → Add-Product wizard step 1 | Scale 0.95 |
| "התחל בבדיקה" | Navigate → Peer-review queue | Scale 0.95 |
| Insight card rows | (undefined in Stitch — §7.2) | — |
| `menu` icon | Open navigation drawer | Ripple |

### 5.6 Scroll behaviour
The AppBar is sticky (`position: sticky` / `SliverAppBar(pinned: true)`). The rest of the content scrolls. The BottomNav is fixed.

---

## 6. Data & controller contract

### 6.1 Data model

```dart
class CommunityStats {
  final int verifiedCount;   // products the user verified (peer-reviewed ✓)
  final int addedCount;      // products the user added to the database
  final int pendingReviews;  // products awaiting peer review by anyone
}

class InsightCard {
  final InsightType type;    // weeklyTip | activeDiscussion
  final String title;        // e.g. "טיפ השבוע"
  final String body;
  final String? targetUrl;   // deep-link or null
}
```

### 6.2 Supabase queries (suggested)

```sql
-- User's verified count (products they approved in peer-review)
SELECT COUNT(*) FROM product_reviews
WHERE user_id = :userId AND action = 'approved';

-- User's added count
SELECT COUNT(*) FROM products WHERE added_by = :userId;

-- Pending peer-review queue (global)
SELECT COUNT(*) FROM products WHERE status = 'pending_review';
```

Insight cards may come from a `community_insights` table or be hardcoded in the MVP. If hardcoded, the weekly-tip body is: "איך לקרוא תוויות של יצרנים בינלאומיים בצורה בטוחה ומדויקת." and the discussion body is: "תחליפי חלב חדשים בשוק - האם הם בטוחים לאלרגיים לחלבון חלב?"

### 6.3 Controller responsibilities

```dart
class CommunityController {
  Future<CommunityStats> loadStats();    // fetch on mount
  Future<void> navigateToAddProduct();   // → wizard step 1
  Future<void> navigateToPeerReview();  // → review queue
}
```

`CommunityScreen` is a `StatefulWidget`. The controller is instantiated with a `SupabaseClient` injected inline in the screen (see CLAUDE.md architecture note: services are not singletons). Stats are cached in SharedPreferences with a short TTL (e.g. 5 min) to avoid re-fetching on every tab switch.

### 6.4 Hero card image
The background image in the Bento-Large card is a stock photo (fresh ingredients). In the app, use a local asset (`assets/images/community_hero.jpg`) rather than a remote URL, to avoid a network waterfall on tab switch.

---

## 7. Open questions / design-vs-app deltas

### 7.1 AppBar menu icon color
The Stitch HTML renders the `menu` icon as `text-primary` (`#00478D`) rather than the standard `#374151` (`AppColors.onSurfaceVariant`) defined in the glossary. This may be a Stitch-template color bleed. **Recommendation:** use `#374151` per glossary unless the brand bar intentionally uses primary-colored icons.

### 7.2 Insight card tap targets
Neither insight card has an explicit tap handler or navigation target in the Stitch design. If tips and discussions are eventually surfaced as separate screens, the cards should become `InkWell`-wrapped with appropriate routes. For the MVP they can be non-interactive.

### 7.3 Active tab indicator style (bottom-nav pill)
Confirmed canonical per _design-decisions.md#dd-6. The rounded-rectangle pill background (`primary-container/40`, radius 12 pt) around the active tab's icon + label is now the **canonical** active-tab indicator style. `_components-glossary.md#bottom-nav` has been updated to reflect this. This screen was correct; no conflict remains. Earlier screens that described a flat active style should be understood as superseded by DD-6.

### 7.4 Bottom-nav tab set — confirms canonical (DD-2/DD-4)
The screen HTML shows tabs: בית / סריקה / קהילה / מועדפים — exactly matching DD-2 canonical. No delta to record here.

### 7.5 App icon for `barcode_scanner` vs `qr_code_scanner`
The Stitch HTML uses `barcode_scanner` for the Scan tab icon; the glossary documents `qr_code_scanner`. This was already flagged as an open question in `home-dashboard.md §7`. Recorded here for completeness but not a new inconsistency.

### 7.6 `CommunityStats` schema — no Supabase tables confirmed
The `product_reviews`, `products.added_by`, and `products.status` columns suggested in §6.2 are inferred from product intent and do not appear in the existing `supabase/schema.sql`. Schema additions are required before the controller can be implemented.

### 7.7 Hero card image asset
The Stitch design loads a remote Google-hosted image. A production-ready local asset (`assets/images/community_hero.jpg`) must be sourced and added to `pubspec.yaml` before the screen can render correctly in the app.

---

## Resolved cross-screen note

**Active bottom-nav tab indicator: flat vs. pill background**

Resolved per _design-decisions.md#dd-6. The rounded-rectangle pill indicator (background `primary-container/40`, radius 12 pt) observed on the "קהילה" active tab in this screen is now **canonical** for all active bottom-nav tabs. `_components-glossary.md#bottom-nav` has been updated accordingly. This screen's Stitch rendering was correct all along; earlier specs that described a flat active style are superseded by DD-6. No code conflict remains — implement the pill indicator for the active tab on all screens.
