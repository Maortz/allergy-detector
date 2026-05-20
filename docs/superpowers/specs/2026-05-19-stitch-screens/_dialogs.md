# Shared Confirmation Dialogs

Three modal `AlertDialog`s reused across the spec set. Each is RTL, uses
`AppTypography` tokens, and follows the same structural pattern: title (Public
Sans SemiBold 16 pt, `#1F2937`) → body (Inter Regular 14 pt, `#374151`) →
`Row` of action `TextButton`s (right-aligned in RTL, destructive action gets
`#DC2626` foreground).

> No Stitch screen exists for these dialogs — they are derived from the
> per-screen behavior specs (`add-product-step-* §5`, `nav-drawer-user §5.4`,
> `settings-profile §5.6`, `admin-trusted-brands §5.8`). They are written here
> once so per-screen specs reference rather than re-spec.

---

## D-1 · Wizard exit confirmation

Shown when the user taps `cancel` (✕) on any Add-Product wizard step (1–4)
with non-empty wizard state.

- **Title:** "לצאת מהוספת מוצר?"
- **Body:** "הנתונים שהזנת לא יישמרו."
- **Actions (RTL order, right → left):**
  - **"המשך עריכה"** (cancel) — `TextButton`, foreground `#374151`. Dismisses the dialog; wizard stays open.
  - **"צא"** (confirm exit) — `TextButton`, foreground `#DC2626`. Pops the wizard route via `Navigator.pop(context)` (full pop, all wizard state discarded).

If wizard state is empty (user is on Step 1 with no input), the dialog is
skipped and the wizard pops directly.

**Used by:** `add-product-step-1-barcode §5`, `-step-2-photos §5`,
`-step-3-contains §5`, `-step-4-may-contain §5`.

```dart
Future<bool> showWizardExitDialog(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('לצאת מהוספת מוצר?'),
      content: const Text('הנתונים שהזנת לא יישמרו.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('המשך עריכה'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('צא'),
        ),
      ],
    ),
  );
  return shouldExit ?? false;
}
```

---

## D-2 · Logout confirmation

Shown when the user taps "התנתקות" in the user or admin nav drawer, OR taps
"התנתק מהחשבון" in Settings.

- **Title:** "התנתק מהחשבון?"
- **Body:** "כל הגדרות הפרופיל ישמרו במכשיר. תוכל להתחבר שוב בכל עת."
- **Actions:**
  - **"ביטול"** — `TextButton`, foreground `#374151`. Dismiss; drawer/Settings stays.
  - **"התנתק"** — `TextButton`, foreground `#DC2626`. Confirms logout: clears `UserProfile` from SharedPreferences (`display_name`, `email`, `selected_allergen_ids`, `avatar_data`, `weekly_scans_count`, `product_filter_level`), sets `has_completed_onboarding = false`, and navigates to `OnboardingScreen` via `Navigator.pushAndRemoveUntil`.

> MVP has no authentication. "Logout" means clearing local preferences only.

**Used by:** `nav-drawer-user §5.4`, `nav-drawer-admin §5.3`, `settings-profile §5.6`.

---

## D-3 · Brand delete confirmation (admin)

Shown when the admin taps "מחק מותג" in the brand edit form (`admin-brand-form.md`).

- **Title:** "האם למחוק את המותג?"
- **Body:** "פעולה זו אינה ניתנת לביטול. מוצרים המקושרים למותג יישארו במאגר אך יסומנו ללא מותג."
- **Actions:**
  - **"ביטול"** — `TextButton`, foreground `#374151`.
  - **"מחק"** — `TextButton`, foreground `#DC2626`. Calls `BrandService.deleteBrand(id)`, closes both the dialog and the parent edit sheet, refreshes the brand list, shows a `SnackBar`: "המותג נמחק בהצלחה".

**Used by:** `admin-trusted-brands §5.8`, `admin-brand-form.md §5`.

---

## Visual conventions (all dialogs)

- `AlertDialog.shape`: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`.
- `AlertDialog.backgroundColor`: `Colors.white`.
- `AlertDialog.titlePadding`: `EdgeInsets.fromLTRB(24, 24, 24, 8)`.
- `AlertDialog.contentPadding`: `EdgeInsets.fromLTRB(24, 0, 24, 16)`.
- `AlertDialog.actionsPadding`: `EdgeInsets.fromLTRB(8, 0, 8, 8)`.
- Wrap with `Directionality(textDirection: TextDirection.rtl, ...)` if not already inside an RTL context.
- Dismissible by tapping the scrim (`barrierDismissible: true`) — equivalent to the cancel action.
