# Admin Brand Add/Edit Form (modal sheet)
Stitch screen: *(no Stitch screen — derived per `admin-trusted-brands §7.7`)*
Maps to: `app/lib/widgets/admin_brand_form_sheet.dart` (new file)

## 1. Purpose & context

Modal bottom sheet hosting the brand add and edit form. Opened by tapping
"הוספת מותג חדש" (empty/add mode) or the `edit` icon on a brand row
(populated/edit mode) on the `admin-trusted-brands` screen. Save → upsert to
Supabase `brands`. Delete (edit mode only) → confirmation dialog (`_dialogs.md#d-3`).

## 2. Visual layout

`showModalBottomSheet(isScrollControlled: true)` with rounded top corners.
Sheet height ~520 pt; expands with keyboard.

| Zone | Content |
|---|---|
| Grabber | 4 pt × 32 pt `#E5E7EB` pill |
| Header row | Title ("הוספת מותג חדש" or "עריכת מותג") RTL-leading + ✕ RTL-trailing |
| Brand name field | Label "שם המותג" + `TextField` (required) |
| Logo URL field | Label "קישור ללוגו" + `TextField` (optional) |
| Logo preview | 56 pt circle showing the URL's image or initial-letter fallback |
| Verified toggle row | "סטטוס אימות" label + Switch widget |
| Notes field | Label "הערות (אופציונלי)" + multi-line `TextField` |
| Action row | "שמור שינויים" primary + "ביטול" text button |
| Delete button | "מחק מותג" — destructive text, edit-mode only |

## 3. Component inventory

| # | Component | Notes |
|---|---|---|
| 1 | Sheet + grabber + header | Same pattern as `profile-edit.md` |
| 2 | Brand name `TextFormField` | Required, max 60 chars |
| 3 | Logo URL `TextFormField` | Optional, `keyboardType: url` |
| 4 | Logo preview circle | Updates on URL field debounce; falls back to initial letter (see `admin-trusted-brands §7.4`) |
| 5 | Verified toggle | Reuses `admin-trusted-brands §4.5` toggle spec (28 × 48 pt pill `Switch`) |
| 6 | Notes field | `TextField(minLines: 3, maxLines: 6)`, optional |
| 7 | Save primary | `PrimaryButton(label: 'שמור שינויים')` |
| 8 | Cancel link | `TextButton('ביטול')` foreground `#374151` |
| 9 | Delete button | Edit-mode only — `TextButton('מחק מותג')` foreground `#DC2626`, 24 pt above bottom safe-area, separated by a 1 pt `#F3F4F6` divider |

## 4. Sub-components / element design

### 4.1 Logo preview
- 56 pt circle, `#EBF4FF` background.
- Renders `Image.network(_logoUrlController.text)` if URL is non-empty and valid; otherwise the initial letter of the brand name in Inter SemiBold 22 pt `#00478D`.
- On image load error: falls back to initial letter (same as the brand list row).

### 4.2 Verified toggle
- 28 pt × 48 pt pill, `BorderRadius.circular(9999)`.
- ON: track `#00478D`, thumb at RTL-left end.
- OFF: track `#E1E3E4`, thumb at RTL-right end.
- Label above: "סטטוס אימות" — Inter Medium 12 pt `#727783`.
- Below toggle: helper text Inter Regular 12 pt `#9CA3AF`:
  - ON: "מותג זה מוצג כמותג מאומת בכל המוצרים".
  - OFF: "מותג זה לא מוצג כמאומת".

### 4.3 Validation
- Brand name: required, `.trim().isNotEmpty`, ≤ 60 chars. Error copy: "נא למלא שם מותג".
- Logo URL: optional; if filled, must match a URL regex. Error: "כתובת לא תקינה".
- Notes: optional, ≤ 500 chars.

### 4.4 Save flow
- Save tap → `BrandService.saveBrand(Brand(...))` upsert:
  - Add mode: insert new row; `id` is null → Supabase auto-generates.
  - Edit mode: update existing row by id.
- On success: sheet dismisses, brand list refreshes, `SnackBar`: "המותג נשמר".
- On error: stays open, `SnackBar`: "שגיאה בשמירת המותג" with a "נסה שנית" action.

### 4.5 Delete flow (edit mode)
- "מחק מותג" tap → opens `_dialogs.md#d-3` (brand delete confirmation).
- Confirmed: `BrandService.deleteBrand(id)`; sheet + dialog both dismiss; brand list refreshes; `SnackBar`: "המותג נמחק בהצלחה".
- Cancelled: dialog dismisses; sheet remains.

## 5. States & interactions

| State | Trigger | Visual |
|---|---|---|
| Add mode | Open via "הוספת מותג חדש" | All fields empty; verified toggle defaults OFF; no delete button |
| Edit mode | Open via per-row edit icon | Fields pre-populated; delete button visible at bottom |
| Field focus | Tap field | Border `#00478D` 1.5 pt |
| Logo URL changed | Debounce 500 ms | Logo preview re-renders |
| Save (valid) | Tap "שמור שינויים" | Loading spinner replaces label; on success → dismiss |
| Save (invalid) | Tap "שמור" with errors | Inline field errors; sheet stays open |
| Delete (edit mode) | Tap "מחק מותג" | Dialog D-3 opens |
| Cancel / scrim | Tap ✕ or scrim | Sheet dismisses; no changes |

## 6. Data & controller contract

### 6.1 Sheet API

```dart
Future<bool> showBrandFormSheet(
  BuildContext context, {
  Brand? brand,   // null → add mode; non-null → edit mode
}) async {
  // Returns true if a save/delete completed (caller refreshes list);
  // false if cancelled.
}
```

### 6.2 Brand model

```dart
class Brand {
  final String? id;
  final String name;
  final String? logoUrl;
  final bool isVerified;
  final DateTime? lastUpdated;
  final String? notes;
}
```

### 6.3 BrandService methods used

- `saveBrand(Brand brand) → Future<Brand>` — upsert; `last_updated = now()` on save.
- `deleteBrand(String id) → Future<void>`.

## 7. Open questions

### 7.1 Logo upload vs URL only
MVP captures `logo_url` as text. A future iteration may add image upload to
Supabase Storage. Not in scope here.

### 7.2 Admin gating
Only admin users see this sheet because `admin-trusted-brands` is admin-only
(per its §5.9). No additional gating needed at the sheet level.
