# Implementation Plan: Tier 1 Unbuilt Screens

**Date:** 2026-05-21
**Branch:** to be created per phase
**Status:** Ready to implement

---

## Executive Summary

Implements all 11 Tier 1 unbuilt screens/widgets for the Hebrew RTL Flutter app. Work divides into 10 strictly ordered phases. Phases 1–3 are foundational model and utility changes that all later phases depend on. Phases 4–9 add screens, widgets, and services. Phase 10 covers test coverage.

**Total estimated effort:** 8–9 developer-days.

---

## Dependency graph (read before starting any phase)

```
Phase 1 (UserProfile extended)
  └── Phase 2 (AppShell persistence)
        └── Phase 4b (OnboardingStep2Screen — reads displayName)
        └── Phase 7  (ProfileEditSheet — persists displayName, avatarData)
  └── Phase 5a (AllergenManagementScreen)
Phase 3 (Utilities: dialogs + photo picker)
  └── Phase 5b (SettingsScreen logout → showLogoutDialog)
  └── Phase 7  (ProfileEditSheet → showPhotoSourcePicker)
  └── Phase 8c (AdminBrandFormSheet → showBrandDeleteDialog D-3)
  └── Phase 9  (Drawer logout → showLogoutDialog)
Phase 4a (pubspec: permission_handler)
  └── Phase 4b (OnboardingStep2Screen)
Phase 6a (FavoritesScreen)
  └── Phase 6b (MainContainer restructure)
Phase 8a (Brand model)
  └── Phase 8b (BrandService)
        └── Phase 8c (AdminBrandFormSheet)
              └── Phase 8d (AdminBrandsScreen modified)
All phases → Phase 10 (Tests)
```

---

## Phase 1 — Extend `UserProfile` Model

**Files changed:** `app/lib/models/user_profile.dart`

Add three nullable fields:

| Field | Type | SharedPreferences key |
|---|---|---|
| `displayName` | `String?` | `display_name` |
| `email` | `String?` | `email` |
| `avatarData` | `String?` | `avatar_data` (base64 JPEG, 256×256 max) |

- Add all three as optional named parameters with `null` defaults.
- Extend `copyWith` to include the new fields. Use a `_Undefined` sentinel if "set to null" ever needs to be distinguishable from "omit" — for MVP, a simple nullable parameter is acceptable since clearing to null only happens on logout (where `UserProfile()` is constructed fresh).
- `toggleAllergen` signature unchanged — it takes an `Allergen` object, matching the existing widget.

**Gotcha:** Existing tests construct `UserProfile` with named args; they continue to compile because new fields are optional. No forced test changes, but extend `user_profile_test.dart` to cover new fields (Phase 10).

---

## Phase 2 — Extend `AppShell` SharedPreferences Persistence

**Files changed:** `app/lib/main.dart`

In `_loadProfileAndAllergens()` — add reads after existing keys:
```dart
final displayName = prefs.getString('display_name');
final email       = prefs.getString('email');
final avatarData  = prefs.getString('avatar_data');
```
Pass all three into the `UserProfile(...)` constructor call.

In `_onProfileUpdated(UserProfile profile)` — extend the write block:
- `displayName != null` → `prefs.setString('display_name', ...)` else `prefs.remove('display_name')`
- Same pattern for `email` and `avatar_data`.

**Logout path (Phase 5b / Phase 9):** Calling `_onProfileUpdated(const UserProfile())` will fire the `prefs.remove` for all new keys automatically because all three fields default to null.

**Gotcha:** `SharedPreferences.setString` is a no-op for empty string on some implementations; always null-check before writing, use `remove` when null.

---

## Phase 3 — Shared Utilities

**Files created:**
- `app/lib/utils/app_dialogs.dart`
- `app/lib/utils/photo_source_picker.dart`

### `app_dialogs.dart`

Three functions, all following `_dialogs.md` visual conventions:
- `AlertDialog.shape`: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`
- All wrapped with `Directionality(textDirection: TextDirection.rtl)`
- Destructive action: `TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626))`
- `barrierDismissible: true`

```dart
// D-1: wizard exit
Future<bool> showWizardExitDialog(BuildContext context) async

// D-2: logout (caller wires the actual profile clear + navigation)
Future<void> showLogoutDialog(BuildContext context, {required VoidCallback onConfirmed})

// D-3: brand delete (admin)
Future<bool> showBrandDeleteDialog(BuildContext context) async
```

Copy button labels and body text exactly from `_dialogs.md`.

### `photo_source_picker.dart`

```dart
Future<ImageSource?> showPhotoSourcePicker(BuildContext context) async
```

- Import `kIsWeb` from `package:flutter/foundation.dart` (never `dart:io` Platform — unsafe on web).
- On web (`kIsWeb == true`): return `ImageSource.gallery` immediately without showing any sheet.
- On mobile: `showModalBottomSheet` with two `ListTile`s — `Icons.camera_alt` / camera, `Icons.photo_library` / gallery. Returns the chosen `ImageSource` or `null` if dismissed via scrim.

---

## Phase 4 — `OnboardingStep2Screen` (and onboarding flow rewire)

**Files changed:** `app/pubspec.yaml`, `app/lib/screens/onboarding_screen.dart`
**Files created:** `app/lib/screens/onboarding_step_2_screen.dart`

### 4a — Add `permission_handler` to `pubspec.yaml`

```yaml
dependencies:
  permission_handler: ^11.3.1   # add under existing deps
```

On web this package is a no-op — `Permission.notification.request()` returns `PermissionStatus.granted` without any OS dialog. No `kIsWeb` guard needed in app code.

**iOS config required (flag in PR):** Add `NSUserNotificationUsageDescription` to `ios/Runner/Info.plist`.

### 4b — Create `OnboardingStep2Screen`

**Constructor:**
```dart
OnboardingStep2Screen({
  required UserProfile userProfile,
  required ValueChanged<UserProfile> onProfileUpdated,
})
```

**Layout** (top-to-bottom `Column` inside `SafeArea`, background `AppColors.background`, horizontal margins 16 pt):

| Zone | Content |
|---|---|
| Brand header row | "SafeBite" RTL-trailing + ✕ `IconButton` RTL-leading (pops back to step 1) |
| Headline block | "כמעט סיימנו!" (`AppTypography.h2`) + explainer body (`AppTypography.bodyMd`, `AppColors.onSurfaceVariant`) |
| Step counter row | "שלב 2 מתוך 2" left · "100% הושלם" right (`AppTypography.labelSm`) |
| Progress bar | `LinearProgressIndicator(value: 1.0)`, 6 pt height, `AppColors.primary` fill |
| Name field | Label "מה השם שלך?" + outlined `TextField` (`keyboardType: TextInputType.name`, right-aligned) |
| Notification block | White card, `BorderRadius.circular(12)`, shadow; `Icons.notifications_active` 32 pt primary; heading + body text; outlined "אפשר התראות" button |
| Spacer | `Spacer()` |
| "סיים" CTA | Full-width `ElevatedButton`, 48 pt, disabled until name non-empty |

**Internal state:**
```dart
late TextEditingController _nameController;  // init from userProfile.displayName ?? ''
bool _notifGranted = false;                  // drives button success state
```

**Notification button tap:**
```dart
final status = await Permission.notification.request();
if (status.isGranted) setState(() => _notifGranted = true);
```
Notification is optional — denying does not block "סיים".

**Completion:**
```dart
void _complete() {
  final updated = widget.userProfile.copyWith(
    displayName: _nameController.text.trim(),
    hasCompletedOnboarding: true,
  );
  widget.onProfileUpdated(updated);
}
```

### 4c — Modify `OnboardingScreen._complete()`

**Current:**
```dart
void _complete() {
  final updated = _profile.copyWith(hasCompletedOnboarding: true);
  widget.onProfileUpdated(updated);
}
```

**Changed to:**
```dart
void _complete() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OnboardingStep2Screen(
        userProfile: _profile,   // selectedAllergenIds already set; hasCompletedOnboarding still false
        onProfileUpdated: widget.onProfileUpdated,
      ),
    ),
  );
}
```

**Impact on existing test** (`onboarding_screen_test.dart`): The assertion `onProfileUpdated` is called with `hasCompletedOnboarding: true` will now fail — step 1 no longer calls it. Update the test: verify that tapping "המשך" with allergens selected causes `find.byType(OnboardingStep2Screen)` to appear after `pumpAndSettle`. `pumpAndSettle` is safe in `onboarding_screen_test.dart` (no infinite animations). Update `user_flows_test.dart` similarly.

---

## Phase 5 — `AllergenManagementScreen` + `SettingsScreen` wiring

**Files created:** `app/lib/screens/allergen_management_screen.dart`
**Files modified:** `app/lib/screens/settings_screen.dart`

### 5a — Create `AllergenManagementScreen`

**Constructor:**
```dart
AllergenManagementScreen({
  required List<Allergen> allergens,
  required UserProfile userProfile,
  required ValueChanged<UserProfile> onProfileUpdated,
})
```

**Layout:**
- `Scaffold` with detail-bar `AppBar(title: Text('נהל אלרגיות'))` (back arrow automatic from `Navigator.push`)
- Body `Column`:
  1. Counter row: `"אלרגנים פעילים: ${_profile.selectedAllergenIds.length}"` — Inter Regular 13 pt, `AppColors.onSurfaceVariant`, right-aligned, 12 pt below app bar, 16 pt horizontal margin
  2. `Expanded(child: GridView.builder(...))` — identical delegate to `OnboardingScreen` (crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.0, 16 pt horizontal padding); items are `AllergenCard(allergen: allergen, isSelected: ..., onTap: () => _toggle(allergen))`
  3. Sticky disclaimer: `SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('השינויים נשמרים אוטומטית', ...)))` — Inter Regular 11 pt, `AppColors.onSurfaceVariant`, `TextAlign.center`

**Toggle logic:**
```dart
void _toggle(Allergen allergen) {
  setState(() => _profile = _profile.toggleAllergen(allergen));
  widget.onProfileUpdated(_profile);   // immediate save → AppShell → SharedPreferences
}
```

### 5b — Wire `SettingsScreen`

Three wiring changes inside `settings_screen.dart`:

**1. "נהל אלרגיות" row** (`_buildNavMenu` → `_buildNavTile` onTap):
```dart
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AllergenManagementScreen(
      allergens: widget.allergens,
      userProfile: widget.userProfile,
      onProfileUpdated: widget.onProfileUpdated,
    ),
  ),
),
```

**2. Avatar pencil edit button** (`_buildProfileSection` → `Positioned` container):
Wrap the pencil `Container` in a `GestureDetector`:
```dart
GestureDetector(
  onTap: _openProfileEdit,
  child: Container(/* existing pencil icon */)
)
```
Add method:
```dart
Future<void> _openProfileEdit() async {
  final result = await showProfileEditSheet(context, widget.userProfile);
  if (result != null) widget.onProfileUpdated(result);
}
```
(Requires Phase 7 `profile_edit_sheet.dart` to exist.)

Also update the hardcoded strings in `_buildProfileSection` to use live data:
- `'משתמש'` → `widget.userProfile.displayName ?? 'משתמש'`
- `'user@example.com'` → `widget.userProfile.email ?? ''`

**3. Logout button** (`_buildLogoutButton` → `OutlinedButton.icon onPressed`):
```dart
onPressed: () => showLogoutDialog(context, onConfirmed: _logout),
```
Add method:
```dart
void _logout() {
  widget.onProfileUpdated(const UserProfile());
}
```

---

## Phase 6 — `FavoritesScreen` + Bottom Nav Restructure

**Files created:** `app/lib/screens/favorites_screen.dart`
**Files modified:** `app/lib/screens/main_container.dart`

### 6a — Create `FavoritesScreen`

**Constructor:**
```dart
FavoritesScreen({
  required UserProfile userProfile,
  required List<Allergen> allergens,
  required int currentNavIndex,
  required ValueChanged<int> onNavIndexChanged,
})
```

**MVP shows empty state only** (Supabase product fetch deferred to a future spec):

Centered `Column`:
- `Icon(Icons.favorite_border, size: 72, color: AppColors.onSurfaceVariant)`
- 16 pt gap
- `Text('לא שמרת מוצרים עדיין', style: AppTypography.h3, textAlign: TextAlign.center)`
- 8 pt gap
- `Text('סרוק מוצר כדי להוסיף למועדפים', style: AppTypography.bodyMd, textAlign: TextAlign.center, color: AppColors.onSurfaceVariant)`
- 24 pt gap
- `ElevatedButton(onPressed: () => widget.onNavIndexChanged(1), child: Text('סרוק מוצר'))`

### 6b — Restructure `MainContainer`

**IndexedStack** — replace tab 3 from `SettingsScreen` to `FavoritesScreen`:
```dart
// Remove:
SettingsScreen(userProfile: ..., allergens: ..., onProfileUpdated: ..., ...)
// Add:
FavoritesScreen(
  userProfile: widget.userProfile,
  allergens: widget.allergens,
  currentNavIndex: _currentIndex,
  onNavIndexChanged: _onNavIndexChanged,
),
```

**`BottomNavigationBar` → `NavigationBar` (M3):**

The existing `BottomNavBar` widget (`app/lib/widgets/bottom_nav_bar.dart`) already implements M3 `NavigationBar` with the correct 4 destinations (בית / סריקה / קהילה / מועדפים). Replace the inline `BottomNavigationBar` in `main_container.dart` with:
```dart
bottomNavigationBar: BottomNavBar(
  currentIndex: _currentIndex,
  onTap: _onNavIndexChanged,
),
```
Remove the now-unused inline `BottomNavigationBar` import.

**Settings access via drawer** — update `_onDrawerItemSelected`:
```dart
// Old: mapping {0: 3} (Profile → Settings tab)
// New: push Settings as a route
if (index == 0) {
  Navigator.pop(context); // close drawer
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SettingsScreen(
        userProfile: widget.userProfile,
        allergens: widget.allergens,
        onProfileUpdated: widget.onProfileUpdated,
        currentNavIndex: _currentIndex,
        onNavIndexChanged: _onNavIndexChanged,
        onContactTap: _showContactSheet,
        onAdminBrandsTap: _navigateToAdminBrands,
      ),
    ),
  );
  return;
}
```
Remove `0` from the old `mapping` map (keep `3: 2` for Community Review).

**Gotcha:** `bottom_nav_bar_test.dart` already asserts "מועדפים" as tab 4. No test changes needed there. The `BottomNavBar` widget was already spec-correct — `MainContainer` was the inconsistency.

---

## Phase 7 — `ProfileEditSheet`

**Files created:** `app/lib/widgets/profile_edit_sheet.dart`
**Requires:** Phase 1, Phase 2, Phase 3 (`photo_source_picker.dart`)

**API:**
```dart
Future<UserProfile?> showProfileEditSheet(BuildContext context, UserProfile current) async
// Returns updated UserProfile on save, null on cancel/dismiss.
```

**Sheet:** `showModalBottomSheet(isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))))`

The sheet body wraps in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom))` to handle keyboard.

**Layout (StatefulWidget `_ProfileEditSheetContent`):**

| Zone | Content |
|---|---|
| Grabber | `Container(width: 32, height: 4, color: Color(0xFFE5E7EB), borderRadius: circular(2))`, centred, 8 pt top padding |
| Header row | `Text('ערוך פרופיל', AppTypography.h3)` + `IconButton(Icons.close, onPressed: Navigator.pop)` |
| Avatar block | 80 pt `CircleAvatar` — `Image.memory(base64Decode(...))` if avatarData present, else initials; `GestureDetector` wraps it; `TextButton('החלף תמונה')` below |
| Name field | Label "שם מלא", `TextFormField`, required |
| Email field | Label "דוא״ל", `TextFormField`, optional, email regex |
| Save button | `ElevatedButton(label: 'שמור')`, disabled when name empty |

**`_pickAvatar()`:**
```dart
Future<void> _pickAvatar() async {
  final source = await showPhotoSourcePicker(context);
  if (source == null) return;
  final picked = await ImagePicker().pickImage(
    source: source, imageQuality: 85, maxWidth: 256, maxHeight: 256,
  );
  if (picked == null) return;
  final bytes = await picked.readAsBytes();
  setState(() => _avatarData = base64Encode(bytes));
}
```

**On save:** `Navigator.pop(context, widget.current.copyWith(displayName: ..., email: ..., avatarData: ...))`

**Gotcha:** `base64Encode` / `base64Decode` from `dart:convert`. `Image.memory` accepts the decoded bytes directly. On web, `pickImage(source: ImageSource.camera)` is unsupported — `photo_source_picker.dart` always returns `ImageSource.gallery` on web, so this is safe.

---

## Phase 8 — `Brand` Model, `BrandService`, `AdminBrandFormSheet`, `AdminBrandsScreen` update

**Files created:** `app/lib/models/brand.dart`, `app/lib/services/brand_service.dart`, `app/lib/widgets/admin_brand_form_sheet.dart`
**Files modified:** `app/lib/screens/admin_brands_screen.dart`, `app/lib/screens/main_container.dart`
**Requires:** Phase 3 (`showBrandDeleteDialog`)

### 8a — `Brand` model (`app/lib/models/brand.dart`)

```dart
class Brand {
  final String? id;        // null = new (Supabase auto-generates)
  final String name;
  final String? logoUrl;
  final bool isVerified;
  final DateTime? lastUpdated;
  final String? notes;

  const Brand({required this.name, this.id, this.logoUrl, this.isVerified = false, this.lastUpdated, this.notes});

  Brand copyWith({...});
  factory Brand.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();  // omit id on insert; include on update
}
```

### 8b — `BrandService` (`app/lib/services/brand_service.dart`)

```dart
class BrandService {
  final SupabaseClient _client;
  BrandService(this._client);

  Future<List<Brand>> fetchBrands() async { /* SELECT * FROM brands ORDER BY name */ }
  Future<Brand> saveBrand(Brand brand) async { /* upsert; last_updated = now() */ }
  Future<void> deleteBrand(String id) async { /* DELETE FROM brands WHERE id = id */ }
}
```

### 8c — `AdminBrandFormSheet` (`app/lib/widgets/admin_brand_form_sheet.dart`)

```dart
Future<bool> showBrandFormSheet(
  BuildContext context, {
  Brand? brand,
  required BrandService brandService,
}) async
// Returns true if save/delete completed, false if cancelled.
```

**Layout:** grabber + header (title adapts: "הוספת מותג חדש" vs "עריכת מותג") + ✕ → name field (required, ≤60 chars) → logo URL field (optional, URL regex) → 56 pt logo preview circle (live update via 500ms debounce `Timer`) → verified `Switch` (ON track `Color(0xFF00478D)`) → notes `TextField(minLines: 3, maxLines: 6)` → action row ("שמור שינויים" primary + "ביטול" TextButton) → delete button (edit mode only, `TextButton('מחק מותג', foregroundColor: Color(0xFFDC2626))`).

**Delete flow:** `showBrandDeleteDialog(context)` → if true → `brandService.deleteBrand(brand!.id!)` → `Navigator.pop(context, true)` → `ScaffoldMessenger.showSnackBar("המותג נמחק בהצלחה")`.

**Save flow:** validate → `brandService.saveBrand(...)` → on success dismiss + `ScaffoldMessenger.showSnackBar("המותג נשמר")`; on error show `ScaffoldMessenger.showSnackBar("שגיאה בשמירת המותג", action: "נסה שנית")`.

### 8d — Update `AdminBrandsScreen`

- Change constructor: remove `const`, add `required SupabaseClient client`.
- Replace `List<Map<String, dynamic>> _brands` with `List<Brand> _brands = []` and `late BrandService _brandService`.
- In `initState`: `_brandService = BrandService(widget.client)` then call `_loadBrands()`.
- `_loadBrands()`: fetches from Supabase, `setState(() => _brands = result)`.
- FAB `onPressed`: `showBrandFormSheet(context, brandService: _brandService)` → on `true` call `_loadBrands()`.
- Add per-row edit `IconButton(Icons.edit)` to `_buildBrandItem`; on tap call `showBrandFormSheet(context, brand: brand, brandService: _brandService)` → on `true` call `_loadBrands()`.
- Remove the `NavigationDrawer` import (no longer needed in this screen).

**Wire in `MainContainer._navigateToAdminBrands`:**
```dart
void _navigateToAdminBrands() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AdminBrandsScreen(
        client: Supabase.instance.client,
      ),
    ),
  );
}
```

---

## Phase 9 — Wire Drawer Logout Dialog

**Files modified:** `app/lib/screens/main_container.dart`
**Requires:** Phase 3 (`showLogoutDialog`), Phase 2 (profile clear)

In `MainContainer._onDrawerItemSelected`, add a logout handler. Review `DrawerUserScreen` for which index maps to logout (check `drawer_user_screen.dart` — the exact index must be confirmed before coding). Wire:

```dart
// inside _onDrawerItemSelected, for the logout index:
Navigator.pop(context); // close drawer first
showLogoutDialog(context, onConfirmed: () {
  widget.onProfileUpdated(const UserProfile());
});
```

`widget.onProfileUpdated(const UserProfile())` propagates to `AppShell`, which clears SharedPreferences (Phase 2) and rebuilds — routing to `OnboardingScreen` because `hasCompletedOnboarding` is `false`.

---

## Phase 10 — Tests

### Files to create

| Test file | Covers |
|---|---|
| `test/unit/models/user_profile_test.dart` (extend) | New fields |
| `test/unit/utils/app_dialogs_test.dart` | D-1, D-2, D-3 |
| `test/widgets/screens/allergen_management_screen_test.dart` | New screen |
| `test/widgets/screens/onboarding_step_2_screen_test.dart` | New screen |
| `test/widgets/screens/favorites_screen_test.dart` | New screen |

### Files to modify

| Test file | Change |
|---|---|
| `test/widgets/screens/onboarding_screen_test.dart` | "calls onProfileUpdated" → assert navigation to `OnboardingStep2Screen` instead |
| `test/integration/user_flows_test.dart` | Same — update onboarding flow assertions |
| `test/helpers/test_fixtures.dart` | Add `displayName`, `email`, `avatarData` to `createUserProfile` factory |

### Test checklist

**`user_profile_test.dart` additions:**
- [ ] `displayName` defaults to null
- [ ] `email` defaults to null
- [ ] `avatarData` defaults to null
- [ ] `copyWith(displayName: 'עידן')` sets field and preserves others

**`app_dialogs_test.dart`:**
- [ ] D-1 "לצאת מהוספת מוצר?" title renders
- [ ] D-1 "המשך עריכה" returns `false`
- [ ] D-1 "צא" returns `true`
- [ ] D-2 "התנתק מהחשבון?" title renders
- [ ] D-2 "ביטול" does not call `onConfirmed`
- [ ] D-2 "התנתק" calls `onConfirmed`
- [ ] D-3 "האם למחוק את המותג?" title renders
- [ ] D-3 "מחק" returns `true`
- [ ] D-3 "ביטול" returns `false`
- [ ] All three use `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`

**`allergen_management_screen_test.dart`:**
- [ ] "נהל אלרגיות" appears in AppBar
- [ ] Counter "אלרגנים פעילים: N" reflects initial selection count
- [ ] Allergen grid renders `widget.allergens.length` cards
- [ ] Tapping an unselected card calls `onProfileUpdated` immediately (not deferred)
- [ ] Counter updates after toggle
- [ ] Disclaimer "השינויים נשמרים אוטומטית" is visible
- [ ] Back button pops the route

**`onboarding_step_2_screen_test.dart`:**
- [ ] Headline "כמעט סיימנו!" displays
- [ ] "סיים" disabled when name field is empty
- [ ] "סיים" enabled after typing ≥1 non-whitespace char
- [ ] Tapping "סיים" with valid name calls `onProfileUpdated` with `hasCompletedOnboarding: true`
- [ ] `displayName` on emitted profile matches entered text
- [ ] "אפשר התראות" button is rendered
- [ ] Progress bar has `value: 1.0`
- [ ] Step counter shows "שלב 2 מתוך 2"
- [ ] NOTE: mock `permission_handler` — do NOT await OS-level dialogs in tests; use `pump(Duration.zero)` after tapping the notification button

**`favorites_screen_test.dart`:**
- [ ] "לא שמרת מוצרים עדיין" text renders
- [ ] "סרוק מוצר" CTA renders
- [ ] Tapping "סרוק מוצר" calls `onNavIndexChanged(1)`
- [ ] `Icons.favorite_border` icon renders

**`onboarding_screen_test.dart` modifications:**
- [ ] Change "calls onProfileUpdated" test → assert `find.byType(OnboardingStep2Screen)` after `pumpAndSettle`
- [ ] Assert `onProfileUpdated` is NOT called from step 1

---

## Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| Onboarding test fails after step-1 `_complete()` change | High | Update test in same PR as Phase 4c |
| `permission_handler` iOS Info.plist missing | Medium | Flag in PR description; add `NSUserNotificationUsageDescription` |
| `pumpAndSettle` prohibition | Medium | Applies only to `search_scan_screen_test.dart`; all other test files may use it freely |
| `SharedPreferences` mock missing in new tests | Medium | Add `SharedPreferences.setMockInitialValues({})` in `setUp` for screen tests that mount `AppShell` |
| `AdminBrandsScreen` `const` constructor removal | Low | No existing test for this screen |
| Avatar base64 size in SharedPreferences | Low | 256×256 JPEG ≈ 30–50 KB; acceptable for MVP |
| `MainContainer` tab-3-was-Settings breaks integration tests | Low | No test references tab index 3 as Settings; `bottom_nav_bar_test.dart` already uses "מועדפים" |

---

## Effort estimate

| Phase | Effort |
|---|---|
| 1 — UserProfile extension | 0.5 day |
| 2 — AppShell persistence | 0.5 day |
| 3 — Shared utilities (dialogs + photo picker) | 0.5 day |
| 4 — permission_handler + OnboardingStep2 + OnboardingScreen mod | 1.5 days |
| 5 — AllergenManagementScreen + SettingsScreen wiring | 1 day |
| 6 — FavoritesScreen + MainContainer restructure | 1 day |
| 7 — ProfileEditSheet | 1 day |
| 8 — Brand model + BrandService + AdminBrandFormSheet + AdminBrandsScreen | 1.5 days |
| 9 — Drawer logout wiring | 0.25 day |
| 10 — Tests | 1 day |
| **Total** | **~8.75 days** |
