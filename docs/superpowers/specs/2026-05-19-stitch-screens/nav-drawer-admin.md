# Admin Navigation Drawer / תפריט ניווט (מנהל)
Stitch screen: projects/16588854804615693446/screens/b4224114bb2e4ff6a2cca1db65a401f6
Maps to: app/lib/screens/drawer_user_screen.dart (admin variant)

## 1. Purpose & context

The admin navigation drawer is the right-anchored slide-in panel shown **only to
users whose role is `admin`** (or equivalent role-gate — see §6). It replaces the
standard user drawer (`nav-drawer-user.md`) entirely; an admin user never sees
the user-drawer variant.

Like the user drawer it is opened from the `menu` icon in the app bar
(see `_components-glossary.md#app-bar`) and slides in **from the right** edge of
the screen (RTL convention, `Scaffold.endDrawer`). The rest of the screen dims
behind a semi-transparent scrim.

The admin drawer provides two categories of additional capability not present in
the user drawer:

1. **System-management destinations** — platform-level controls (dashboard,
   brand management, reports, system settings).
2. **Content-management destinations** — moderation tools (product scans,
   community management).

The header identity line is also elevated: instead of "שלום, משתמש" it greets
the admin by name and shows the role label "מנהל מערכת" (System Administrator),
making the elevated privilege level immediately visible.

## 2. Visual layout breakdown

Drawer occupies roughly 80 % of screen width, anchored to the right edge —
identical proportions and shadow treatment as the user drawer (see
`nav-drawer-user.md §2`). The internal column is taller because it carries two
labelled section groups rather than a flat list.

```
┌─────────────────────────────────────┐  ← right edge of screen
│  HEADER                             │
│    avatar (circular, ~56 pt)        │
│    "שלום, מנהל"    (bold, ~18 pt)   │
│    "מנהל מערכת"    (role badge/tag) │
├─────────────────────────────────────┤
│  SECTION: ניהול מערכת               │
│    row: לוח בקרה                    │
│    row: ניהול מותגים                │
│    row: דיווחים                     │
│    row: הגדרות מערכת               │
├─────────────────────────────────────┤
│  SECTION: ניהול תוכן                │
│    row: סריקות מוצרים              │
│    row: ניהול קהילה                 │
├─────────────────────────────────────┤
│  FOOTER                             │
│    [  ← התנתקות  ]   salmon button  │
│    "אלרגיות בצלחת"         v1.0.0   │
└─────────────────────────────────────┘
```

**Background:** `#FFFFFF` (white surface).  
**Scrim:** semi-transparent black overlay, ~40–50 % opacity.  
**Drawer width / shadow / corner-radius:** identical to user drawer
(see `nav-drawer-user.md §2`).  
**Section headers:** short Hebrew label rendered as a non-tappable group
label above the rows in each section — see §4.3.

## 3. Component inventory

Full admin drawer item list in RTL reading order (top → bottom). Items marked
**[admin-only]** do not appear in the user drawer; items marked **[shared]**
appear in both drawers (with identical label, icon, and destination).

| # | Hebrew label | Icon (Material) | Destination / action | Admin-only or shared |
|---|---|---|---|---|
| H | Header area | — | — | Header differs (see §4.1) |
| **— SECTION: ניהול מערכת —** | | | | Admin-only section group |
| 1 | **לוח בקרה** | `dashboard` | `AdminDashboardScreen` | [admin-only] |
| 2 | **ניהול מותגים** | `factory` | `BrandManagementScreen` | [admin-only] |
| 3 | **דיווחים** | `report` (or `flag`) | `ReportsScreen` | [admin-only] |
| 4 | **הגדרות מערכת** | `settings` | `SystemSettingsScreen` | [admin-only] |
| **— SECTION: ניהול תוכן —** | | | | Admin-only section group |
| 5 | **סריקות מוצרים** | `barcode_scanner` | `ProductScansScreen` | [admin-only] |
| 6 | **ניהול קהילה** | `group` (or `groups`) | `CommunityManagementScreen` | [admin-only] |
| F | **התנתקות** | `logout` / `exit_to_app` | Logout action | [shared] — identical salmon button |

> **User-drawer rows absent from admin drawer:** פרופיל, היסטוריית סריקה,
> מוצרים שמורים, ביקורות שלי, מרכז עזרה, אודות. The admin drawer replaces
> the entire menu list with the management sections above; the only shared
> element in the menu region is the footer logout button.

> **הגדרות (Settings):** The admin drawer contains **הגדרות מערכת** (System
> Settings, item 4), which is an admin-scoped settings screen distinct from the
> user-level settings absent from the user drawer. This partially addresses the
> `settings-row-in-drawer` inconsistency flagged in `nav-drawer-user.md §7.1`
> for the admin context, but does not resolve it for regular users. See §7.

## 4. Sub-components / element design

### 4.1 Drawer header / admin identity banner

Follows the same structural pattern as the user drawer header
(see `nav-drawer-user.md §4.1`) with these differences:

- **Greeting line:** "שלום, מנהל" — Public Sans SemiBold ~18 pt, `#1F2937`.
  "מנהל" is replaced at runtime with the admin user's display name
  (`AdminProfile.displayName`). The greeting "שלום," is fixed copy.
- **Role subtitle / badge — resolved (chip).** Render "מנהל מערכת" as a small
  role chip below the greeting: rounded pill, background `#EBF4FF` (Medical
  Blue tint), border 1 pt `#BFDBFE`, label Inter Medium 12 pt `#00478D`,
  padding `EdgeInsets.symmetric(horizontal: 10, vertical: 4)`,
  `BorderRadius.circular(20)`. Visually distinct from the user-drawer's plain
  muted subtitle; communicates elevated privilege at a glance. Consistent with
  `allergen-chip` Variant A styling.
- **Avatar:** same circular `CircleAvatar`, ~56 pt, with an admin-specific
  fallback (e.g. `admin_panel_settings` icon) if no avatar URL is set.
- **Background:** `#FFFFFF` or very light tint — identical to user drawer.

### 4.2 Section header label

The admin drawer introduces named section groups absent from the user drawer:

- **Text:** Inter SemiBold 11–12 pt, `#9CA3AF` (muted, uppercase or
  small-caps treatment) — e.g. "ניהול מערכת", "ניהול תוכן".
- **Padding:** `EdgeInsets.fromLTRB(16, 16, 16, 4)` — left-padding in LTR terms,
  but since the drawer is RTL the label text reads right-to-left with 16 pt
  inset from the right edge.
- **Not tappable.** Purely a visual grouping label.
- **No divider line between sections** was confirmed; section headers alone
  delineate the groups. A `Divider` may still be added between the two section
  groups at implementation discretion.

### 4.3 Menu row

Identical spec to the user drawer menu row (see `nav-drawer-user.md §4.2`):
height ~52–56 pt, `ListTile` RTL, icon 22–24 pt `#374151`, label Inter Medium
15 pt `#1F2937`, active-row tint `#EBF4FF` / `#00478D`.

Admin-specific note: "לוח בקרה" (Dashboard) is the default active/selected row
when the drawer is opened from the admin home context, analogous to "פרופיל"
being the default active row in the user drawer.

### 4.4 Footer

Identical to the user drawer footer (see `nav-drawer-user.md §4.4`):
- Salmon/pink logout button ("התנתקות"), full-width, height 48 pt,
  border-radius 12 pt, background ~`#FECDD3` / `#FDA4AF`, label dark-rose
  `#9F1239` (token TBD — `AppColors.destructiveSubtle`).
- **Version row** (per DD-14): centred app version string only
  ("v1.0.0" from `PackageInfo.fromPlatform()`), Inter Regular 11 pt `#9CA3AF`.
  Brand/tagline text is dropped — "אלרגיות בצלחת" is not rendered.
- Bottom safe-area padding applied.

The Stitch HTML extraction showed version "v1.2.4 Build" for the admin drawer
versus "v1.0.0" on the user drawer. Both are placeholder values; runtime version
comes from `PackageInfo` — see §7.2.

## 5. States & interactions

### 5.1 Open / close

Identical mechanism to the user drawer (see `nav-drawer-user.md §5.1`):
`Scaffold.of(context).openEndDrawer()`, scrim tap or right-swipe to close.

The admin drawer is only mounted when the authenticated user has admin role;
the `Scaffold.endDrawer` parameter receives `AdminNavigationDrawer` instead
of `UserNavigationDrawer` (role switching happens at `AppShell` level — see §6).

### 5.2 Row navigation targets

| Row | Navigation action |
|---|---|
| לוח בקרה | Push `AdminDashboardScreen` |
| ניהול מותגים | Push `BrandManagementScreen` |
| דיווחים | Push `ReportsScreen` |
| הגדרות מערכת | Push `SystemSettingsScreen` |
| סריקות מוצרים | Push `ProductScansScreen` |
| ניהול קהילה | Push `CommunityManagementScreen` |
| התנתקות | Logout action (see §5.3) |

After a navigation row is tapped the drawer closes and the destination is pushed
onto the navigator stack — identical to the user drawer pattern
(`nav-drawer-user.md §5.2`).

### 5.3 Logout

Identical flow to the user drawer (`nav-drawer-user.md §5.4`): confirmation
dialog → clear profile/session → navigate to `OnboardingScreen`.

### 5.4 Active / selected state

The row matching the admin's current screen is rendered with the active style
(§4.3 active). "לוח בקרה" is pre-selected when the drawer is first opened from
the admin home. The `activeDestination` parameter drives this (see §6).

## 6. Data & controller contract

```dart
/// Drawer widget for authenticated admin users.
/// Mounted as Scaffold.endDrawer when AdminProfile.isAdmin == true.
class AdminNavigationDrawer extends StatelessWidget {
  /// The current admin profile — provides display name for the header.
  final AdminProfile adminProfile;

  /// Called when a menu item is tapped; caller drives navigation.
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;

  /// Called when the logout button is confirmed.
  final VoidCallback onLogout;

  /// Which item is currently active (highlighted).
  final AdminDrawerDestination? activeDestination;

  const AdminNavigationDrawer({
    super.key,
    required this.adminProfile,
    required this.onDestinationSelected,
    required this.onLogout,
    this.activeDestination,
  });
}

enum AdminDrawerDestination {
  dashboard,          // לוח בקרה
  brandManagement,    // ניהול מותגים
  reports,            // דיווחים
  systemSettings,     // הגדרות מערכת
  productScans,       // סריקות מוצרים
  communityManagement, // ניהול קהילה
}
```

**Admin role gating — how admin mode is determined:**

The `AppShell` widget is responsible for reading the user's role and choosing
which drawer variant to mount:

```dart
// Pseudocode in AppShell.build():
endDrawer: userProfile.isAdmin
    ? AdminNavigationDrawer(adminProfile: adminProfile, ...)
    : UserNavigationDrawer(userProfile: userProfile, ...),
```

`UserProfile.isAdmin` (or an equivalent field such as `role == 'admin'`) must be
persisted in SharedPreferences and/or returned from Supabase on session load.
The admin drawer is never rendered for non-admin users — it is not just
visually hidden.

**Data sources:**

| Field | Source |
|---|---|
| Display name ("מנהל") | `AdminProfile.displayName` from SharedPreferences / Supabase session |
| Role label ("מנהל מערכת") | Fixed copy (admin users always hold this role in MVP) |
| Avatar image | `AdminProfile.avatarUrl` (nullable; fallback to `admin_panel_settings` icon) |
| App version ("v1.0.0") | `PackageInfo.fromPlatform()` (`package_info_plus`) |
| Active destination | Passed in from `AppShell` based on current route |
| `isAdmin` flag | `UserProfile.isAdmin` (bool) populated from Supabase user metadata or a local role field |

**No Supabase queries** are made directly by this drawer. All data is resolved
by `AppShell` before the drawer widget is instantiated.

## 7. Open questions / design-vs-app deltas

### 7.1 Role subtitle rendering — resolved (chip per §4.1)

Render "מנהל מערכת" as a chip (background `#EBF4FF`, border `#BFDBFE`, label
`#00478D` Inter Medium 12 pt) below the greeting. See §4.1.

### 7.2 Footer version string artefact

The Stitch HTML for the admin drawer shows "v1.2.4 Build" whereas the user
drawer shows "v1.0.0". Both are design-time placeholder values. Implementation
must use `PackageInfo.fromPlatform()` for both drawers — the version string
should be identical at runtime regardless of drawer variant.

### 7.3 Settings row — admin drawer partially resolves the user-drawer flag

The `settings-row-in-drawer` inconsistency flagged in `nav-drawer-user.md §7.1`
remains open for regular users. The admin drawer **does** contain a
"הגדרות מערכת" row (item 4), but this is an admin-scoped system-settings screen
(`SystemSettingsScreen`), not the user-level `SettingsScreen` that DD-2 calls
for. The gap identified in the user-drawer flag is unresolved for non-admin
users; this note relates to that existing flag and does not open a new
inconsistency.

### 7.4 Admin dashboard metrics — resolved (NOT in the drawer)

The metrics panel ("משתמשים פעילים: 12,482" / "דיווחים פתוחים: 42") and the
announcements strip belong to `AdminDashboardScreen` (the destination behind
the "לוח בקרה" row), not to the drawer itself. The HTML extraction merged the
two. The drawer remains a flat list of section-grouped rows + footer per §2.
`AdminDashboardScreen` is out-of-batch for these specs.

### 7.5 Delta summary — admin drawer vs. user drawer

| Aspect | User drawer (`nav-drawer-user`) | Admin drawer (this screen) |
|---|---|---|
| Header greeting | "שלום, משתמש" | "שלום, מנהל" |
| Header subtitle | "בטוח לאכול" (app tagline) | "מנהל מערכת" (role label) |
| Avatar fallback | Person silhouette | `admin_panel_settings` icon (inferred) |
| Menu structure | Flat list, 6 rows, 1 divider | Two labelled sections, 6 rows total, no flat list |
| Section groups | None | "ניהול מערכת" (4 rows) + "ניהול תוכן" (2 rows) |
| Menu rows | פרופיל, היסטוריית סריקה, מוצרים שמורים, ביקורות שלי, מרכז עזרה, אודות | לוח בקרה, ניהול מותגים, דיווחים, הגדרות מערכת, סריקות מוצרים, ניהול קהילה |
| Settings access | None visible in Stitch (open flag) | הגדרות מערכת row present (admin-scoped) |
| Footer logout button | Identical salmon "התנתקות" | Identical salmon "התנתקות" |
| Footer version row | Centred "v1.0.0" only (per DD-14; brand string dropped) | Centred "v1.0.0" only (per DD-14; brand string dropped; Stitch "v1.2.4" is an artefact) |
| Role gating | Not shown (all authenticated users) | `UserProfile.isAdmin == true` required |
| Widget class | `UserNavigationDrawer` | `AdminNavigationDrawer` |
| Default active row | פרופיל | לוח בקרה |

### 7.6 Icon confirmation for ניהול מותגים

The `factory` icon is inferred from the HTML text extraction label "Brand
Management". Verify against the rendered screenshot — a more semantically
appropriate icon such as `storefront`, `business`, or `label` may be intended.

### 7.7 Trailing chevrons

Same open question as user drawer (`nav-drawer-user.md §7.4`) — whether each
row carries a `chevron_left` trailing indicator. Apply consistently across both
drawer variants.
