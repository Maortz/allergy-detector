# User Navigation Drawer / תפריט ניווט (משתמש)
Stitch screen: projects/16588854804615693446/screens/6e8f8bcbe71548b0a7f1bf6920de7343
Maps to: app/lib/screens/drawer_user_screen.dart

## 1. Purpose & context

The user navigation drawer is a right-anchored slide-in panel opened from the
hamburger menu icon on the app bar (see `_components-glossary.md#app-bar`). It
gives non-admin users access to their profile, activity history, saved items,
personal reviews, help, about, and a logout action.

Per `_design-decisions.md#dd-2`, **Settings is reached from this drawer**, not
from the bottom navigation bar. The drawer is the canonical entry point for any
destination that is not one of the four main bottom-nav tabs (בית / סריקה /
קהילה / מועדפים).

The drawer slides in **from the right** edge of the screen (RTL convention).
The rest of the screen dims with a scrim. Tapping the scrim or swiping right
closes the drawer.

## 2. Visual layout breakdown

The drawer occupies roughly 80 % of screen width, anchored to the right edge.
Top → bottom structure:

```
┌─────────────────────────────────────┐  ← right edge of screen
│  HEADER                             │
│    avatar (circular, ~56 pt)        │
│    "שלום, משתמש"   (bold, ~18 pt)  │
│    "בטוח לאכול"    (small, muted)   │
├─────────────────────────────────────┤
│  MENU LIST                          │
│    row: פרופיל          [active]    │
│    row: היסטוריית סריקה            │
│    row: מוצרים שמורים              │
│    row: ביקורות שלי                │
│    ────  divider ────               │
│    row: מרכז עזרה                  │
│    row: אודות                      │
├─────────────────────────────────────┤
│  FOOTER                             │
│    [  ← התנתקות  ]  salmon button  │
│    "אלרגיות בצלחת"        v1.0.0   │
└─────────────────────────────────────┘
```

**Background:** `#FFFFFF` (white surface).  
**Scrim:** semi-transparent black overlay behind the drawer, ~40–50 % opacity.  
**Drawer width:** ~80 % of screen width (Flutter `Drawer` default is 304 pt;
use `MediaQuery.of(context).size.width * 0.80` or the Material default).  
**Corner radius:** left edge of drawer has a 0 pt radius (flush to screen edge
on the right); the left side (open side) could carry a subtle 12–16 pt radius
— not confirmed from screenshot; default Flutter `Drawer` shape applies.  
**Shadow:** left-side `BoxShadow` to separate drawer from scrim.

## 3. Component inventory

Every drawer row, in RTL reading order (top → bottom), with exact Hebrew label,
icon, and destination:

| # | Hebrew label | Icon (Material) | Destination / action | Notes |
|---|---|---|---|---|
| H | Header area | — | — | Non-navigating; displays user identity |
| 1 | **פרופיל** | `person` (person/account outline) | `ProfileScreen` (or `UserProfileScreen`) | Active/selected highlight on entry; this is the identity-management destination |
| 2 | **היסטוריית סריקה** | `history` (clock with arrow) | `ScanHistoryScreen` | Full list of previously scanned products |
| 3 | **מוצרים שמורים** | `bookmark_border` or `bookmark` | `SavedProductsScreen` | User's bookmarked/saved product list |
| 4 | **ביקורות שלי** | `photo_library` or `rate_review` | `MyReviewsScreen` | Products the user has reviewed/contributed |
| — | *(divider)* | — | — | Horizontal `Divider` separating utility items from info items |
| 5 | **מרכז עזרה** | `help_outline` | `HelpCenterScreen` or external help URL | Help/FAQ destination |
| 6 | **אודות** | `info_outline` | `AboutScreen` | App version, credits, legal |
| F | **התנתקות** | `logout` or `exit_to_app` (leading, RTL) | Logout action | Salmon/pink button in footer; triggers sign-out flow |

> **Settings (הגדרות):** Per DD-2, Settings is resolved to be a drawer item.
> However, the Stitch screenshot does **not** show a "הגדרות" row among the six
> menu items enumerated above. See §7 (delta).

## 4. Sub-components / element design

### 4.1 Drawer header / profile banner

- **Layout:** `DrawerHeader` or custom `Container` with bottom padding.
- **Avatar:** circular `CircleAvatar`, diameter ~56 pt. Shows a user profile
  photo if available; fallback to a person silhouette icon (`#9CA3AF` on
  `#E5E7EB` background). Avatar is positioned at the top of the header,
  horizontally centred or right-aligned in RTL.
- **Name line:** "שלום, משתמש" — Public Sans SemiBold ~18 pt, `#1F2937`
  (`AppTypography.titleMedium` or equivalent). "משתמש" is replaced at runtime
  with the user's display name (from `UserProfile`). The greeting "שלום," is
  fixed Hebrew copy.
- **Subtitle line:** "בטוח לאכול" — Inter Regular 13 pt, `#6B7280`
  (`AppTypography.bodySmall` or `AppColors.onSurfaceVariant`). This appears to
  be the app name/tagline used as a muted role label.
- **Background:** `#FFFFFF` or a very light tint; no visible gradient.
- **Padding:** `EdgeInsets.fromLTRB(16, 24, 16, 16)` (4 px grid, adjusted for
  RTL so leading = right).

### 4.2 Menu row

Each row in the menu list follows a consistent pattern:

- **Height:** ~52–56 pt (comfortable tap target, 4 px grid).
- **Layout:** `ListTile` (Material) — RTL: icon on the right (leading in RTL),
  label text to the left of the icon, trailing chevron optional (not confirmed
  in screenshot).
- **Icon:** 22–24 pt, `#374151` (`AppColors.onSurfaceVariant`) in default state.
- **Label:** Inter Medium 15 pt, `#1F2937` (`AppColors.onSurface`) in default state.
- **Active / selected row** (פרופיל as shown): light blue-tinted background
  `#EBF4FF` (Medical Blue tint), icon color `#00478D` (`AppColors.primary`),
  label color `#00478D`.
- **Hover/pressed:** `InkWell` ripple, color `#00478D` at 8 % opacity.
- **Horizontal padding:** 16 pt each side.

### 4.3 Divider

A standard `Divider` between the main navigation items (פרופיל through
ביקורות שלי) and the utility items (מרכז עזרה, אודות):

- Height: 1 pt.
- Color: `#E5E7EB` (`AppColors.outline` token TBD).
- Horizontal indent: 16 pt each side (or full-width with `indent`/`endIndent`).

### 4.4 Footer

- **Container:** pinned to the bottom of the drawer (use `Column` +
  `Spacer` inside the drawer body, or wrap in a `Scaffold`-like structure).
- **Logout button:** full-width `ElevatedButton` or `OutlinedButton`,
  height ~48 pt, border-radius 12 pt.
  - Background: salmon/pink — approximately `#FECDD3` or `#FDA4AF` (light red-
    pink), **not** the primary Medical Blue. Exact token TBD — appears
    intentionally distinct from `AppColors.primary` to signal a destructive
    action without full red danger styling.
  - Label: "התנתקות", Inter SemiBold 14 pt, color approximately `#9F1239`
    (dark rose/crimson) — (token TBD).
  - Leading icon: `logout` or `exit_to_app`, same dark-rose color, 20 pt,
    positioned on the right in RTL (leading side).
  - Horizontal margin: 16 pt each side.
  - Bottom margin: 16 pt above the tagline row.
- **Version row** (below button):
  - Per DD-14, the brand/tagline string is **dropped from the drawer footer**. Footer renders only the runtime app version string.
  - Centred (`mainAxisAlignment: MainAxisAlignment.center`): "v1.0.0" — Inter Regular 11 pt, `#9CA3AF`. Sourced at runtime from `PackageInfo.fromPlatform()`.
  - Bottom safe-area padding applied.

## 5. States & interactions

### 5.1 Open / close

| Trigger | Effect |
|---|---|
| Tap hamburger `menu` icon in app bar | Drawer slides in from the right; scrim appears |
| Tap scrim (area outside drawer) | Drawer slides out to the right; scrim fades |
| Swipe right (RTL gesture) | Drawer slides closed |
| Back button / system back gesture | Drawer closes (pop) |

The drawer is opened via `Scaffold.of(context).openEndDrawer()` (RTL right-side
drawer maps to `endDrawer` in Flutter's `Scaffold`). The `Scaffold` must have
`endDrawer:` set, not `drawer:`.

### 5.2 Row navigation targets

| Row | Navigation action |
|---|---|
| פרופיל | Push `SettingsScreen` (Settings & Profile screen) — per DD-11, the פרופיל row is the Settings entry point; no separate הגדרות row exists |
| היסטוריית סריקה | Push `ScanHistoryScreen` |
| מוצרים שמורים | Push `SavedProductsScreen` |
| ביקורות שלי | Push `MyReviewsScreen` |
| מרכז עזרה | Push `HelpCenterScreen` or launch URL via `url_launcher` |
| אודות | Push `AboutScreen` |

After a navigation row is tapped:
1. The drawer closes (`Navigator.pop` / `Scaffold.of(context).closeEndDrawer()`).
2. The destination screen is pushed onto the navigator stack.

### 5.3 Active / selected state

The row matching the current logical destination is rendered with the active
style (§4.2 active). On first open from Home, "פרופיל" appears pre-selected in
the screenshot. The active row should reflect the user's current destination
(caller passes `currentRoute` or similar to the drawer widget).

### 5.4 Logout

Tapping "התנתקות":
1. Show a confirmation dialog (not modelled in this Stitch screen — implementation detail).
2. On confirm: clear `UserProfile` from SharedPreferences, reset Supabase
   session if applicable, navigate to `OnboardingScreen` (replace navigator stack).
3. On cancel: dismiss dialog; drawer remains open or closes.

The button is **not** a navigation row — it is a distinct destructive action in
the footer.

## 6. Data & controller contract

```dart
/// Drawer widget for authenticated (non-admin) users.
/// Opened as Scaffold.endDrawer (RTL right-side).
class UserNavigationDrawer extends StatelessWidget {
  /// The current user profile — provides display name for the header.
  final UserProfile userProfile;

  /// Called when a menu item is tapped; caller drives navigation.
  final ValueChanged<DrawerDestination> onDestinationSelected;

  /// Called when the logout button is confirmed.
  final VoidCallback onLogout;

  /// Which item is currently active (highlighted).
  final DrawerDestination? activeDestination;

  const UserNavigationDrawer({
    super.key,
    required this.userProfile,
    required this.onDestinationSelected,
    required this.onLogout,
    this.activeDestination,
  });
}

enum DrawerDestination {
  profile,
  scanHistory,
  savedProducts,
  myReviews,
  helpCenter,
  about,
  // settings reached via profile row per DD-11 — no separate drawer entry
}
```

**Data sources:**

| Field | Source |
|---|---|
| Display name ("משתמש") | `UserProfile.displayName` from SharedPreferences |
| Avatar image | `UserProfile.avatarUrl` (nullable; fallback to icon) |
| App version ("v1.0.0") | `PackageInfo.fromPlatform()` (`package_info_plus` package) |
| Active destination | Passed in from `AppShell` / `MainContainer` based on current route |

**No Supabase queries** are made directly by this drawer. Profile data is
already loaded by `AppShell` and passed down.

## 7. Open questions / design-vs-app deltas

### 7.1 Settings row missing from Stitch screenshot — Resolved per DD-11

Resolved per _design-decisions.md#dd-11. There is intentionally **no "הגדרות" row** in the drawer. The **"פרופיל"** row opens the Settings & Profile screen (`settings_screen.dart`), which already contains the profile block plus all settings menu rows (נהל אלרגיות, העדפות אפליקציה, etc.). No separate הגדרות row needs to be added. The Stitch drawer as drawn is correct; DD-2's statement that "Settings is reached via the drawer" is satisfied because פרופיל → Settings & Profile.

### 7.2 Logout button color token — resolved
Add `AppColors.destructiveSubtle = #FECDD3` (bg) and
`AppColors.onDestructiveSubtle = #9F1239` (fg) to the app palette. Logout
button uses these. Pressed state: bg `#FEE2E2`. The pair is registered in the
glossary's M3 adoption section as app-extension tokens (outside the
`ColorScheme` core).

### 7.3 Drawer footer brand text — resolved per DD-14

Resolved per _design-decisions.md#dd-14. The brand/tagline string is **dropped
from the drawer footer**; footer renders only the runtime version
("v1.0.0" from `PackageInfo.fromPlatform()`). The header subtitle "בטוח לאכול"
remains per DD-8. No new tagline is introduced.

### 7.4 Trailing chevrons on menu rows — resolved
Each menu row carries a trailing `Icon(Icons.chevron_left, size: 20, color: #9CA3AF)`
on the RTL-trailing (left) side, indicating push-navigation. Consistent across
both user and admin drawers.

### 7.5 App bottom-nav state when drawer is open

When the drawer is open the bottom nav is still visible but dimmed by the scrim.
No interaction change is needed — the scrim intercepts taps.

### 7.6 Icon assignments for rows 3 and 4

Icons for "מוצרים שמורים" and "ביקורות שלי" are inferred from context
(`bookmark_border` and `rate_review` / `photo_library` respectively); the
screenshot is small and exact icon glyphs could not be confirmed pixel-for-pixel.
Verify against the Stitch HTML source when accessible.

### 7.7 Implementation deltas — verification pass 2026-05-24 <!-- DIVERGED -->

Spec-parity check of `app/lib/screens/drawer_user_screen.dart` (and the parallel `app/lib/widgets/navigation_drawer.dart` which is an older widget also used by `AdminBrandsScreen`).

**Result: Two separate implementations exist — `DrawerUserScreen` (closer but still diverged) and `NavigationDrawer` widget (significantly diverged); neither is a `Drawer`/`endDrawer` widget as required.** Verified = ⚠. No code change this pass (documented only).

Aligned: `DrawerUserScreen` — correct 6 menu rows present (פרופיל, היסטוריה, מוצרים שמורים, ביקורת קהילה, מרכז עזרה, אודות), trailing `chevron_left` on each row (per §7.4), avatar 56 pt `CircleAvatar`-style container, logout via `onLogout` callback, RTL-compatible `Icons.person_outline`/`Icons.history`/`Icons.bookmark_outline`/`Icons.help_outline`/`Icons.info_outline`.

| # | Spec requirement | Current code |
|---|---|---|
| DU1 | Widget must be a `Drawer` widget (or wrapped in one) mounted as `Scaffold.endDrawer` for RTL right-side slide-in | `DrawerUserScreen` is a `Scaffold`-based full screen (`StatelessWidget` returning `Scaffold`) — it is **not** a `Drawer` widget; it cannot be mounted as `endDrawer`; the older `NavigationDrawer` widget (widgets/navigation_drawer.dart) returns a `Drawer` but is mounted as left-side `drawer:` not `endDrawer:` |
| DU2 | Widget signature: `UserNavigationDrawer` with `UserProfile userProfile`, `ValueChanged<DrawerDestination> onDestinationSelected`, `VoidCallback onLogout`, `DrawerDestination? activeDestination` (§6) | `DrawerUserScreen` accepts `String? userName`, `String? userSubtitle`, `ValueChanged<int>? onItemSelected`, `Set<int> disabledIndices` — no `UserProfile` object, no typed `DrawerDestination` enum; `onDestinationSelected` is an untyped int index |
| DU3 | Header greeting: "שלום, [name]" — fixed "שלום," prefix + dynamic user name from `UserProfile.displayName` | Header renders `userName ?? 'משתמש'` with no "שלום," greeting prefix |
| DU4 | Header subtitle: "בטוח לאכול" (Inter Regular 13 pt, `#6B7280`) — the app tagline per §4.1 | Subtitle renders `userSubtitle ?? 'חבר קהילה'` — "חבר קהילה" is not the spec copy; caller must pass "בטוח לאכול" but default is wrong |
| DU5 | Avatar: `CircleAvatar` with `UserProfile.avatarUrl` network image; fallback to person silhouette icon on `#E5E7EB` background | Avatar is a fixed `Container` with `AppColors.primaryFixed` background and `Icons.person` — no avatar URL support, no nullable fallback path |
| DU6 | Active row highlight: `#EBF4FF` background, icon/label `#00478D` for active destination (§4.2) | No `selectedTileColor` or active-state logic in `DrawerUserScreen`; rows are always non-selected (`disabledIndices` dims rows but is not the active-state feature) |
| DU7 | Divider between rows 4 (ביקורות שלי) and 5 (מרכז עזרה) — `Divider` 1 pt `#E5E7EB` (§4.3) | No `Divider` widget between the two groups |
| DU8 | Row 4 label: "ביקורות שלי" with icon `rate_review` or `photo_library` | Row 4 label is "ביקורת קהילה" (wrong copy — spec says "ביקורות שלי"); icon is `Icons.rate_review_outlined` (acceptable) |
| DU9 | Logout: full-width `ElevatedButton`/`OutlinedButton` height 48 pt, `BorderRadius.circular(12)`, salmon bg `#FECDD3` (or `#FDA4AF`), label "התנתקות" dark-rose `#9F1239`, leading `logout`/`exit_to_app` icon right-aligned in RTL, 16 pt horizontal margin (§4.4) | Logout is a `ListTile` with `Icons.logout` in `AppColors.error` (red, not salmon) and label "יציאה" (wrong copy — spec says "התנתקות"); not an `ElevatedButton`; no salmon background; wrong text |
| DU10 | Footer version row: centred "v1.0.0" from `PackageInfo.fromPlatform()`, Inter Regular 11 pt `#9CA3AF` (per DD-14) | No version row anywhere in `DrawerUserScreen` |
| DU11 | Background: `#FFFFFF` (white surface) | `DrawerUserScreen` uses `AppColors.surfaceContainerLow` (not white) |
| DU12 | Row label "היסטוריית סריקה" for row 2 | Row 2 label is "היסטוריה" (truncated — spec says "היסטוריית סריקה") |

**Priority / quick wins:** DU9 (logout button wrong label "יציאה" vs. spec "התנתקות", wrong color red vs. salmon — user-visible copy bug), DU8 (row 4 "ביקורת קהילה" vs. spec "ביקורות שלי" — user-visible copy bug), DU12 ("היסטוריה" vs. "היסטוריית סריקה"). DU1 (Scaffold vs. Drawer widget) is the structural root issue that blocks all RTL endDrawer behavior.

---

## Resolved cross-screen note

**Settings row missing from drawer**

Resolved per _design-decisions.md#dd-11. There is intentionally no "הגדרות" row in the drawer. The **"פרופיל"** row opens the Settings & Profile screen (`settings_screen.dart`), which contains both profile management and all settings menu rows. The Stitch drawer as drawn is correct and complete. DD-2's claim that "Settings is reached via the drawer" is satisfied by the פרופיל row. No Stitch screen edit is needed; no new drawer row is to be added.
