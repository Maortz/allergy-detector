# Onboarding — Step 2 (Name + Notifications)
Stitch screen: *(no Stitch screen — derived spec per `onboarding-allergen-selection §7.4` resolution)*
Maps to: `app/lib/screens/onboarding_step_2_screen.dart` (new file)

## 1. Purpose & context

Step 2 of the 2-step onboarding flow. Step 1 (`onboarding-allergen-selection`)
captured the user's allergen profile; step 2 collects the user's display name
and optionally requests notification permission. On completion this screen
sets `UserProfile.hasCompletedOnboarding = true`, persists `displayName`, and
hands off to `MainContainer`.

This screen is presented inside the same standalone onboarding shell as step 1
(no main-app chrome, no bottom nav).

## 2. Visual layout breakdown

Single `Scaffold` body, `Directionality(textDirection: TextDirection.rtl)`,
`SafeArea`. Top-to-bottom `Column`:

| Zone | Height | Content |
|---|---|---|
| Brand header | ~56 pt | "SafeBite" RTL-trailing; `cancel` ✕ RTL-leading |
| Headline block | auto | Title "כמעט סיימנו!" + body explainer |
| Progress row | ~24 pt | "שלב 2 מתוך 2" · "100% הושלם" |
| Linear progress bar | 6 pt | 100 % fill, `AppColors.primary` |
| Name field | ~80 pt | Label "מה השם שלך?" + `TextField` |
| Notification block | ~140 pt | Icon + heading + body + outlined "אפשר התראות" button |
| Spacer | flex | — |
| Continue button | 48 pt | "סיים" — full-width primary |

Background: `AppColors.background` `#F9FAFB`. Horizontal margins: 16 pt.

## 3. Component inventory

| # | Component | Source |
|---|---|---|
| 1 | Brand header inline row | Screen-specific (matches step 1 §4.1) |
| 2 | Headline "כמעט סיימנו!" | Screen-specific text |
| 3 | Step-counter row | Mirrors step 1 §4.3 with values "שלב 2 מתוך 2" / "100% הושלם" |
| 4 | Linear progress bar | `LinearProgressIndicator(value: 1.0)`, height 6 pt |
| 5 | Name `TextField` | Standard outlined input |
| 6 | Notification request block | Screen-specific (§4.3) |
| 7 | Primary CTA "סיים" | see `_components-glossary.md#primary-button` |

## 4. Sub-components / element design

### 4.1 Name field

- Label above input: "מה השם שלך?" — Inter SemiBold 14 pt, `#191C1D`, right-aligned.
- `TextField`:
  - Height 48 pt, `BorderRadius.circular(8)`, border 1 pt `#727783`, focused border `#00478D`.
  - Background `#FFFFFF`, text right-aligned (RTL).
  - Placeholder: "הקלד את שמך".
  - `keyboardType: TextInputType.name`.
  - Bound to a `TextEditingController` in state.
- Required to continue (`displayName.trim().isNotEmpty`).
- 8 pt gap between label and input.

### 4.2 Notification request block

- Container: `#FFFFFF` bg, `BorderRadius.circular(12)`, padding 16 pt, subtle drop-shadow.
- Internal `Column(crossAxisAlignment: CrossAxisAlignment.center)`:
  - Icon: `Icons.notifications_active`, 32 pt, `#00478D`.
  - Gap 8 pt.
  - Heading: "התראות חכמות" — Inter SemiBold 14 pt, `#1F2937`, `TextAlign.center`.
  - Gap 4 pt.
  - Body: "קבל התראות כשמצאנו מוצר חדש שעלול לסכן אותך." — Inter Regular 13 pt, `#6B7280`, `TextAlign.center`, max 2 lines.
  - Gap 12 pt.
  - Outlined button "אפשר התראות": full-width-min-content, height 40 pt, `BorderRadius.circular(8)`, border 1.5 pt `#00478D`, label Inter SemiBold 13 pt `#00478D`, icon `Icons.notifications_none` leading 18 pt `#00478D`. Tapping triggers the OS notification-permission prompt via `permission_handler`.
  - After grant (or any user response): button enters a "אופשר" success state (background `#DCFCE7`, border `#16A34A`, icon `Icons.check_circle` `#16A34A`, label `#15803D`). Reversible only via OS settings.
- The notification step is **optional** — declining (denying the OS prompt) does not block "סיים".

### 4.3 Primary CTA

- `PrimaryButton` (Standard variant): label "סיים", no trailing icon, height 48 pt, full-width within 16 pt margins, `BorderRadius.circular(12)`.
- `onPressed` is `null` (disabled) until `_nameController.text.trim().isNotEmpty`.
- On tap: persist `displayName` + `hasCompletedOnboarding = true` via `onProfileUpdated`; `AppShell` swaps to `MainContainer`.

## 5. States & interactions

| State | Trigger | Visual |
|---|---|---|
| Empty name (initial) | Screen mount | "סיים" disabled (`#D1D5DB` bg, `#9CA3AF` text) |
| Name typed | User types ≥1 non-whitespace char | "סיים" enabled (`#00478D` bg) |
| Notification button tapped | User taps "אפשר התראות" | OS permission dialog appears |
| Notification granted | User accepts | Button transitions to "אופשר" success state |
| Notification denied | User denies | Button reverts to default; no error shown; "סיים" still enabled |
| "סיים" tapped (valid) | User submits | `UserProfile.copyWith(displayName, hasCompletedOnboarding: true)` → `onProfileUpdated` → `AppShell` rebuild → `MainContainer` |
| Back / ✕ | User taps `cancel` | Pops back to step 1 (allergen selection); profile state preserved |

## 6. Data & controller contract

### 6.1 Inputs

```dart
OnboardingStep2Screen({
  required UserProfile userProfile,   // from step 1 — selectedAllergenIds populated
  required ValueChanged<UserProfile> onProfileUpdated,
})
```

### 6.2 Local state

- `late TextEditingController _nameController;` (initialised to `userProfile.displayName ?? ''`).
- `NotificationPermissionStatus _notifStatus = .notRequested;` — drives notification button visual.

### 6.3 Completion side-effects

- `_complete()` calls:
  ```dart
  final updated = _profile.copyWith(
    displayName: _nameController.text.trim(),
    hasCompletedOnboarding: true,
  );
  widget.onProfileUpdated(updated);
  ```
- `AppShell` persists to SharedPreferences (`display_name`, `has_completed_onboarding = true`) and rebuilds.

### 6.4 SharedPreferences keys

| Key | Written by | Value |
|---|---|---|
| `display_name` | AppShell on this screen's completion | `String` |
| `has_completed_onboarding` | AppShell on this screen's completion | `true` |

### 6.5 Permission package

Use `permission_handler` to request `Permission.notification`. On web, the
package is a no-op — the screen behaves identically but the button remains in
its default state (no OS dialog appears).

## 7. Open questions / design-vs-app deltas

### 7.1 Stitch source — no canonical screen
This spec is derived from `onboarding-allergen-selection §7.4` resolution
("implement step 2"). No Stitch screen exists for this step. Visual choices
mirror step 1's design system (brand header, progress bar, primary button).

### 7.2 Notification provider — out of scope
The actual notification delivery (FCM / APNs setup) is out of scope for these
specs. This screen only requests permission; the back-end push pipeline lands
in a separate spec.
