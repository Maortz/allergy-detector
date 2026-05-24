# Manage Trusted Brands (Admin) / ניהול מותגים מהימנים
Stitch screen: projects/16588854804615693446/screens/59e6d26de9a64bec9123ec396aae32fc
Maps to: app/lib/screens/admin_brands_screen.dart

## 1. Purpose & context

This is an **admin-only management screen** that allows authorised administrators to maintain the brands database for the allergy-detection clinic. The screen surfaces three core capabilities:

1. **Discoverability** — search through registered brands by name.
2. **Trust-status management** — toggle each brand's verified/unverified state via an inline switch.
3. **CRUD** — add new brands and edit existing brand records.

The screen is reached via the navigation drawer (menu icon in the app bar), not via the bottom navigation tabs. Its drawer entry is labelled "ניהול מותגים" with the `branding_watermark` icon and displays the active-highlight state (right border `#005EB8`, background `bg-blue-50`) when the user is on this screen.

There is no end-user path to this screen — it is gated to admin accounts (see §6). The MVP app has no authentication layer, so admin gating is a design intent that must be reconciled with the current implementation.

---

## 2. Visual layout breakdown

The screen is a single scrollable column inside a `Scaffold`. From top to bottom:

```
┌─────────────────────────────────────────┐
│  AppBar (sticky)                        │  h = 56 pt
├─────────────────────────────────────────┤
│  Page header block                      │  mb = 32 pt (xl)
│    H1 title: "ניהול מותגים מאושרים"    │
│    Subtitle paragraph                   │
├─────────────────────────────────────────┤
│  Search + Stats bento (2-column grid)   │  mb = 32 pt (xl)
│    [Search field card  |  Stats card]   │
│     col-span-2           col-span-1     │
├─────────────────────────────────────────┤
│  Brand list (vertical stack)            │  gap = 16 pt (gutter)
│    Brand row card 1 — תנובה            │
│    Brand row card 2 — שטראוס           │
│    Brand row card 3 — יוניליוור        │
│    … (scrollable)                       │
├─────────────────────────────────────────┤
│  "הוספת מותג חדש" FAB / action button  │  mt = 32 pt (xl)
├─────────────────────────────────────────┤
│  BottomNavBar (fixed, 64 pt)            │
└─────────────────────────────────────────┘
```

**Outer padding:** `px-20 pt` (HTML: `p-margin` = 20 px) and `mt-24 pt` (HTML: `mt-lg` = 24 px) for the main content area. `max-w-4xl mx-auto` centres on wide viewports; on 390 pt mobile it is effectively full-width minus margins.

**Background:** `#F8F9FA` (`AppColors.surface` / `surface-container-lowest` for cards over this).

---

## 3. Component inventory

| # | Component | Type | Glossary ref |
|---|---|---|---|
| 1 | App bar — "בטוח לאכול" brand bar with menu icon + avatar (canonical per DD-8; Stitch renders "בדיקת אלרגנים" — §7 delta) | Shared | see _components-glossary.md#app-bar (Home/brand-bar variant) |
| 2 | Page header (H1 + subtitle) | Screen-specific | §4.1 |
| 3 | Search field card | Screen-specific | §4.2 |
| 4 | Stats card (count + progress bar) | Screen-specific | §4.3 |
| 5 | Brand list row card (logo · name · last-update · toggle · edit) | Screen-specific | §4.4 |
| 6 | Verification toggle (on/off switch) | Screen-specific sub-element | §4.5 |
| 7 | "הוספת מותג חדש" add-brand button | Screen-specific | §4.6 |
| 8 | Bottom navigation bar | Shared | see _components-glossary.md#bottom-nav |
| 9 | Navigation drawer (hidden by default) | Shared | see _components-glossary.md (not yet fully specced — admin variant with "ניהול מותגים" entry) |

---

## 4. Sub-components / element design

### 4.1 Page header block

- **Title:** "ניהול מותגים מאושרים"
  - Font: Public Sans 700, 30 pt / 38 pt line-height (`h1`).
  - Color: `AppColors.primary` `#00478D`.
  - Alignment: right-aligned (RTL natural).
- **Subtitle:** "עדכן ואמת מותגים במאגר הנתונים של הקליניקה"
  - Font: Inter Regular 16 pt / 24 pt (`body-md`).
  - Color: `#424752` (`on-surface-variant`).
- **Spacing:** gap 4 pt (`unit`) between title and subtitle; 32 pt (`xl`) margin-bottom before bento grid.

### 4.2 Search field card

- **Container:** `#FFFFFF` fill, `BorderRadius.circular(12)` (xl), 8 pt drop shadow `rgba(0,0,0,0.05)`, 1 pt border `#EDEEEF` (`surface-container`). Padding 16 pt (`md`).
- **Label:** "חיפוש מותג" — Inter SemiBold 14 pt (`label-bold`), `#424752`.
- **Input field:**
  - Placeholder: "הקלד שם מותג (לדוגמה: שטראוס)"
  - `search` icon (`material-symbols-outlined`) positioned at the RTL-trailing end (right side within RTL layout = `absolute right-3`) in `#727783` (`outline`).
  - Border: 1 pt `#727783` resting; `#00478D` focused with 1 pt ring.
  - Padding: `pr-10 pl-4 py-3` (right pad accommodates icon).
  - Background: `#FFFFFF`; `BorderRadius.circular(8)` (lg).
  - Text: right-aligned.
- **Behavior:** filters the brand list in real-time (or on submit) against brand names. See §5.

### 4.3 Stats card ("מותגים רשומים")

- **Container:** same card style as §4.2 (white fill, rounded-xl, shadow, border). Padding 16 pt.
- **Top row:** right-aligned count "124" (Public Sans SemiBold 20 pt / 28 pt, `#00478D`) and left-aligned label "מותגים רשומים" (Inter Medium 12 pt, `#424752`).
- **Progress bar:** full-width, height 6 pt (h-1.5), `BorderRadius.circular(9999)`, background `#E1E3E4` (`surface-container-highest`), filled track `#00478D` at 85% fill. Represents the percentage of brands that are verified (not a loading indicator).
- **Spacing:** 8 pt (`sm`) margin-top above progress bar.

### 4.4 Brand list row card

Each row is a card with the following structure (RTL — right to left reading order):

```
[ Logo thumbnail ]  [ Name + status text ]  →  [ Toggle group ]  [ Edit button ]
```

- **Container:** `#FFFFFF` fill, `BorderRadius.circular(12)`, 8 pt shadow `rgba(0,0,0,0.05)`, 1 pt border `#EDEEEF`. Padding 24 pt (`lg`). On hover: elevated shadow (`shadow-md`).
- **Logo thumbnail:**
  - Size: 56 × 56 pt (`w-14 h-14`).
  - Container: white fill, 8 pt border-radius (lg), 1 pt border `#EDEEEF`, `overflow: hidden`, 8 pt padding.
  - Image: `object-contain w-full h-full` — brand logo asset.
  - If no logo available: placeholder icon or initials (not specced in Stitch; app may use `Icons.image_not_supported`).
- **Name + metadata column:**
  - Brand name: Public Sans SemiBold 20 pt / 28 pt (`h3`), `#191C1D` (`on-surface`).
  - Status/metadata line: Inter Medium 12 pt (`label-sm`), `#424752` (`on-surface-variant`), 4 pt (`xs`) margin-top.
  - Verified brands show: "עדכון אחרון: לפני יומיים" / "עדכון אחרון: לפני שבוע" (last-updated timestamp, relative).
  - Unverified brands show: "ממתין לבדיקת רכיבים" (pending ingredient review).
- **Right-side actions (RTL trailing — physically on the left):** `flex items-center gap-xl` (32 pt gap).
  - Toggle group (see §4.5).
  - Edit button (see §4.6 inline).

**Edit icon button:**
- `edit` icon, Material Symbols Outlined, 24 pt.
- Resting color: `#727783` (`outline`).
- Hover/group-hover: `#00478D` (`primary`).
- Tap navigates to brand edit form (see §5).

**Observed brands in Stitch:**

| Brand (HE) | Logo | Status text | Toggle state |
|---|---|---|---|
| תנובה | dairy logo | "עדכון אחרון: לפני יומיים" | ON (verified) |
| שטראוס | snack product image | "עדכון אחרון: לפני שבוע" | ON (verified) |
| יוניליוור | organic goods image | "ממתין לבדיקת רכיבים" | OFF (unverified) |

### 4.5 Verification toggle

A pill-shaped toggle switch indicating whether a brand is admin-verified.

- **Container button:** `h-7 w-12` (28 × 48 pt), `BorderRadius.circular(9999)` (full pill), `focus:outline-none`.
- **ON state (verified):** track background `#005EB8` (`primary-container` token in the Stitch theme; map to `AppColors.primary` `#00478D` in the app token). Thumb translated to the left end: `translateX(-1.25rem)` = −20 pt (RTL: thumb on left = checked/on in RTL layout).
- **OFF state (unverified):** track background `#E1E3E4` (`surface-container-highest`). Thumb at `translateX(-0.25rem)` = −4 pt (right side, near edge).
- **Thumb:** `h-5 w-5` (20 × 20 pt), `#FFFFFF`, `BorderRadius.circular(9999)`, smooth transition.
- **Label above toggle:** "סטטוס אימות" — Inter Medium 12 pt, `#727783` (`outline`), `mb-1`, right-aligned.
- **Flutter implementation:** `Switch` widget with `activeColor: AppColors.primary` and custom sizing, or a custom `AnimatedContainer` following the described geometry. RTL thumb direction must be tested.

### 4.6 "הוספת מותג חדש" add-brand button

- Positioned at the bottom of the main content, flush-right (`justify-end`), 32 pt margin-top.
- **Label:** "הוספת מותג חדש"
- **Trailing icon:** `add` Material Symbol, 24 pt.
- **Style:** `AppColors.primary` `#00478D` fill, `#FFFFFF` text, `BorderRadius.circular(12)`, padding `px-24 py-12` (lg horizontal, 12 pt vertical), `box-shadow: lg`. Inter SemiBold 14 pt (`label-bold`).
- **Behavior:** opens the brand add/edit form (bottom sheet or new route — see §5).
- **Note:** unlike other screens' full-width `primary-button`, this button is right-aligned and sized to content + icon. It shares the same visual token as `primary-button` standard variant (see _components-glossary.md#primary-button) but is NOT full-width here. Implement as a `FilledButton` with `icon` variant rather than the shared `PrimaryButton` wrapper if that wrapper forces full-width.

---

## 5. States & interactions

### 5.1 List — loaded state (default)
Brands list renders with all fetched brands. Search field is empty. Stats card shows total registered count and verified percentage. This is the Stitch-depicted state.

### 5.2 List — loading state
- Show `CircularProgressIndicator(color: AppColors.primary)` centred in the list area while fetching from Supabase.
- Stats card count: "—" (em dash) while loading.
- Search field is present but disabled (or functional against an empty list) until load completes.

### 5.3 List — empty state
- No brand rows rendered.
- Show centred illustration + text: headline "אין מותגים רשומים" (Public Sans SemiBold 18 pt, `#1F2937`), body "הוסף מותג חדש כדי להתחיל" (Inter Regular 14 pt, `#424752`). Icon: `branding_watermark`, 48 pt, `#9CA3AF`.
- "הוספת מותג חדש" button remains visible.

### 5.4 Search — active state
- As the admin types in the search field, the brand list filters in real time (client-side filter on already-fetched brands list, OR server-side query on each keystroke with debounce ~300 ms).
- No matching results: inline "לא נמצאו מותגים עבור «…»" message replaces the list (same empty-state style, shorter copy).
- Clear search: if text is present, an `×` (`close`) icon appears trailing (left) of the search input to clear it.

### 5.5 Toggle — tap interaction
- Admin taps the toggle to flip verified ↔ unverified.
- **Optimistic update:** toggle animates immediately. If the Supabase call fails, it reverts and shows a `SnackBar` error: "שגיאה בעדכון סטטוס המותג".
- Success: toggle stays in new state; "עדכון אחרון" timestamp updates to "עכשיו" / "לפני רגע" (or refetches the brand record).

### 5.6 Edit — tap interaction
- Admin taps the `edit` icon on a brand row.
- Opens an **edit bottom sheet** (or a separate route) pre-populated with the brand's data: name, logo URL, verified status, notes.
- Bottom sheet contains a "שמור שינויים" primary button and a "ביטול" text button.
- On save: refreshes the brand row in the list.

### 5.7 Add — tap interaction
- Admin taps "הוספת מותג חדש".
- Opens the **brand add form** (same bottom sheet layout as edit, but empty fields).
- Fields: brand name (required), logo URL (optional), verified toggle (defaults OFF), notes (optional).
- On submit: row added to top of list; stats counter increments.

### 5.8 Delete
- Not exposed directly in the list row (no delete icon in Stitch). Delete is accessed via the edit bottom sheet — a "מחק מותג" destructive text button (red `#DC2626`, `Inter SemiBold 14 pt`) at the bottom of the sheet.
- Tapping shows a `AlertDialog` confirmation: "האם אתה בטוח שברצונך למחק את המותג?" with "מחק" (red filled) / "ביטול" actions.

### 5.9 Admin gate — unauthorised access
- If the current user is not an admin (see §6), the screen body is replaced with an access-denied view: `Icons.lock` 48 pt `#9CA3AF`, "הגישה מוגבלת למנהלים בלבד" (Inter Regular 16 pt, `#424752`). No action button shown.

---

## 6. Data & controller contract

### 6.1 Supabase table: `brands`

The screen reads from and writes to the `brands` table (see `supabase/schema.sql`). Expected columns used by this screen:

| Column | Type | Description |
|---|---|---|
| `id` | `uuid` | Primary key |
| `name` | `text` | Brand name (Hebrew/English) |
| `logo_url` | `text?` | URL to brand logo asset |
| `is_verified` | `boolean` | Admin-verified trust flag (maps to toggle) |
| `last_updated` | `timestamptz` | Used to display relative "עדכון אחרון" text |
| `notes` | `text?` | Admin notes (edit form only) |

The stats card "מותגים רשומים" count = `SELECT COUNT(*) FROM brands`. The progress bar fill = `(COUNT(*) WHERE is_verified = true) / COUNT(*) * 100`.

### 6.2 Controller / service

- `BrandService` (new, analogous to `ProductService` in `app/lib/services/`) receives a `SupabaseClient` in its constructor.
- Key methods:
  - `fetchBrands({String? nameFilter})` → `List<Brand>` — fetches all brands, optionally filtered by name (ILIKE).
  - `updateVerification(String brandId, bool isVerified)` → `void` — patches `is_verified` and `last_updated`.
  - `saveBrand(Brand brand)` → `Brand` — upsert (insert if `id` is null, update otherwise).
  - `deleteBrand(String brandId)` → `void` — deletes the brand record.

### 6.3 State management

Following project conventions (see CLAUDE.md §Architecture), the screen uses `StatefulWidget` with local state:
- `List<Brand> _brands` — full fetched list.
- `String _searchQuery` — current filter string.
- `bool _isLoading` — controls loading indicator.
- Profile/admin-gate check is passed down from `AppShell` via a `bool isAdmin` prop or read from `SharedPreferences` (key `is_admin`).

### 6.4 Admin-only gating

The MVP has no auth layer. Admin gating is currently a **design intent only**. Interim implementation options:
- Hard-code a flag in SharedPreferences (`is_admin = true/false`) set via a hidden gesture or a separate dev/debug toggle.
- Gate the drawer entry "ניהול מותגים" visibility on the same flag — admin-only users see the entry; others do not.
- The screen itself should also enforce the gate (§5.9) in case of direct navigation.

---

## 7. Open questions / design-vs-app deltas

### 7.1 App title string: "בדיקת אלרגנים" vs. "בטוח לאכול"
The Stitch HTML renders the app-bar brand text as **"בדיקת אלרגנים"** (Public Sans Black 20 pt, `#005EB8`). The glossary canonical app-bar brand text is **"בטוח לאכול"** (Inter Medium 16 pt, `#00478D`). This screen uses a different brand name string and a bolder weight. This is likely a Stitch artefact — the implementation should use the canonical "בטוח לאכול" from the glossary.

### 7.2 Bottom-nav tab set: stale Stitch artefact (DD-4 applies)
The Stitch HTML renders a 4-tab bottom nav: בית / סריקה / **הוספה** / **הגדרות** (tabs 3 and 4 are "הוספה" with `add_circle` and "הגדרות" with `settings`). Per DD-2 / DD-4, the canonical bottom nav is בית / סריקה / קהילה / **מועדפים**. The "הוספה" and "הגדרות" tabs are stale Stitch artifacts and must NOT be implemented. See _components-glossary.md#bottom-nav.

### 7.3 `admin_brands_screen.dart` not yet created
The mapped file `app/lib/screens/admin_brands_screen.dart` does not exist in the current codebase. The screen and its `BrandService` are net-new additions.

### 7.4 Logo source — resolved (URL + initial-letter fallback)
Logo image is fetched from `brands.logo_url`. If null or the network image
fails, render the brand's Hebrew first character (e.g. "ת" for תנובה) in
Inter SemiBold 22 pt `#00478D` on a `#EBF4FF` 56×56 pt circle. No
`Icons.store` placeholder — the initial-letter chip is the fallback. Admin
can paste a new `logo_url` in the brand edit form (§7.7) to update.

### 7.5 "הוספת מותג חדש" button: right-aligned vs. full-width
The Stitch screen shows the add-brand button right-aligned and auto-sized. This diverges from the shared `primary-button` pattern (which is full-width within margins). The implementation may use a right-aligned `FilledButton.icon(...)` rather than the shared `PrimaryButton` component. See §4.6.

### 7.6 Stats progress bar semantics unclear
The stats card shows a progress bar at 85% fill. It is unclear whether 85% is literal (85 of 124 brands verified) or illustrative. The implementation must compute this dynamically from the brands table. No static value.

### 7.7 Brand add/edit form — resolved (modal bottom sheet)
Use a `showModalBottomSheet`-driven `BrandFormSheet` (new sub-spec
`admin-brand-form.md` added in this batch). Both "הוספת מותג חדש" and the
per-row edit icon open the same sheet — empty for add, pre-populated for edit.
Sheet hosts: brand name, logo URL, verified toggle, notes, plus a destructive
"מחק מותג" text button (edit-mode only). On save: `BrandService.saveBrand(...)`
upserts; on delete: confirmation dialog → `BrandService.deleteBrand(id)`.

Resolved per _design-decisions.md#dd-8: the canonical app-bar brand text is **"בטוח לאכול"** (Inter Medium 16 pt, `#00478D`). The "בדיקת אלרגנים" string rendered in this screen's Stitch HTML is a Stitch artifact. Implement "בטוח לאכול"; note the delta in §7.1 above.

### 7.8 Implementation deltas — verification pass 2026-05-24 <!-- DIVERGED -->

Spec-parity check of `app/lib/screens/admin_brands_screen.dart`.
**Result: Screen exists and core structure is in place, but multiple layout, visual, and interaction gaps remain.** Verified = ⚠. No code change this pass (documented only).

Aligned: `BrandService` injection, `_isLoading` CircularProgressIndicator, edit icon opens `BrandFormSheet`, add-brand FAB triggers `showBrandFormSheet`, `BorderRadius.circular(12)` on row cards, toggle present, error SnackBar on load failure.

| # | Spec requirement | Current code |
|---|---|---|
| TB1 | AppBar title: absent from spec (page header block carries the H1 "ניהול מותגים מאושרים"); AppBar is not the title location in spec layout | `AppBar` renders `Text('ניהול מותגים')` using `AppTypography.h3` — wrong title string (missing "מאושרים") and wrong placement (spec has no branded AppBar title; the H1 title lives in the page header block below the AppBar) |
| TB2 | AppBar: "בטוח לאכול" brand bar with menu icon + avatar (canonical per DD-8; shared chrome) | `AppBar` has no brand-bar text, no leading menu icon to open a drawer — uses generic back-navigation only; `drawer:` is set to `NavigationDrawer()` but via the left-side `drawer:` not `endDrawer:` (RTL should use `endDrawer`) |
| TB3 | Page header block: H1 "ניהול מותגים מאושרים" (Public Sans 700, 30 pt, `#00478D`), subtitle "עדכן ואמת מותגים במאגר הנתונים של הקליניקה" (Inter Regular 16 pt, `#424752`), 32 pt margin-bottom | No page header block exists in the body; screen goes directly to search + stats row |
| TB4 | Search + Stats **bento** (2-column grid): search card col-span-2, stats card col-span-1, card style: white `#FFFFFF`, `BorderRadius.circular(12)`, shadow `rgba(0,0,0,0.05)`, 1 pt border `#EDEEEF`, 16 pt padding; search label "חיפוש מותג", placeholder "הקלד שם מותג (לדוגמה: שטראוס)" | `SearchInput` widget + `_buildStats()` stacked vertically (not a 2-column grid); search placeholder is "חפש מותג..." (wrong copy); no card container around either widget; stats is a plain `Row` with icon + count text, not a card with progress bar |
| TB5 | Stats card: count "124" (Public Sans SemiBold 20 pt, `#00478D`) + label "מותגים רשומים" (Inter Medium 12 pt), progress bar 6 pt height showing verified percentage | `_buildStats()` renders a small `Row` with `Icons.business` + `'${_brands.length} מותגים רשומים'` in `labelSm`; no progress bar; count style is `labelSm` not `Public Sans SemiBold 20 pt` |
| TB6 | Brand row card: white `#FFFFFF` fill, 8 pt shadow, 1 pt border `#EDEEEF`, 24 pt padding | Row container uses `AppColors.surfaceContainer` fill (not white), no shadow, border uses `AppColors.outlineVariant` (not `#EDEEEF`), margin `AppSpacing.sm`, padding from `ListTile` defaults |
| TB7 | Logo thumbnail: 56 × 56 pt, white fill container, 8 pt border-radius, 1 pt border `#EDEEEF`, 8 pt padding inside; fallback = Hebrew initial letter (e.g. "ת") Inter SemiBold 22 pt `#00478D` on `#EBF4FF` 56×56 pt circle (per §7.4) | Thumbnail is 40 × 40 pt (not 56 pt); fallback renders `Icons.store` at 20 pt in `onSurfaceVariant` color — violates §7.4 which explicitly prohibits `Icons.store` and requires initial-letter chip |
| TB8 | Brand name: Public Sans SemiBold 20 pt / `#191C1D` (`h3` level); metadata line: "עדכון אחרון: …" or "ממתין לבדיקת רכיבים" (Inter Medium 12 pt, `#424752`) | `ListTile.title` uses `AppTypography.bodyMd` weight `w500` for brand name (not `h3`/20 pt Public Sans SemiBold); no metadata subtitle line rendered (no "עדכון אחרון" / "ממתין לבדיקת רכיבים") |
| TB9 | Verification toggle: `activeColor` should map to `AppColors.primary` `#00478D`; `onChanged` must call `BrandService.updateVerification()` optimistically (§5.5) | `Switch` has `onChanged: null` — toggle is **non-functional** / read-only; no optimistic update, no revert-on-error SnackBar |
| TB10 | "הוספת מותג חדש" button: `FilledButton.icon`, right-aligned, NOT a FAB; `AppColors.primary` fill, `BorderRadius.circular(12)`, Inter SemiBold 14 pt, trailing `add` icon, 32 pt margin-top (§4.6) | Implemented as `FloatingActionButton.extended` — spec explicitly calls for a right-aligned `FilledButton.icon`, not a FAB |
| TB11 | Admin-gate access denied view (§5.9): `Icons.lock` 48 pt, "הגישה מוגבלת למנהלים בלבד" when not admin | No admin-gate check anywhere in the screen; screen renders for any caller |
| TB12 | Empty state (§5.3): illustration + "אין מותגים רשומים" headline + "הוסף מותג חדש כדי להתחיל" body | `ListView.builder` with `itemCount: 0` renders empty — no empty state widget |
| TB13 | Real-time search filter (§5.4): brand list filters as user types; clear (×) icon when text present | `_searchController` is created but its value is never used to filter `_brands`; no listener attached; search is non-functional |
| TB14 | Background: `#F8F9FA` (`AppColors.surface`) | `Scaffold.backgroundColor: AppColors.surfaceContainerLow` — different token |

**Priority / quick wins:** TB9 (toggle `onChanged: null` makes the core feature non-functional — one-line fix to wire `updateVerification`), TB13 (search field entirely disconnected — add a listener or `onChanged` to filter `_brands`). TB3 (missing page header), TB7 (wrong logo fallback icon per §7.4), and TB10 (FAB vs. FilledButton) are the next-highest-impact visual divergences.
