# Settings & Profile / הגדרות ופרופיל
Stitch screen: projects/16588854804615693446/screens/3a2bc2f1aac1444886d44def38b72bc4
Maps to: app/lib/screens/settings_screen.dart

---

## 1. Purpose & context

This screen is the single-pane hub where the user views and edits their identity
information (name, email, age), manages their allergen profile, controls app
behaviour preferences, accesses secondary features (contribution history, help,
about), and signs out.

**Entry point:** The screen is reached via the navigation drawer (`nav-drawer-user`) —
per _design-decisions.md#dd-2, Settings is NOT a bottom-nav tab. The drawer
provides a "הגדרות" link that pushes `settings_screen.dart` onto the navigator
stack. The current app implementation incorrectly places Settings as bottom-nav
tab 4 (see §7.1).

**Exit paths:**
- Back arrow / system-back → returns to the screen that opened the drawer.
- "התנתק מהחשבון" logout button → clears local profile and navigates to
  onboarding or a signed-out state.
- Any menu row → navigates to the corresponding sub-screen (manage allergies,
  app preferences, contribution history, help center, about).

---

## 2. Visual layout breakdown

Screen dimensions from Stitch: 780 × 2318 px (tall scrollable mobile layout).
The canonical 390 pt logical-pixel width is assumed (2× density).

```
┌─────────────────────────────────────────┐
│  App bar (56 pt)                        │
│  "בטוח לאכול" logo  ·  hamburger + avatar│
├─────────────────────────────────────────┤
│  Profile block (≈ 200 pt)               │
│    Avatar (64 pt circle, verified badge)│
│    Name: ישראל ישראלי (Public Sans Bold)│
│    Email: israel.i@example.com (Inter)  │
│    Scan-count chip: 24 / סריקות השבוע  │
├─────────────────────────────────────────┤
│  Product-filter section (≈ 112 pt)      │
│    Section label: רמת סינון מוצרים      │
│    Three horizontal filter-level chips  │
│      לא בטוח  ·  בטוח חלקית  ·  בטוח לחלוטין│
├─────────────────────────────────────────┤
│  Menu list (≈ 280 pt)                   │
│    Row: נהל אלרגיות                     │
│    Row: העדפות אפליקציה                 │
│    Row: היסטוריית תרומות                │
│    Row: מרכז עזרה                       │
│    Row: אודות                           │
├─────────────────────────────────────────┤
│  Logout button (full-width, 48 pt)      │
│    "התנתק מהחשבון"                      │
├─────────────────────────────────────────┤
│  Bottom nav (56 pt + safe-area)         │
│  [see _components-glossary.md#bottom-nav]│
└─────────────────────────────────────────┘
```

Background: `#F9FAFB` (near-white page surface, `AppColors.background` token TBD).
All sections are contained in a scrollable `SingleChildScrollView` / `ListView`
body (the screen is taller than the viewport).

---

## 3. Component inventory

| # | Component | Glossary ref | Screen-specific? |
|---|---|---|---|
| 1 | App bar (brand-bar variant, home logo + hamburger + avatar) | see _components-glossary.md#app-bar | No — shared |
| 2 | Profile block (avatar, name, email, scan-count chip) | — | Yes — §4.1 |
| 3 | Product-filter level selector (3-segment chip row) | — | Yes — §4.2 |
| 4 | Settings menu row (icon + label + chevron) | — | Yes — §4.3 |
| 5 | Logout button | — | Yes — §4.4 |
| 6 | Bottom navigation bar | see _components-glossary.md#bottom-nav | No — shared (delta noted §7.2) |

No `status-pill`, `allergen-chip`, `primary-button`, or `wizard-chrome` appear
on this screen.

---

## 4. Sub-components / element design

### 4.1 Profile block

A vertically centred card-like block at the top of the scrollable body.

**Container**
- Background: `#FFFFFF`, border-radius 16 pt, `BoxShadow` subtle (elevation ≈ 1).
- Margin: 16 pt horizontal, 16 pt top.
- Padding: 24 pt vertical, 16 pt horizontal.
- Layout: `Column`, `crossAxisAlignment: CrossAxisAlignment.center`.

**Avatar**
- Circular image widget, diameter 64 pt.
- Displays the user's profile photo (network image or placeholder).
- A small `verified_user` (shield-check) badge is overlaid at the bottom-right of
  the circle: diameter ≈ 20 pt, background `AppColors.primary` `#00478D`, icon
  white 12 pt.
- An edit pencil icon (`edit` Material icon, 16 pt) appears on the avatar,
  indicating the avatar is tappable to update the photo.

**Name**
- Text: ישראל ישראלי (placeholder; real value from `UserProfile.displayName`).
- Style: Public Sans Bold 20 pt, `#1F2937` (`AppTypography.headlineSmall` token TBD).
- Alignment: `TextAlign.center`.
- Below avatar, gap 8 pt.

**Email**
- Text: israel.i@example.com (placeholder; real value from `UserProfile.email`).
- Style: Inter Regular 14 pt, `#6B7280` (`AppColors.onSurfaceVariant`).
- Alignment: `TextAlign.center`.
- Below name, gap 4 pt.

**Weekly-scan count chip**
- Container: `#EBF4FF` background, border-radius 20 pt, padding
  `EdgeInsets.symmetric(horizontal: 16, vertical: 6)`.
- Row: number label (Inter Bold 16 pt, `#00478D`) + space + unit label
  (Inter Regular 12 pt, `#374151` — "סריקות השבוע").
- This is a read-only display metric, not interactive.
- Below email, gap 12 pt.

**Edit profile entry point**
- A small outlined `TextButton` or `InkWell` row below the chip, label
  "ערוך פרופיל" (Inter Medium 13 pt, `#00478D`), with a `edit` icon 14 pt.
- Tapping opens a profile-edit modal or sub-screen (not designed in this Stitch
  screen — out of scope).

---

### 4.2 Product-filter level selector (רמת סינון מוצרים)

A horizontal three-segment row that controls which products are shown or
highlighted based on their safety verdict.

**Container / section**
- Section header: "רמת סינון מוצרים" — Inter SemiBold 13 pt, `#374151`,
  RTL-aligned, 16 pt horizontal margin.
- Below header, gap 8 pt.
- Segment row is a `Row` with `mainAxisAlignment: MainAxisAlignment.spaceBetween`
  inside the same horizontal margins.

**Three segment chips** (equal-width, `Expanded` or fixed ~108 pt each)

| Position (RTL right→left) | Hebrew label | Meaning | Active style | Inactive style |
|---|---|---|---|---|
| 1 (rightmost) | "לא בטוח" | Contains allergens / Avoid | Background `#FEE2E2`, border `#DC2626`, text `#991B1B` Inter SemiBold 12 pt | Background `#FFFFFF`, border `#E5E7EB`, text `#6B7280` Inter Regular 12 pt |
| 2 (centre) | "בטוח חלקית" | May-contain / Caution | Background `#FEF9C3`, border `#CA8A04`, text `#A16207` Inter SemiBold 12 pt | same inactive as above |
| 3 (leftmost) | "בטוח לחלוטין" | Fully safe / no traces | Background `#DCFCE7`, border `#16A34A`, text `#15803D` Inter SemiBold 12 pt | same inactive as above |

- Each chip: border-radius 20 pt, padding `EdgeInsets.symmetric(horizontal: 8, vertical: 6)`,
  border 1.5 pt, `TextAlign.center`.
- Only one chip is active at a time (single-select).
- The design screenshot shows all three visible; the active state is inferred
  from semantic colours matching the `status-pill` palette. The exact active chip
  in the Stitch screenshot is not definitively readable at this resolution —
  implementation should default to "בטוח חלקית" active (most permissive common
  case).
- Full Hebrew labels from HTML:
  - "לא בטוח מכיל אלרגנים" (long form) — truncate to "לא בטוח" on chip,
    or wrap to 2 lines at small widths.
  - "בטוח חלקית עשוי להכיל" — truncate to "בטוח חלקית".
  - "בטוח לחלוטין ללא חשש עקבות" — truncate to "בטוח לחלוטין".

---

### 4.3 Settings menu row

Repeated five times. A single tappable list tile navigating to a sub-screen.

**Structure** (`ListTile` or custom `InkWell` row)
- Height: 56 pt.
- Background: `#FFFFFF`.
- Divider: 1 pt `#E5E7EB` below each row (or `ListView.separated`).
- RTL layout (right → left):
  - **Leading (right):** Icon in a 40 × 40 pt circle with a light tinted
    background (icon-specific tint, see table below). Icon 20 pt.
  - **Centre:** Label text — Inter Medium 15 pt, `#1F2937`.
  - **Trailing (left):** `chevron_left` icon 20 pt, `#9CA3AF` (RTL "forward"
    chevron pointing left).
- Pressed state: `InkWell` splash, background `#F3F4F6`.

**Five rows (RTL reading order, top to bottom):**

| Row | Hebrew label | Material icon | Icon bg tint |
|---|---|---|---|
| 1 | נהל אלרגיות | `medical_services` | `#EBF4FF` (blue tint) |
| 2 | העדפות אפליקציה | `settings_suggest` | `#F3F4F6` (grey tint) |
| 3 | היסטוריית תרומות | `volunteer_activism` | `#F0FDF4` (green tint) |
| 4 | מרכז עזרה | `help_center` | `#FFF7ED` (amber tint) |
| 5 | אודות | `info` | `#F3F4F6` (grey tint) |

**Menu list container**
- Background: `#FFFFFF`, border-radius 16 pt, `BoxShadow` subtle.
- Margin: 16 pt horizontal, 12 pt vertical.

**"נהל אלרגיות" row special behaviour**
- Tapping opens the allergen-selection flow (same allergen catalog used in
  onboarding). This is the primary allergen-edit entry point from Settings.
- The row may show a secondary count badge ("5 אלרגנים נבחרו") to the left
  of the chevron, but this detail is not confirmed from the Stitch screenshot.

---

### 4.4 Logout button

A full-width prominent button at the bottom of the scrollable content, above the
bottom nav.

**Structure**
- Flutter: `OutlinedButton` or custom container styled as a filled danger-light
  button.
- Width: full-width within 16 pt horizontal margins.
- Height: 48 pt, border-radius 12 pt.
- Background: `#FEF2F2` (light red, danger-surface).
- Border: 1.5 pt `#DC2626`.
- Icon: `logout` Material icon, 20 pt, `#DC2626`, RTL-leading (right side).
- Label: "התנתק מהחשבון" — Inter SemiBold 14 pt, `#DC2626`.
- Margin: 16 pt horizontal, 16 pt top, 24 pt bottom (above bottom nav safe area).
- Pressed state: background `#FEE2E2`.
- Tapping triggers a confirmation dialog before clearing the local profile
  (SharedPreferences `has_completed_onboarding = false`, allergen IDs cleared)
  and navigating to `OnboardingScreen`.

---

## 5. States & interactions

### 5.1 Default / loaded state
- Profile block shows current `UserProfile` values (name, email, age/scan-count).
- Filter-level selector shows the currently persisted filter level (single chip
  active).
- Menu rows are all tappable.
- Logout button is visible and enabled.

### 5.2 Avatar edit interaction
- Tapping the avatar (or the edit icon overlay) opens a bottom sheet or
  image-picker dialog to update the profile photo.
- Implementation note: MVP stores avatar locally (SharedPreferences path or
  base64); no Supabase upload in MVP scope.

### 5.3 Filter-level selection
- Tapping a chip sets it as the sole active chip; the previously active chip
  reverts to inactive styling.
- Change is persisted immediately to `SharedPreferences` key
  `product_filter_level` (enum value: `avoid_only` | `caution_and_above` |
  `safe_only`).
- The home dashboard and search results re-read this preference on next load.

### 5.4 "נהל אלרגיות" navigation
- Navigator push to the allergen-management sub-screen (shares UI with
  onboarding allergen-selection step).
- On return, `UserProfile.selectedAllergenIds` is updated and bubbled up via
  `ValueChanged<UserProfile>` to `AppShell`, which persists to SharedPreferences.

### 5.5 Menu row navigation
- Each row is a standard navigator push:
  - "העדפות אפליקציה" → app-preferences screen (not yet specced).
  - "היסטוריית תרומות" → contribution history screen (not yet specced).
  - "מרכז עזרה" → help center (web view or static screen).
  - "אודות" → about screen (version info, licences).

### 5.6 Logout confirmation dialog
- An `AlertDialog` appears:
  - Title: "התנתק מהחשבון?" (Public Sans SemiBold 16 pt).
  - Body: "כל הגדרות הפרופיל ישמרו במכשיר." (Inter Regular 14 pt, `#374151`).
  - Actions (RTL row):
    - "ביטול" — `TextButton`, `#374151`.
    - "התנתק" — `TextButton`, `#DC2626`.
- Confirming "התנתק" clears local profile data and navigates to onboarding.

### 5.7 Error / no-profile state
- If `UserProfile` is null or not yet loaded, the profile block shows skeleton
  placeholders (`shimmer` or grey `Container` blocks).
- This should be transient (SharedPreferences is synchronous after first load).

---

## 6. Data & controller contract

### 6.1 UserProfile fields consumed by this screen

| Field | Type | Display location |
|---|---|---|
| `displayName` | `String` | Profile block — name label |
| `email` | `String?` | Profile block — email label |
| `selectedAllergenIds` | `List<String>` | Read by "נהל אלרגיות" sub-screen; count badge (TBD) |
| `weeklyScansCount` | `int?` | Profile block — scan-count chip (token TBD — may be derived, not stored) |
| `avatarUrl` | `String?` | Profile block avatar image |

`UserProfile` is the existing model read from / written to SharedPreferences by
`AppShell`. `settings_screen.dart` receives it as a constructor parameter and
emits updates via `ValueChanged<UserProfile> onProfileChanged`.

### 6.2 SharedPreferences keys

| Key | Type | Used for |
|---|---|---|
| `display_name` | String | User name |
| `email` | String | User email |
| `selected_allergen_ids` | `List<String>` (JSON) | Allergen profile |
| `has_completed_onboarding` | bool | Set to `false` on logout to re-trigger onboarding |
| `product_filter_level` | String (enum value) | Product-filter level selector |
| `avatar_path` | String? | Local path or base64 for avatar (MVP) |

### 6.3 Allergen catalog
- The allergen catalog is fetched from Supabase once at startup by `AppShell`
  and passed down. `SettingsScreen` does not re-fetch; it receives the catalog
  list as a constructor parameter and passes it to the allergen-management
  sub-screen.

### 6.4 No authentication / no server writes
- MVP has no authentication. There is no Supabase user record to update.
- All writes are to SharedPreferences only.
- "התנתק" (logout) means clearing local preferences, not an OAuth signout.

### 6.5 Controller pattern
- `SettingsScreen` is a `StatefulWidget`.
- Local `_filterLevel` state mirrors the persisted value and drives the
  filter-chip selected state.
- On `initState`, read `product_filter_level` from SharedPreferences into
  `_filterLevel`.
- On chip tap, update local state + write to SharedPreferences (no debounce
  needed — immediate).
- Profile changes (name, email, avatar) are emitted via `onProfileChanged`
  after any edit sub-screen returns.

---

## 7. Open questions / design-vs-app deltas

### 7.1 Delta: Settings is currently a bottom-nav tab (app) vs. drawer-only (design)
The current app `MainContainer` places Settings as index 3 bottom-nav tab. Per
_design-decisions.md#dd-2 the canonical design has Settings reachable only from
the navigation drawer. The app must be realigned: remove the Settings tab,
replace it with Favorites (`מועדפים`), and route Settings through the drawer.
This is a **known realignment** (DD-2), not a new flag.

### 7.2 Delta: Bottom nav — Settings tab active in Stitch, Favorites in canon
The Stitch screenshot shows the "הגדרות" (Settings) icon active in the bottom
nav. Per DD-2 and DD-4, this is a stale Stitch artifact. The canonical bottom
nav (בית/סריקה/קהילה/מועדפים) applies. Implementation must not follow the
Stitch bottom-nav here.

### 7.3 weeklyScansCount source — resolved (local rolling counter)
Stored in SharedPreferences as a rolling weekly counter under key
`weekly_scans_count`. Incremented on each scan completion; reset to 0 by a
local timestamp comparison against `weekly_scans_week_start` (every Sunday
00:00 local). No Supabase dependency. Profile block reads from
`UserProfile.weeklyScansCount` (added to the model). If null → render "0".

### 7.4 Product-filter default — resolved (בטוח חלקית)
Default value on first launch = `caution_and_above` ("בטוח חלקית" active).
Persists to SharedPreferences key `product_filter_level` on first chip tap.

### 7.5 Allergen-management sub-screen — resolved (reuses onboarding step 1)
The "נהל אלרגיות" row pushes `OnboardingAllergenSelection`-style grid as a
sub-screen (`AllergenManagementScreen` — new file
`app/lib/screens/allergen_management_screen.dart`). It reuses the 3-col grid +
selection cards (canonical per `_components-glossary.md#allergen-chip` Variant
C), but without the brand header / progress bar / disclaimer. Header instead:
detail-bar app-bar with title "נהל אלרגיות" + back arrow. Continue button
becomes "שמור" (Save) and persists changes immediately. See
`allergen-management.md` (new spec) for the full description.

### 7.6 Avatar edit MVP scope — resolved (local-only)
MVP scope: tap avatar → image picker → store as base64 in SharedPreferences
under `avatar_data`. No Supabase upload. The edit pencil icon stays visible on
the avatar; tapping it (or tapping the avatar itself) opens an
`ImagePicker.pickImage(source: ImageSource.gallery)` flow (camera optional on
mobile). Web platform: gallery only.

### 7.7 Filter chip labels — resolved (long form with 2-line wrap)
Render the full Stitch labels: "לא בטוח מכיל אלרגנים", "בטוח חלקית עשוי
להכיל", "בטוח לחלוטין ללא חשש עקבות". Each chip wraps to 2 lines at small
widths (use `Text` with `maxLines: 2`, `TextAlign.center`). The chip height
grows to ~52 pt to accommodate two-line text; padding stays
`EdgeInsets.symmetric(horizontal: 8, vertical: 6)`. This overrides the prior
spec note about truncation.

### 7.8 Implementation deltas — verification pass 2026-05-24 <!-- DIVERGED -->

Spec-parity check of `app/lib/screens/settings_screen.dart`.
**Result: diverged; the filter selector is non-functional.** Verified = ⚠.
No code change this pass (documented only). App-bar + bottom-nav are
`MainContainer`'s concern (DD-2 tab-vs-drawer realignment, §7.1/§7.2).

Aligned: white profile card (radius 16 + shadow), name/email from profile,
avatar edit pencil → `ProfileEditSheet`, menu list in a white card, "נהל
אלרגיות" → `AllergenManagementScreen`, logout via `showLogoutDialog` clearing
the profile.

| # | Spec requirement | Current code |
|---|---|---|
| ST1 | Avatar 64 pt + `verified_user` shield badge overlay (§4.1) | 96 pt avatar, edit pencil only, no verified badge |
| ST2 | Scan chip: `#EBF4FF` pill (radius 20), value from `weeklyScansCount` (§7.3) | ✅ **REMOVED 2026-06-09** — hardcoded "24" removed; chip hidden until `UserProfile.weeklyScansCount` field + rolling counter implemented per §7.3 |
| ST3 | "ערוך פרופיל" text-button entry below chip (§4.1) | only the avatar pencil |
| ST4 | Section header "רמת סינון מוצרים" (§4.2) | "הצג רק מוצרים בטוחים" + subtitle |
| ST5 | 3 filter chips use status-pill palette (red/amber/green), single-select (§4.2) | iOS-style segmented control, plain white/grey, no semantic colours |
| ST6 | Filter selection persists to `product_filter_level` (§5.3) | ✅ **FIXED 2026-06-09** — `_SettingsScreenState` tracks `_userProfile` locally; `_onFilterSelected` updates local state + calls `widget.onProfileUpdated`; profile/email/name reflect immediately after edit sheet closes |
| ST7 | Use `AppTypography` tokens | raw `TextStyle(fontSize: 11/9)` literals on filter labels |
| ST8 | 5 menu rows: נהל אלרגיות / העדפות אפליקציה / היסטוריית תרומות / מרכז עזרה / אודות (§4.3) | extra 6th row "נהל מותגים" (admin); spec puts admin in the admin drawer |
| ST9 | Per-row icon tints (blue/grey/green/amber/grey) (§4.3) | only "נהל אלרגיות" tinted blue; all others grey |
| ST10 | Trailing `chevron_left` (RTL forward) (§4.3) | `Icons.chevron_right` |
| ST11 | Logout = filled light-red `#FEF2F2` + 1.5 pt `#DC2626` border (§4.4) | `OutlinedButton` (transparent fill, faint border) |
| ST12 | "העדפות אפליקציה" / "היסטוריית תרומות" / "אודות" navigate (§5.5) | `onTap: () {}` no-ops (destinations are Tier 3, unbuilt) |

**Status 2026-06-09:** ST6 resolved (filter now functional + persisted). ST2 placeholder removed. ST3/ST4/ST5/ST7–ST11 still outstanding; ST12 expected until Tier 3 screens exist.
