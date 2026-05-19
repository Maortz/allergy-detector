# המשך סקירה / Review Next Item
Stitch screen: projects/16588854804615693446/screens/2d3d5126490f4c5496fc194b35a865a7
Maps to: app/lib/screens/review_next_screen.dart

---

## 1. Purpose & context

This screen is a **post-review success state** within the community moderation flow. It appears immediately after a user submits a product review/verdict, serving two purposes simultaneously:

1. **Confirm the just-completed action** — a celebration/thank-you moment that rewards the contributor with community points and leaderboard ranking.
2. **Funnel to the next item** — surfaces the next product awaiting community review so the user can continue without returning to a list screen.

The screen sits between moderation actions: the user has just finished reviewing one product (its sibling screen "Review All Clear", Stitch ID `3c43a140`, is a later batch) and is being offered the next queued item. It is a transient destination screen, not a persistent tab — the bottom navigation bar is **suppressed** by Stitch design mandate (see §7.1).

Flow position: `[any review action] → review-next-item → [review product] or [home]`.

---

## 2. Visual layout breakdown

The screen uses a single-column scrollable layout at max-width 448 pt (Tailwind `max-w-md`), centred horizontally, with `padding-top: 96 pt` (accounts for the fixed app bar, approximately 56 pt bar + 40 pt gap) and `padding-bottom: 48 pt`. Horizontal gutter is 20 pt (`margin` token). Layout reads RTL throughout.

### 2.1 Fixed app bar (top)
See §4.1. Background `#F8FAFC` (slate-50). Positioned `fixed top-0 z-50`, height ~56 pt.

### 2.2 Success section (hero)
Vertically centred column, `text-align: center`, bottom margin 32 pt (`xl` token).

- **Check-circle icon container:** 96 × 96 pt circle, background `#78F8DD` (`secondary-container`), foreground `#007261` (`on-secondary-container`), `box-shadow: 0 1px 3px rgba(0,0,0,0.12)` (`shadow-sm`). Bottom margin 24 pt (`lg`).
  - Icon: `check_circle`, filled (`FILL=1`), 48 pt (`text-5xl`).
- **Heading:** "תודה על תרומתך!" — see §4.2.
- **Body copy:** "הביקורת שלך עוזרת לאלפי משתמשים לבחור מוצרים בבטחה ובביטחון." — Inter Regular 16 pt / 24 pt line-height, `#424752` (`on-surface-variant`), max-width 280 pt, centred.

### 2.3 Gamification bento grid
Two equal-width stat cards in a 2-column grid, gap 16 pt (`gutter`). Bottom margin 32 pt (`xl`). See §4.3.

### 2.4 Next-product card section
Full-width section. Section header row (space-between) + a product card below it. See §4.4.

### 2.5 Secondary action (footer)
Ghost/text button "חזרה לדף הבית", vertically separated 32 pt (`mt-xl`) from the card section. Centred horizontally. See §4.5.

---

## 3. Component inventory

| # | Element | Type | Shared? |
|---|---|---|---|
| 1 | App bar | `app-bar` | see _components-glossary.md#app-bar |
| 2 | Check-circle success icon container | Screen-specific | §4.2 |
| 3 | "תודה על תרומתך!" heading | Typography only | §4.2 |
| 4 | Body paragraph | Typography only | §4.2 |
| 5 | Community-points stat card | Screen-specific bento card | §4.3 |
| 6 | Weekly-rank stat card | Screen-specific bento card | §4.3 |
| 7 | "המוצר הבא לבדיקה" section heading | Typography only | §4.4 |
| 8 | "דלג" skip link | Inline text button | §4.4 |
| 9 | Product image (hero photo) | `Image` widget | §4.4 |
| 10 | "חשד לאלרגנים" warning badge (overlay) | Screen-specific chip | §4.4 |
| 11 | Product category label | Typography only | §4.4 |
| 12 | Product name heading | Typography only | §4.4 |
| 13 | Product description | Typography only | §4.4 |
| 14 | "בדוק עכשיו" primary action button | `primary-button` variant | §4.4 |
| 15 | Favourite icon button | Icon button | §4.4 |
| 16 | "חזרה לדף הבית" ghost button | Screen-specific | §4.5 |
| 17 | Bottom nav | suppressed on this screen | §7.1 |

---

## 4. Sub-components / element design

### 4.1 App bar
see _components-glossary.md#app-bar

Variant used: **brand/home bar** — right side shows "בטיחות מזון" (note: diverges from standard "בטוח לאכול" brand text; see §7.2). Left side: `menu` hamburger icon. Avatar: circular 32 × 32 pt, background `primary-container` (`#005EB8`), displays a user profile photo (placeholder image in Stitch). Background `#F8FAFC` (slate-50, near-white), 1 pt bottom border `#E2E8F0` (slate-200), `shadow-sm`.

### 4.2 Success hero section

**Icon container**
- Size: 96 × 96 pt, `border-radius: 9999px` (full circle).
- Background: `#78F8DD` (`secondary-container` token).
- Icon: `check_circle`, filled, 48 pt (`text-5xl`), colour `#007261` (`on-secondary-container` token).
- Shadow: `box-shadow: 0 1px 2px rgba(0,0,0,0.05)` (`shadow-sm`).
- Bottom margin: 24 pt.

**Heading "תודה על תרומתך!"**
- Font: Public Sans Bold 30 pt / 38 pt line-height (`h1` scale).
- Colour: `#00478D` (`primary`).
- Bottom margin: 8 pt (`sm`).

**Body paragraph**
- Font: Inter Regular 16 pt / 24 pt (`body-md` scale).
- Colour: `#424752` (`on-surface-variant`).
- Max-width: 280 pt, `text-align: center`.

### 4.3 Gamification bento cards

Two cards in a `Row`/2-col grid, each:
- Background: `#FFFFFF`.
- Border-radius: 12 pt (`xl`).
- Border: 1 pt solid `#F1F5F9` (slate-100).
- Shadow: `0 2px 8px rgba(0,0,0,0.05)`.
- Padding: 16 pt (`md`) all sides.
- Internal `Column`, `mainAxisAlignment: center`, `crossAxisAlignment: center`.

**Points card (right in RTL)**
- Large value: "+15", Public Sans SemiBold 20 pt / 28 pt (`h3`), colour `#006B5B` (`secondary`).
- Label: "נקודות קהילה", Inter Medium 12 pt / 16 pt (`label-sm`), colour `#727783` (`outline`).

**Rank card (left in RTL)**
- Large value: "#42", Public Sans SemiBold 20 pt / 28 pt (`h3`), colour `#00478D` (`primary`).
- Label: "דירוג שבועי", Inter Medium 12 pt / 16 pt (`label-sm`), colour `#727783` (`outline`).

Both values are dynamic — sourced from the controller (see §6).

### 4.4 Next-product card section

**Section header row**
- Layout: `Row`, `mainAxisAlignment: spaceBetween`.
- Left (RTL trailing): "דלג" — Inter SemiBold 14 pt (`label-bold`), colour `#00478D` (`primary`), `cursor: pointer`, underline on hover. Tapping skips this product and loads the next queued item.
- Right (RTL leading): "המוצר הבא לבדיקה" — Public Sans SemiBold 24 pt / 32 pt (`h2`), colour `#191C1D` (`on-surface`). Bottom margin 16 pt (`md`).

**Product card container**
- Background: `#FFFFFF`.
- Border-radius: 12 pt (`xl`).
- Border: 1 pt solid `#F1F5F9` (slate-100).
- Shadow: `0 8px 24px rgba(0,0,0,0.10)` (elevated card).
- Overflow: hidden (clips image corners). Hover: image scale `1.05` over 500 ms.

**Product image hero**
- Height: 192 pt (`h-48`), full-width.
- `BoxFit.cover`.
- Decorative only (content loaded from `nextItem.imageUrl`).

**"חשד לאלרגנים" warning badge (image overlay)**
- Positioned `absolute top-md right-md` (i.e., 16 pt from top, 16 pt from right in RTL layout — visually top-right corner of the image).
- Container: background `rgba(255,255,255,0.9)` with `backdrop-blur`, `border-radius: 9999px` (full pill), `padding: 4pt 8pt`, `shadow-sm`.
- Internal `Row`: `warning` icon (filled, ~16 pt, colour `#B05B00`) → gap 4 pt → label "חשד לאלרגנים", 10 pt Bold, colour `#B05B00`.
- This is NOT the standard `status-pill` (no status enum maps to "חשד לאלרגנים"); it is a screen-specific urgency badge indicating the product's allergen verification status is unresolved.

**Product card body (padding 24 pt)**

*Meta row (stacked column, gap 4 pt, bottom margin 24 pt):*
- Category label: "משקאות צמחיים" — Inter Medium 12 pt / 16 pt (`label-sm`), colour `#727783` (`outline`), `text-transform: uppercase`, `letter-spacing: wider`.
- Product name: "חלב שקדים אורגני - ללא סוכר" — Public Sans SemiBold 20 pt / 28 pt (`h3`), colour `#191C1D` (`on-surface`).
- Description: "מוצר זה ממתין לאימות קהילה בנושא הימצאות עקבות בוטנים ורכיבי חלב." — Inter Regular 16 pt / 24 pt (`body-md`), colour `#424752` (`on-surface-variant`), max 2 lines (`line-clamp-2`).

*Action row (gap 16 pt, `Row`):*
- **"בדוק עכשיו" button** (flex-1): see _components-glossary.md#primary-button. Variant: **Primary** (`#00478D` fill, white text). Label: "בדוק עכשיו". Trailing icon: `arrow_back` 20 pt (RTL forward arrow). Height: ~48 pt (`py-3` + label), border-radius 8 pt (`lg`). Shadow `shadow-md`. Hover: background shifts to `primary-container` (`#005EB8`). Active: scale 95%.
  - Note: icon used is `arrow_back` (Stitch HTML literal). In RTL context this points leftward (i.e., forward/proceed direction). Canonical primary-button glossary specifies `chevron_left`; see §7.3.
- **Favourite icon button** (fixed 48 × 48 pt): border 2 pt solid `#F1F5F9` (slate-100), border-radius 8 pt (`lg`). Icon: `favorite` (outlined/unfilled at rest), `#9CA3AF` (slate-400) at rest. Hover: icon and border shift to `#00478D` (`primary`). Toggleable (filled heart when favourited — not explicitly shown in Stitch but implied by interactive pattern).

### 4.5 "חזרה לדף הבית" ghost button

- Type: text/ghost button with leading icon.
- Layout: `Row`, `mainAxisAlignment: center`, gap 8 pt.
- Leading icon: `home`, 24 pt.
- Label: "חזרה לדף הבית".
- Font: Inter SemiBold 14 pt (`label-bold`).
- Colour: `#00478D` (`primary`).
- Background: transparent at rest; hover `rgba(#D6E3FF, 0.20)` (`primary-fixed-dim` at 20% opacity).
- Border-radius: 9999 pt (full pill).
- Padding: `EdgeInsets.symmetric(horizontal: 24, vertical: 16)`.
- Top margin: 32 pt (`mt-xl`).
- On tap: navigates to Home (index 0 of `MainContainer`).

---

## 5. States & interactions

### 5.1 Screen entry state
The screen is entered after a successful review submission. The success hero (§4.2) and gamification cards (§4.3) are fully populated with the just-earned reward data (points delta, new rank). The next product (§4.4) is pre-fetched (ideally concurrent with the review submission) to avoid perceived loading delay.

### 5.2 Loading state (next product not yet ready)
If the next queued product is still being fetched when the screen mounts:
- The product card area shows a shimmer/skeleton: a full-width 192 pt tall grey rectangle for the image, and three shimmer rows for category/name/description.
- The "בדוק עכשיו" button is disabled (background `#D1D5DB`, text `#9CA3AF`).
- The "דלג" skip link is hidden or also disabled.

### 5.3 "בדוק עכשיו" — proceed to review
Tapping "בדוק עכשיו" navigates to the product review/detail screen for `nextItem`, passing `nextItem.id` and `nextItem.source = community_queue`. The current screen is popped from the navigation stack (or replaced) so back-navigation returns the user to the queue/community screen, not back to this success state.

### 5.4 "דלג" — skip item
Tapping "דלג":
1. Marks `nextItem` as skipped for this user session (not permanently blocked).
2. Triggers a new fetch for the next queued item.
3. The product card transitions: brief fade-out → skeleton shimmer → fade-in with new product data. If no further items exist in the queue, the card is replaced with an empty-state message (copy TBD by product).

### 5.5 Favourite toggle
Tapping the heart icon button:
- Toggles favourite state for `nextItem`.
- `favorite_border` (unfilled) → `favorite` (filled, `#00478D`).
- Persists to user profile / SharedPreferences (same pattern as other favouriting in the app).
- Does NOT trigger navigation.

### 5.6 "חזרה לדף הבית" — home navigation
Tapping the ghost button pops/replaces the stack to navigate to `MainContainer` index 0 (Home). No state changes to the queue.

### 5.7 Empty-queue state
When `nextItem` is null (no products pending review):
- The entire "המוצר הבא לבדיקה" section is hidden.
- In its place: a small card or inline message, e.g., "אין מוצרים נוספים לסקירה כרגע" (copy TBD).
- "חזרה לדף הבית" remains visible and is the primary action.

---

## 6. Data & controller contract

### 6.1 Inputs (passed to screen / loaded on mount)
| Field | Type | Source | Description |
|---|---|---|---|
| `pointsEarned` | `int` | Review result payload | Points awarded for the completed review (displayed as "+N"). |
| `newWeeklyRank` | `int` | Review result payload | User's updated community leaderboard rank (displayed as "#N"). |
| `nextItem` | `ReviewQueueItem?` | `ReviewQueueService.fetchNext()` | Next product pending community verification. Nullable (empty-queue state). |

### 6.2 `ReviewQueueItem` model (minimum)
```dart
class ReviewQueueItem {
  final String id;
  final String name;           // "חלב שקדים אורגני - ללא סוכר"
  final String categoryLabel;  // "משקאות צמחיים"
  final String description;    // body copy (max 2 lines displayed)
  final String imageUrl;
  final String alertLabel;     // "חשד לאלרגנים" or similar — drives overlay badge
  bool isFavourited;
}
```

### 6.3 Controller actions
| Action | Trigger | Effect |
|---|---|---|
| `skipItem(id)` | "דלג" tap | Marks item skipped, fetches next |
| `favouriteItem(id)` | Heart button tap | Toggles favourite on item |
| `proceedToReview(id)` | "בדוק עכשיו" tap | Navigates to product review screen |
| `goHome()` | "חזרה לדף הבית" tap | Navigates to MainContainer index 0 |

### 6.4 Service layer
- `ReviewQueueService` (new service, `app/lib/services/review_queue_service.dart`) wraps the Supabase query for community-review queue items.
- `UserStatsService` or existing Supabase call provides `pointsEarned` + `newWeeklyRank` from the review-submission response.

---

## 7. Open questions / design-vs-app deltas

### 7.1 Bottom navigation suppressed — delta
**Delta (design vs. app):** The Stitch HTML explicitly suppresses the bottom navigation bar on this screen ("Navigation suppressed for Success Screen per design mandate"). The app's `MainContainer` uses an `IndexedStack` with a persistent `NavigationBar` on all tabs; this screen will need to be implemented as a pushed route (not a tab) to achieve the no-nav-bar intent, or the `NavigationBar` must be hidden conditionally.
**Action required:** Implement `ReviewNextScreen` as a `Navigator.push` destination outside `MainContainer`, not as an indexed tab.

### 7.2 App-bar brand text "בטיחות מזון" vs. "בטוח לאכול" — delta
**Delta:** The HTML shows "בטיחות מזון" as the app-bar brand text. The canonical brand text per `_components-glossary.md#app-bar` is "בטוח לאכול". This appears to be a Stitch content artefact (the app name variant used during this screen's generation). Implementation should use the canonical "בטוח לאכול".

### 7.3 "בדוק עכשיו" button trailing icon — delta
**Delta:** The Stitch HTML specifies `arrow_back` as the trailing icon on the "בדוק עכשיו" button. The `_components-glossary.md#primary-button` canonical continue icon is `chevron_left`. In an RTL layout both icons point in the same physical direction (leftward = forward). Canonical `chevron_left` should be used for consistency with the glossary; `arrow_back` is a Stitch artifact.

### 7.4 Gamification points and rank values are placeholder
"+15" and "#42" in the Stitch design are placeholder/dummy values. Real values come from the review submission API response. The UI layout must accommodate variable-length values (e.g., "+150", "#1,024").

### 7.5 "חשד לאלרגנים" badge is not a standard status-pill
The overlay warning badge on the product image is a screen-specific urgency indicator and must NOT be implemented using the shared `StatusPill` widget. It uses a distinct visual style (frosted glass, amber text) and a non-standard label. A dedicated `AllergenSuspicionBadge` widget or inline build is appropriate.

### 7.6 Favourite icon initial state
The Stitch HTML renders the `favorite` icon (filled) rather than `favorite_border` (outline). It is unclear whether this means the placeholder next-product is pre-favourited or if the icon choice is incidental. Implementation should default to `favorite_border` (not favourited) unless `nextItem.isFavourited` is true.
