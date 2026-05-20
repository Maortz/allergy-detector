# Profile Edit (modal sheet)
Stitch screen: *(no Stitch screen — derived per `settings-profile §4.1` "ערוך פרופיל" entry point)*
Maps to: `app/lib/widgets/profile_edit_sheet.dart` (new file)

## 1. Purpose & context

Modal bottom sheet opened by tapping "ערוך פרופיל" (or the avatar pencil) in
Settings. Lets the user edit `displayName`, `email`, and the avatar image.
Edits are committed only on tapping "שמור"; tapping "ביטול" or scrim-dismiss
discards changes.

## 2. Visual layout

`showModalBottomSheet` with `isScrollControlled: true` and rounded top corners
(`BorderRadius.vertical(top: Radius.circular(16))`). Sheet height ~440 pt
(content-driven; expands with keyboard).

| Zone | Content |
|---|---|
| Grabber | 4 pt × 32 pt `#E5E7EB` pill, centred 8 pt from top |
| Header row | Title "ערוך פרופיל" RTL-leading + `cancel` ✕ RTL-trailing |
| Avatar block | 80 pt circular avatar centred + "החלף תמונה" `TextButton` below |
| Name field | Label "שם מלא" + `TextField` |
| Email field | Label "דוא״ל" + `TextField` |
| Save button | "שמור" full-width primary |

## 3. Component inventory

| # | Component | Source |
|---|---|---|
| 1 | Sheet container | Material `showModalBottomSheet` |
| 2 | Grabber | Screen-specific decoration |
| 3 | Header row title + close | Public Sans SemiBold 16 pt `#1F2937` + `IconButton` |
| 4 | Avatar circle | 80 pt, base64 from `UserProfile.avatarData` or initials fallback |
| 5 | "החלף תמונה" link | `TextButton` `#00478D` |
| 6 | Form fields | Standard outlined `TextField` (matches `contact-us §4.3`) |
| 7 | Save primary | `_components-glossary.md#primary-button` |

## 4. Sub-components / element design

### 4.1 Avatar block
- Container: 80 pt circle, `BorderRadius.circular(40)`, background `#EBF4FF`, border 2 pt solid `#BFDBFE`.
- Inside: either `Image.memory(base64Decode(avatarData), fit: BoxFit.cover)` or initials text (Inter SemiBold 28 pt `#00478D`) on `#EBF4FF` background.
- Tapping the avatar OR tapping "החלף תמונה" below triggers `image_picker` (`ImageSource.gallery` only on web; both `camera` and `gallery` on mobile via a `showModalBottomSheet` picker).

### 4.2 Form fields

Both fields use the same outlined `InputDecoration` as `contact-us §4.3`:

| Field | Type | Placeholder | Validation |
|---|---|---|---|
| שם מלא | `TextFormField` single-line, `keyboardType: name` | "הקלד שם מלא" | Required; non-empty |
| דוא״ל | `TextFormField` `keyboardType: email` | "name@example.com" | Optional in MVP (no auth); if filled, must match email regex |

Labels: Inter SemiBold 14 pt `#191C1D`, right-aligned, 8 pt below.

### 4.3 Save button
- `PrimaryButton(label: 'שמור', onPressed: _isValid ? _save : null)`.
- Full-width, height 48 pt, 16 pt margins, 16 pt top margin, 8 pt bottom.
- Disabled when the name field is empty.

## 5. States & interactions

| State | Trigger | Visual |
|---|---|---|
| Default | Sheet open | Fields pre-populated from `UserProfile`; Save enabled if name present |
| Avatar picker | Tap avatar or "החלף תמונה" | OS picker; chosen image preview replaces avatar circle |
| Field focus | Tap field | Border `#00478D` 1.5 pt; floating label `#00478D` |
| Save | Tap "שמור" | Updated `UserProfile` emitted via `onProfileUpdated`; sheet dismisses |
| Cancel | Tap ✕ or scrim | Sheet dismisses; no state changes |
| Validation error | Email malformed | Error text below field; Save still enabled (email is optional) but tapping Save fails silently or re-focuses field |

## 6. Data & controller contract

```dart
Future<UserProfile?> showProfileEditSheet(
  BuildContext context,
  UserProfile current,
) async {
  // Returns the updated profile on save, or null on cancel.
}
```

### 6.1 Avatar persistence
- Selected image is converted to base64 (jpeg-encoded, 256×256 max resolution).
- Stored in `SharedPreferences` under `avatar_data`.
- No Supabase upload in MVP (per `settings-profile §7.6` resolution).

## 7. Open questions

### 7.1 Email field role
MVP has no authentication; the email field is currently informational only.
If a future iteration adds password-less login, it becomes load-bearing.

### 7.2 Avatar size cap
256×256 jpeg base64 ≈ 30–50 KB in SharedPreferences. Acceptable; if it grows
beyond ~100 KB consider switching to file storage in app documents directory.
