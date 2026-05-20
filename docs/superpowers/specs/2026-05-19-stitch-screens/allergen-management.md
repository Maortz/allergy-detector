# Allergen Management
Stitch screen: *(no Stitch screen — derived per `settings-profile §7.5`)*
Maps to: `app/lib/screens/allergen_management_screen.dart` (new file)

## 1. Purpose & context

The user's allergen-profile edit screen, reached from Settings →
"נהל אלרגיות". Lets the user add or remove allergens from
`UserProfile.selectedAllergenIds` after the initial onboarding pass. Visually
and structurally identical to `onboarding-allergen-selection §4.5` (3-column
selection grid + bordered+badge selected state per DD-13), but framed inside a
detail-bar app-bar (DD-15) instead of the standalone onboarding shell.

Changes save **immediately** on each toggle — no explicit "save" button. The
detail-bar back arrow returns to Settings with the updated profile already
persisted.

## 2. Visual layout breakdown

| Zone | Content |
|---|---|
| App bar | Detail-bar (DD-15): title "נהל אלרגיות", `arrow_back_ios` trailing |
| Counter row | "אלרגנים פעילים: N" right-aligned, Inter Regular 13 pt `#6B7280` |
| Allergen grid | 3-column grid identical to onboarding §4.5 |
| Disclaimer footer | Inter Regular 11 pt `#6B7280` — explains immediate-save behavior |

No bottom navigation (pushed sub-route from Settings).

## 3. Component inventory

| # | Component | Source |
|---|---|---|
| 1 | App bar | `_components-glossary.md#app-bar` — detail-bar variant |
| 2 | Counter row | Screen-specific |
| 3 | Allergen selection card grid | `_components-glossary.md#allergen-chip` Variant C |
| 4 | Disclaimer text | Screen-specific |

## 4. Sub-components / element design

### 4.1 Counter row
- Right-aligned (RTL) within 16 pt margins.
- "אלרגנים פעילים: N" where N = `userProfile.selectedAllergenIds.length`.
- Inter Regular 13 pt, `#6B7280`. 12 pt above the grid, 16 pt below the app bar.

### 4.2 Allergen selection grid
- Identical structure to `onboarding-allergen-selection §4.5`:
  - 3-column `GridView`, `crossAxisSpacing: 12`, `mainAxisSpacing: 12`, `childAspectRatio: 1.0`.
  - Cards 16 pt horizontal margins.
- Unselected / selected states per `_components-glossary.md#allergen-chip` Variant C (bordered + badge per DD-13).
- Tapping toggles membership in `selectedAllergenIds`; widget rebuilds with the updated set.
- All 12+ allergens from the catalog are rendered (Step-3 grouping not used here — flat alphabetical or seed-order list).

### 4.3 Disclaimer footer
- "השינויים נשמרים אוטומטית" — Inter Regular 11 pt, `#6B7280`, `TextAlign.center`.
- 16 pt horizontal margin, 12 pt bottom margin, sticky to the bottom edge above safe area.

## 5. States & interactions

| State | Trigger | Visual |
|---|---|---|
| Default | Screen mount | Grid renders with current selections marked; counter shows N |
| Toggle on | Tap unselected card | Card → selected (bordered + badge); counter increments; SharedPreferences write |
| Toggle off | Tap selected card | Card → unselected; counter decrements; SharedPreferences write |
| Back | Tap `arrow_back_ios` | Pop route with `userProfile` already in updated state |
| Empty selection | All cards untapped | Counter shows "0"; no validation block (zero selections is valid post-onboarding) |

## 6. Data & controller contract

### 6.1 Inputs

```dart
AllergenManagementScreen({
  required List<Allergen> allergens,
  required UserProfile userProfile,
  required ValueChanged<UserProfile> onProfileUpdated,
})
```

### 6.2 Local state

```dart
late UserProfile _profile;          // mirror of widget.userProfile
void _toggle(String allergenId) {
  setState(() => _profile = _profile.toggleAllergen(allergenId));
  widget.onProfileUpdated(_profile);  // immediate save up to AppShell → SharedPreferences
}
```

### 6.3 SharedPreferences key
- `selected_allergen_ids` — same key written by onboarding step 1 and read by all consumers.

## 7. Open questions / design-vs-app deltas

### 7.1 No Stitch screen
Derived spec; visual parity with onboarding ensures no design drift. No PM
call required.

### 7.2 Grouping vs flat list
Onboarding uses a flat 3-column grid (no sub-section headers). Step 3
wizard groups allergens into 3 categories. This screen follows onboarding's
flat layout for simplicity; switching to the grouped layout would require
duplicating the Step-3 grouping logic. Coordinator call — flat wins unless PM
requests otherwise.
