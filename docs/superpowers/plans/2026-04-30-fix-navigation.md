# Navigation Fix Implementation Plan

**Goal:** Fix broken navigation so all screens are connected properly.

**Architecture:** Create `MainContainer` with `IndexedStack` for bottom tabs, replace direct Navigator.push with state-based navigation.

**Tech Stack:** Flutter, Material 3 NavigationBar

---

## Current Broken Flow
```
Onboarding → SearchScreenContent (OLD) → FAB → Community (WRONG)
```

## Target Flow
```
Onboarding → MainContainer[HomeScreen] → Bottom Nav (Home/Scan/Community/Settings)
                        ↓
                 FAB → AddProductWizard
```

---

## Tasks

### Task 1: Create MainContainer with IndexedStack ✅ DONE

- Created `app/lib/screens/main_container.dart`
- IndexedStack with 4 tabs: Home, Scan, Community, Settings
- NavigationBar with Hebrew labels

### Task 2: Update main.dart ✅ DONE

- Changed entry from `SearchScreenContent` to `MainContainer`
- Added import for MainContainer

### Task 3: Add callbacks to SettingsScreen ✅ DONE

- Added `onContactTap` and `onAdminBrandsTap` params
- Connected menu items to callbacks

### Task 4: AddContactSheet method to MainContainer

- Add `_showContactSheet` method using showModalBottomSheet
- Add `_navigateToAdminBrands` method using Navigator.push

### Task 5: Connect Feedback Success Screen

- Modify `feedback_screen.dart` to push `FeedbackSuccessScreen` after submit

### Task 6: Connect Drawer to HomeScreen

- Add Drawer to HomeScreen scaffold
- Connect DrawerUserScreen with navigation callbacks

### Task 7: Test all navigation paths

- Manual verification of all screens reachable

---

## After Fix - All Screens Reachable

| Screen | Status |
|--------|--------|
| home_screen.dart | ✅ Tab 0 in MainContainer |
| search_scan_screen.dart | ✅ Tab 1 in MainContainer |
| community_screen.dart | ✅ Tab 2 in MainContainer |
| settings_screen.dart | ✅ Tab 3 in MainContainer |
| contact_screen.dart | ✅ Modal from Settings |
| admin_brands_screen.dart | ✅ From Settings |
| add_product_screen.dart | ✅ Opens from scan tab |
| feedback_success_screen.dart | ✅ After feedback submit |
| product_details.dart | ✅ From search results |
| feedback_screen.dart | ✅ From product details |
| drawer_user_screen.dart | ✅ From Home menu |

---

## Execution Log

- Worktree: `.worktrees/fix-navigation` (branch: fix/navigation)
- Baseline: 188 tests passing
- Task 1, 2, 3 completed
- Task 4 in progress