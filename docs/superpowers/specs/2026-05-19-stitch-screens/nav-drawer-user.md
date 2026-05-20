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
- **Tagline row** (below button):
  - Left (trailing in RTL): "v1.0.0" — Inter Regular 11 pt, `#9CA3AF`.
  - Right (leading in RTL): "אלרגיות בצלחת" — Inter Regular 11 pt, `#9CA3AF`.
  - This row is purely informational (app version + brand tagline).
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

### 7.2 Logout button color token

The logout button uses a salmon/pink background that does not map to any named
token in `AppColors` as currently documented. Token TBD pending palette
expansion. Candidates: `AppColors.destructiveSubtle` (token TBD).

### 7.3 "אלרגיות בצלחת" tagline vs. "בטוח לאכול" app name

The header subtitle reads "בטוח לאכול" (the app's primary brand name).
The footer reads "אלרגיות בצלחת" — a secondary tagline/brand phrase not seen
elsewhere in the reviewed screens. Implementors should confirm which string is
the canonical app name/tagline and which (if either) should be localisation-
keyed rather than hardcoded.

### 7.4 Trailing chevrons on menu rows

The screenshot does not clearly confirm whether individual rows carry a trailing
`chevron_left` (RTL forward-nav indicator). Standard Material `ListTile`
convention would include one for items that push a new screen. Implementation
may add `trailing: Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant)`
to each row; confirm with design.

### 7.5 App bottom-nav state when drawer is open

When the drawer is open the bottom nav is still visible but dimmed by the scrim.
No interaction change is needed — the scrim intercepts taps.

### 7.6 Icon assignments for rows 3 and 4

Icons for "מוצרים שמורים" and "ביקורות שלי" are inferred from context
(`bookmark_border` and `rate_review` / `photo_library` respectively); the
screenshot is small and exact icon glyphs could not be confirmed pixel-for-pixel.
Verify against the Stitch HTML source when accessible.

---

## Resolved cross-screen note

**Settings row missing from drawer**

Resolved per _design-decisions.md#dd-11. There is intentionally no "הגדרות" row in the drawer. The **"פרופיל"** row opens the Settings & Profile screen (`settings_screen.dart`), which contains both profile management and all settings menu rows. The Stitch drawer as drawn is correct and complete. DD-2's claim that "Settings is reached via the drawer" is satisfied by the פרופיל row. No Stitch screen edit is needed; no new drawer row is to be added.
