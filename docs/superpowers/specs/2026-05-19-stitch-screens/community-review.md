# Community Review / סקירת קהילה
Stitch screen: projects/16588854804615693446/screens/521b195cd91443849b0f983487ef5f9c
Maps to: app/lib/screens/community_review_screen.dart

## 1. Purpose & context

The Community Review screen is the moderation/review surface of the Community Hub. It presents a single pending community-contributed product to a reviewer (community member or moderator) and asks them to approve or reject the allergen data submitted. The reviewer sees the product image, category, name, brand, the reported allergen breakdown (contains / may-contain / absent), and the contributor's free-text note. They then tap "אישור מוצר" (approve) or "פסילת מוצר" (reject), with the reject path requiring a typed rejection reason.

A counter ("12 נותרו") shows how many contributions remain in the review queue. A horizontal history strip below the decision panel shows the reviewer's own recent past contributions with their outcome status (approved / pending).

This screen is tab 2 ("קהילה") in `MainContainer`'s `IndexedStack`, rooted in `app/lib/screens/community_screen.dart`.

## 2. Visual layout breakdown

Canvas: 780 × 2970 px @2× (390 pt logical width). Background: `#F8F9FA` (`surface`, token TBD — near `AppColors.surface`). RTL (`dir="rtl"` on `<html>`).

### App bar (top, fixed)
Per DD-15, this screen uses the canonical **detail-bar** variant — no centred
title, no `arrow_forward` trailing, no menu hamburger.

- Height: 56 pt, white background, `elevation: 0` (optional 1 pt bottom border `#F1F5F9`).
- **RTL leading (right):** screen title "סקירת מוצר" — Public Sans SemiBold 16 pt, `#1F2937` (right-aligned per RTL).
- **RTL trailing (left):** `arrow_back_ios` (or platform-appropriate back glyph), `#374151`, 24 pt — pops the route back to Community Hub.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar) — detail-bar variant.

### Status & counter row (below app bar)
- Horizontal flex row, `justify-between`, 16 pt horizontal margin, 16 pt top padding, 24 pt bottom margin.
- **Right block (RTL leading):**
  - "סקירת מוצר חדש" — Public Sans SemiBold 24 pt, `#191C1D` (`on-surface`).
  - "תרומת הקהילה לאימות נתונים" — Inter Regular 12 pt, `#727783` (`outline`).
- **Left block (RTL trailing) — queue counter badge:**
  - Background: `#D6E3FF` (`primary-fixed`), text: `#001B3D` (`on-primary-fixed`).
  - Padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`, border-radius 12 pt.
  - `pending_actions` icon (filled variant, 20 pt) + "12 נותרו" — Inter SemiBold 14 pt.
  - Subtle `shadow-sm`.

### Main bento grid (product card + action panel)
Two-column bento layout (`grid-cols-12`, gap 16 pt). On mobile these stack vertically (full-width columns).

#### Left card — Product image & basic info (col-span-5)
- White card (`#FFFFFF`), border-radius 12 pt, padding 16 pt, border 1 pt `#E7E8E9` (`surface-container-high`), shadow 0 2 8 rgba(0,0,0,0.05).
- **Image area:** aspect-ratio 1:1, border-radius 8 pt, background `#EDEEEF` (`surface-container`). Displays product photo (sample: organic oat-milk carton).
- **Info block** (below image, `space-y: 4 pt`):
  - Category chip: "חלב ומשקאות" — Inter Medium 12 pt, `#006B5B` (`secondary`) on `#78F8DD` (`secondary-container`) background, border-radius 9999 pt (pill), `px-8 py-[2px]`.
  - Product name: "משקה שיבולת שועל אורגני" — Public Sans SemiBold 20 pt, `#191C1D`.
  - Brand line: "מותג: EcoNature" — Inter Regular 16 pt, `#727783` (`outline`).

#### Right column (col-span-7) — two stacked cards
Two cards stacked vertically with 16 pt gap:

**Card A — Allergen info card**
- White card, border-radius 12 pt, padding 16 pt, border 1 pt `#E7E8E9`, shadow same as above. `flex-grow` — expands to fill available height.
- **Header row** (bottom border 1 pt `#EDEEEF`, 8 pt gap, 16 pt bottom padding):
  - `warning` icon, `#00478D` (primary), 24 pt.
  - "מידע על אלרגנים שהוזן:" — Inter SemiBold 14 pt, `#191C1D`.
- **Allergen grid** (`grid-cols-2`, 8 pt gap): three allergen-status tiles.
- **Contributor note block** (16 pt top margin):
  - Background: `#F3F4F5` (`surface-container-low`), border-right 4 pt solid `#00478D` (primary), border-radius 8 pt, padding 16 pt.
  - Label: "הערת התורם:" — Inter Medium 12 pt, `#727783`.
  - Note text: Inter Regular 16 pt, `#191C1D`, italic — e.g. `"צילמתי את גב האריזה, המידע מעודכן לסדרת הייצור החדשה של מרץ 2024."`

**Card B — Decision panel**
- White card, border-radius 12 pt, padding 16 pt, border 1 pt `#E7E8E9`, shadow same.
- "החלטה למוצר זה:" — Inter SemiBold 14 pt, `#191C1D`, 16 pt bottom margin.
- **2-column button row** (16 pt gap, 16 pt bottom margin):
  - "אישור מוצר" button (approve — primary filled).
  - "פסילת מוצר" button (reject — error outlined).
- **Rejection reason textarea** below buttons.

### History strip (below bento grid)
- 32 pt top margin.
- Section header: "תרומות אחרונות שלך" — Public Sans SemiBold 20 pt, `#191C1D`, 16 pt bottom margin.
- Horizontal scroll row (no scrollbar visible), 16 pt gap, `overflow-x: auto`.
- Two contribution mini-cards visible (expandable).

### Bottom navigation bar (fixed, bottom)
- See [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav).
- "קהילה" tab is NOT shown as active in this screen's HTML — see §7.2.

## 3. Component inventory

| Component | Type | Glossary ref / notes |
|---|---|---|
| App bar | Shared | [_components-glossary.md#app-bar](_components-glossary.md#app-bar) — detail-bar variant per DD-15 |
| Bottom nav | Shared | [_components-glossary.md#bottom-nav](_components-glossary.md#bottom-nav) — §7.2 |
| Queue counter badge | Screen-specific | Right of status row; teal/primary-fixed background; described in §2 |
| Category chip | Screen-specific | Pill in teal (`secondary`/`secondary-container`) palette; not an allergen-chip variant |
| Allergen-status tile | Screen-specific | 2-col grid tile (contains / may-contain / absent states); NOT an `allergen-chip` |
| Contributor note block | Screen-specific | Left-bordered (RTL: right-bordered) blockquote-style text card |
| Approve button | Screen-specific (Primary CTA) | Primary filled; see §4 |
| Reject button | Screen-specific (Danger outlined) | Error-colour outlined; see §4 |
| Rejection reason textarea | Screen-specific | Floating-label text area; see §4 |
| Contribution mini-card | Screen-specific | History strip card; see §4 |

## 4. Sub-components / element design

### Allergen-status tile (grid tile in Card A)

Three states; each tile is `p-md rounded-lg border flex items-center gap-md`.

| State | Background | Border | Icon circle bg | Icon | Icon color | Status label | Label color |
|---|---|---|---|---|---|---|---|
| Contains (מכיל בוודאות) | `#FFDAD6` / 10% (`error-container/10`) | 2 pt `#BA1A1A/20` (`error/20`) | `#FFDAD6` (`error-container`) | allergen-specific (e.g. `bakery_dining` for gluten) | `#93000A` (`on-error-container`) | "מכיל בוודאות" 11 pt Inter Medium `#BA1A1A` (`error`) |
| May contain (עשוי להכיל) | `#F3F4F5` (`surface-container-low`) | 1 pt `#C2C6D4` (`outline-variant`) | `#E1E3E4` (`surface-variant`) | allergen-specific (e.g. `nat` for nuts) | `#424752` (`on-surface-variant`) outline | "עשוי להכיל" 11 pt Inter Medium `#727783` (`outline`) |
| Safe / absent (לא מכיל) | `#78F8DD` / 10% (`secondary-container/10`) | 1 pt `#006B5B/20` (`secondary/20`) | `#78F8DD` (`secondary-container`) | allergen-specific (e.g. `water_drop` for milk) | `#007261` (`on-secondary-container`) | "לא מכיל" 11 pt Inter Medium `#006B5B` (`secondary`) |

Tile inner layout (RTL row):
- Icon circle: 40×40 pt, `border-radius: full`.
- Text block (right of circle in LTR terms, left in RTL): name label Inter SemiBold 14 pt `#191C1D` + status label 11 pt below.

Allergen icon mapping: use [_components-glossary.md#allergen-chip](_components-glossary.md#allergen-chip) icon table for the same allergen symbols.

### Approve button ("אישור מוצר")

Full-width within its half-column slot. Height 48 pt (via `py-md` = 16 pt top+bottom), border-radius 12 pt.
- Background: `#00478D` (`primary`). Text: `#FFFFFF` (`on-primary`).
- Icon: `check_circle` 24 pt, leading (right in RTL), gap 8 pt.
- Label: "אישור מוצר" — Inter SemiBold 14 pt.
- `active:scale-95` press feedback. `shadow-md`.
- Disabled state: background `#D1D5DB`, text `#9CA3AF` (matches [_components-glossary.md#primary-button](_components-glossary.md#primary-button) disabled).

### Reject button ("פסילת מוצר")

Full-width within its half-column slot. Height 48 pt, border-radius 12 pt.
- Background: transparent / white. Border: 2 pt solid `#BA1A1A` (`error`). Text: `#BA1A1A`.
- Icon: `cancel` 24 pt, `#BA1A1A`, gap 8 pt.
- Label: "פסילת מוצר" — Inter SemiBold 14 pt.
- Hover: `bg-error-container/20` (`#FFDAD6` at 20% opacity). `active:scale-95`.

### Rejection reason textarea

Floating-label pattern. Positioned relative container; label floats above the top border.
- Container: `border border-outline-variant` (`#C2C6D4`) 1 pt, border-radius 8 pt, transparent background.
- Floating label: "סיבת הפסילה (במידה ונפסל)" — 11 pt Inter Bold, `#727783` (`outline`). Absolute-positioned, `-top-2 right-3` (RTL: right edge), `px-1`, background `#FFFFFF` to cut the border.
- `<textarea>`: height 80 pt, `text-right`, `font-body-md` Inter Regular 16 pt. Placeholder: "פרט מדוע המידע אינו תקין...". Focus ring: 1 pt `#00478D` (`primary`).
- Only required and validated when reject action is chosen.

### Contribution mini-card (history strip)

Fixed min-width 200 pt, white `#FFFFFF` background, border-radius 12 pt, padding 8 pt, border 1 pt `#E7E8E9`. Horizontal flex row.
- **Thumbnail:** 48×48 pt, border-radius 8 pt, `surface-container` (`#EDEEEF`) background, `object-cover` image.
- **Text block:**
  - Product name: Inter SemiBold 14 pt, `#191C1D`, truncated to 128 pt (`truncate w-32`).
  - Status indicator row: 10 pt Inter Bold, icon 12 pt + label.
    - Approved: icon `check_circle` filled, `#006B5B` (`secondary`), label "אושר".
    - Pending: icon `schedule` outline, `#727783` (`outline`), label "ממתין".
    - (Rejected variant: expected — icon `cancel`, `#BA1A1A`, label "נפסל" — not shown in Stitch but implied by the flow.)

## 5. States & interactions

### Screen-level states

| State | Description |
|---|---|
| **Queue has items** (default) | Counter shows "N נותרו"; full bento layout rendered with a pending product. |
| **Queue empty** | Counter "0 נותרו"; bento grid should show empty state: illustration + "אין מוצרים לסקירה כרגע" message. Not designed in Stitch — flagged in §7.3. |
| **Submitting decision** | Approve/reject buttons enter loading state (`CircularProgressIndicator` replaces label); textarea disabled. |
| **Decision submitted** | Screen advances to next pending product OR shows empty-queue state. |

### Card B — Decision panel interactions

1. **Approve tap:** "אישור מוצר" button fills with `#003F7D` (pressed), triggers approval API call, advances to next queued product.
2. **Reject tap:** "פסילת מוצר" button shows pressed state (`border-error bg-error-container/20`). Textarea becomes required. Submit is gated until the textarea is non-empty.
3. **Reject submit:** Validation check (non-empty reason) → API call → advance.
4. **Textarea focus:** container border switches to 1 pt `#00478D` primary, floating label colour shifts to `#00478D`.

### App bar back/close

`arrow_back_ios` (detail-bar canonical per DD-15) → pops the review detail,
returns to the Community Hub list/landing.

## 6. Data & controller contract

### Inputs (from parent / route)

```dart
// Passed as navigation argument or via CommunityReviewController
class CommunityReviewArgs {
  final String productId;        // pending product to review
  final int queueCount;          // total items remaining
}
```

### Data model — PendingReview

```dart
class PendingReview {
  final String id;
  final String productId;
  final String productName;       // "משקה שיבולת שועל אורגני"
  final String brandName;         // "EcoNature"
  final String categoryLabel;     // "חלב ומשקאות"
  final String? imageUrl;         // product photo
  final List<AllergenReport> allergenReports;  // contains / may_contain / absent per allergen
  final String? contributorNote;  // free-text note from the contributor
}

enum AllergenReportStatus { contains, mayContain, absent }

class AllergenReport {
  final Allergen allergen;
  final AllergenReportStatus status;
}
```

### Data model — PastContribution (history strip)

```dart
class PastContribution {
  final String productId;
  final String productName;
  final String? imageUrl;
  final ContributionOutcome outcome;   // approved | pending | rejected
}
enum ContributionOutcome { approved, pending, rejected }
```

### Controller methods

```dart
abstract class CommunityReviewController {
  // Loads the next pending review item; updates queueCount.
  Future<PendingReview?> loadNextPendingReview();

  // Approves the current review.
  Future<void> approveReview(String reviewId);

  // Rejects the current review with a required reason string.
  Future<void> rejectReview(String reviewId, {required String reason});

  // Loads the current user's recent past contributions for the history strip.
  Future<List<PastContribution>> loadPastContributions();
}
```

### Supabase queries (expected)

- `pending_reviews` table (or `product_contributions` + status filter): fetch one item where `status = 'pending'`, ordered by `created_at asc`.
- `PATCH pending_reviews SET status='approved'|'rejected', rejection_reason=? WHERE id=?`.
- `user_contributions` view: filter by `user_id`, order `reviewed_at desc`, limit 20.

## 7. Open questions / design-vs-app deltas

### §7.1 — App bar variant — resolved per DD-15

Resolved per _design-decisions.md#dd-15. App-bar variant set is closed at three
(brand / detail / wizard). This screen normalises to the **detail-bar** variant:
right-aligned title "סקירת מוצר", `arrow_back_ios` on the RTL-trailing side,
no centred title, no `arrow_forward`, no hamburger. The Stitch render
(menu | centred title | arrow_forward) is an artifact; do not implement it.

### §7.2 — Bottom nav: stale tab set + active tab

The Stitch HTML bottom nav shows four tabs: **בית / סריקה / הוספה / הגדרות** — with "הוספה" (`add_circle`, filled/active, `bg-blue-50`) as the highlighted tab. This diverges from the DD-2/DD-4 canonical set (בית / סריקה / קהילה / מועדפים) on two counts: (a) the tab labels and icons differ, (b) the active tab should be "קהילה" (index 2) for a Community screen, not "הוספה". Both divergences are stale Stitch artefacts per DD-4. The canonical bottom-nav applies; "קהילה" tab (index 2) is active on this screen.

### §7.3 — Empty queue state — resolved

When `queueCount == 0`, the bento grid + history strip are replaced by a
centred empty-state column:
- `Icon(Icons.task_alt, size: 64, color: #9CA3AF)`.
- Heading "אין מוצרים לסקירה כרגע" — Public Sans SemiBold 18 pt, `#1F2937`,
  `TextAlign.center`. 12 pt below the icon.
- Body "תודה על תרומתך לקהילה! נשלח לך הודעה כשיהיו מוצרים חדשים לסקירה." —
  Inter Regular 14 pt, `#6B7280`, `TextAlign.center`, max-width 280 pt. 8 pt
  below the heading.
- A `PrimaryButton` "חזרה לקהילה" — full-width within 16 pt margins, 24 pt top
  margin, navigates back to the Community Hub root.

App-bar and bottom-nav remain unchanged in this state.

### §7.4 — Allergen-status tile vs. allergen-chip

The allergen breakdown inside Card A uses a bespoke tile layout (icon circle + name + status text) rather than any existing `allergen-chip` variant from the glossary. The tile communicates three reporting states (contains / may-contain / absent) that don't map 1:1 to the chip's safe/caution/avoid semantics. These should remain distinct components; the allergen-chip glossary does not need a new variant for this pattern.

### §7.5 — Navigation hierarchy — resolved (nested under Hub)

Community Hub (`community-hub.md`) is the **root** of tab index 2 in
`MainContainer`. Tapping "התחל בבדיקה" on the Hub pushes the **Community
Review** screen on top. Back navigation returns to the Hub. The app must be
realigned so `app/lib/screens/community_screen.dart` (or a renamed
`community_hub_screen.dart`) is the tab root, and `community_review_screen.dart`
is a pushed sub-route.

### 7.6 Implementation deltas — updated 2026-06-09

**Note:** The "Maps to" field in the spec header is stale. The correct file is `app/lib/screens/community_review_screen.dart` (not `community_screen.dart`). The file was created prior to this pass; `community_screen.dart` is the Community Hub root.

| # | Spec requirement | Current code |
|---|---|---|
| CR1 | Dedicated `community_review_screen.dart` implementing the product-review workflow | ✅ File exists at `app/lib/screens/community_review_screen.dart` |
| CR2 | Detail-bar AppBar: title "סקירת מוצר", `arrow_back_ios` trailing (DD-15) | ✅ Implemented — `AppBar` with title "סקירת מוצר", `Icons.arrow_back_ios` action |
| CR3 | Status/counter row: "סקירת מוצר חדש" heading + queue counter badge ("12 נותרו", `#D6E3FF` bg) | ✅ Implemented — `_buildCounterRow()` with `AppColors.primaryFixed` bg badge |
| CR4 | Two-column bento: product image/info card (left) + allergen-info card + decision panel card (right) | Partially — single-column vertical layout, not two-column bento |
| CR5 | Allergen-status tiles (contains / may-contain / absent) with state-specific styling | ✅ Implemented — `_buildAllergenTile()` with per-status colors |
| CR6 | Contributor note block (right-bordered blockquote, italic text) | ✅ Implemented — `_buildContributorNote()` with right border 4 pt `AppColors.primary` |
| CR7 | Approve ("אישור מוצר") + Reject ("פסילת מוצר") buttons; in-memory queue update | ✅ **FIXED 2026-06-09** — buttons wired; `onApprove`/`onReject` callbacks update `CommunityScreen._localQueue` |
| CR8 | Rejection reason floating-label textarea (required when rejecting) | ✅ Implemented — `_reasonController` TextField, validated before reject |
| CR9 | History strip: "תרומות אחרונות שלך" horizontal scroll with `PastContribution` mini-cards | ✅ Implemented — `_buildHistoryStrip()` |
| CR10 | Empty-queue state (§7.3): "אין מוצרים לסקירה כרגע" + "חזרה לקהילה" button | ✅ Implemented — `_buildEmptyState()` |
| CR11 | Dynamic data: `PendingReview` model from Supabase `pending_reviews` table | In-memory stub only; Supabase table does not exist yet |

**Remaining:** CR4 (two-column layout on larger screens), CR11 (Supabase wiring pending `pending_reviews` table).
