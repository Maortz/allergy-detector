# Report Issue / דיווח על תקלה
Stitch screen: projects/16588854804615693446/screens/a6741117c9f14b84938c4abda143a5dd
Maps to: app/lib/screens/feedback_screen.dart

## 1. Purpose & context

This screen lets a user report a data error on a specific product (e.g. wrong allergen list, bad image). It is reached from a product-detail screen by tapping a report/flag action. The product name and barcode are passed in as context so the form is pre-identified.

On successful submission the user is pushed to the `report-success` screen (`FeedbackSuccessScreen`). On failure a snackbar is shown.

The screen is a **modal detail flow** — it has its own app bar with a back/close affordance. The Stitch screenshot shows the bottom nav at the bottom of the canvas; see section 7.1 for the visibility delta.

---

## 2. Visual layout breakdown

Layout is a single-scroll `Column` inside `Scaffold`, RTL, 16 pt horizontal padding throughout. Top-to-bottom reading order (RTL: right-to-left within rows):

`
+-----------------------------------------+
| AppBar: <- (back)    "דיווח על שגיאה"   |  56 pt
+-----------------------------------------+
| Product context card                    |  ~72 pt
|   [thumbnail 40x40]  Name               |
|                       Barcode           |
+-----------------------------------------+
| Heading: "מה הסיבה לדיווח?"             |
+-----------------------------------------+
| Issue-type chip grid (2 x 2)            |  ~160 pt
|  [אלרגנים שגויים]  [רכיבים לא נכונים]  |
|  [אחר]             [תמונה לא תואמת]    |
+-----------------------------------------+
| Heading: "פרטים נוספים (אופציונלי)"    |
| Multi-line text field (4+ rows)         |  ~104 pt
|   placeholder: "תאר את הבעיה שמצאת..." |
+-----------------------------------------+
| Heading: "העלאת תמונה"                  |
| Image-upload dashed box                 |  ~88 pt
|   [camera+ icon] "צלם תמונה של תווית   |
|    המוצר" + hint sub-text              |
+-----------------------------------------+
| PrimaryButton: "שלח דיווח לבדיקה"  <   |  48 pt
+-----------------------------------------+
| Bottom nav (DD-2 canonical)             |  56 pt
+-----------------------------------------+
`

Overall Stitch canvas: 2448 x 780 px. Content is scrollable when the soft keyboard is raised.

---

## 3. Component inventory

| # | Component | Shared? | Notes |
|---|-----------|---------|-------|
| 1 | App bar — detail/back variant | Yes — see `_components-glossary.md#app-bar` | Title "דיווח על שגיאה", back arrow RTL-leading |
| 2 | Product context card | Screen-specific | Thumbnail + name + barcode; read-only |
| 3 | Section heading labels | Screen-specific | "מה הסיבה לדיווח?" / "פרטים נוספים (אופציונלי)" / "העלאת תמונה" |
| 4 | Issue-type selection chip grid | Screen-specific | 2x2 radio-group of toggle chips |
| 5 | Additional details text field | Screen-specific | Multi-line, optional, RTL |
| 6 | Image upload zone | Screen-specific | Dashed-border tap target, camera icon, optional |
| 7 | Submit primary button | Yes — see `_components-glossary.md#primary-button` | Label "שלח דיווח לבדיקה", standard Medical Blue |
| 8 | Bottom navigation bar | Yes — see `_components-glossary.md#bottom-nav` | DD-2 canonical; active tab "סריקה" (index 1); see section 7.1 re: visibility delta |

---

## 4. Sub-components / element design

### 4.1 App bar

See `_components-glossary.md#app-bar` — **detail bar variant**.

- Title: "דיווח על שגיאה" — AppTypography.titleMedium (Public Sans SemiBold 16 pt, `#1F2937`).
- RTL-leading (right side): `arrow_back_ios` icon, AppColors.onSurfaceVariant `#374151`, 24 pt.
- RTL-trailing (left side): none.
- Background `#FFFFFF`, elevation 0.

### 4.2 Product context card

- Container: `#FFFFFF` background, BorderRadius.circular(12), border 1 pt solid `#E5E7EB`, padding 12 pt all sides.
- Internal Row (RTL — thumbnail on the right, text column on the left):
  - **Thumbnail:** ClipRRect(borderRadius: BorderRadius.circular(8)) wrapping Image.network, 40 x 40 pt. Falls back to Icons.fastfood in `#9CA3AF` if URL is null.
  - **Text Column** (crossAxisAlignment.start, 8 pt gap from thumbnail):
    - Product name: Public Sans SemiBold 14 pt, `#1F2937`. Example: "חלב אורגני 3%".
    - Barcode: Inter Regular 12 pt, `#6B7280`. Example: "7290001234567".
- Card: 16 pt below app bar, 16 pt horizontal margins.

### 4.3 Section heading labels

- Font: Inter SemiBold 13 pt, `#1F2937`.
- Spacing: 20 pt above each heading; 8 pt between heading and its content.

Three labels in order:
1. "מה הסיבה לדיווח?" — above the chip grid.
2. "פרטים נוספים (אופציונלי)" — above the text field.
3. "העלאת תמונה" — above the image upload zone.

### 4.4 Issue-type selection chip grid

A 2 x 2 layout of toggle chips with radio-group semantics (exactly one selected at all times). Default: "אלרגנים שגויים" selected on open.

**Chip dimensions:**
- Width: (screenWidth - 48) / 2  [16 pt margin + 8 pt gap + 16 pt margin].
- Height: 56 pt.
- Shape: BorderRadius.circular(12).

**Unselected state:**
- Background: `#FFFFFF`. Border: 1.5 pt solid `#E5E7EB`.
- Icon: 22 pt, `#6B7280`. Label: Inter Medium 13 pt, `#374151`.

**Selected state:**
- Background: `#EBF4FF` (light Medical-Blue tint, token TBD).
- Border: 2 pt solid `#00478D` (AppColors.primary).
- Icon: 22 pt, `#00478D`. Label: Inter SemiBold 13 pt, `#00478D`.

**Internal layout:** Column(mainAxisAlignment: center) — icon, 4 pt gap, label.

**Four chips:**

| Hebrew label | Material icon | Key |
|---|---|---|
| "אלרגנים שגויים" | `warning_amber` | `allergens_wrong` |
| "רכיבים לא נכונים" | `list_alt` | `ingredients_wrong` |
| "תמונה לא תואמת" | `image_not_supported` | `image_mismatch` |
| "אחר" | `more_horiz` | `other` |

**RTL grid order** (right to left, row 1 then row 2):
- Row 1: "אלרגנים שגויים" (right) | "רכיבים לא נכונים" (left)
- Row 2: "אחר" (right) | "תמונה לא תואמת" (left)

### 4.5 Additional details text field

- Flutter: TextField with OutlineInputBorder.
- minLines: 4, maxLines: null (expands on input).
- Border resting: 1 pt solid `#E5E7EB`, BorderRadius.circular(12).
- Border focused: 2 pt solid `#00478D`.
- Background: `#FFFFFF`.
- Placeholder: "תאר את הבעיה שמצאת..." — Inter Regular 13 pt, `#9CA3AF`.
- Input text: Inter Regular 14 pt, `#1F2937`.
- textDirection: TextDirection.rtl.
- **Optional** — no required marker; no submission guard on emptiness.

### 4.6 Image upload zone

- Container: dashed border (1.5 pt dashed `#D1D5DB`), BorderRadius.circular(12), background `#F9FAFB`, height ~88 pt, full-width within 16 pt margins.
- Internal Column(mainAxisAlignment: center, crossAxisAlignment: center):
  - Icon: `add_a_photo` or `camera_alt`, 28 pt, `#6B7280`.
  - Primary label: "צלם תמונה של תווית המוצר" — Inter SemiBold 13 pt, `#374151`, 6 pt below icon.
  - Hint text: "העלאת תמונה של רכיבים ואלרגנים תאמת את הדיווח" — Inter Regular 11 pt, `#9CA3AF`, 4 pt below primary label.
- Tap action: ImagePicker.pickImage or showModalBottomSheet offering camera/gallery choice.
- After image selected: zone replaced by Stack — image thumbnail fills zone + circular X clear button at top-trailing corner (`#FFFFFF` icon on semi-opaque `#00000066` circular background).
- Upload is **optional**; no validation block on submission.

### 4.7 Submit primary button

See `_components-glossary.md#primary-button` — **Standard CTA variant**.

- Label: "שלח דיווח לבדיקה".
- RTL-trailing icon (visual left): `send` icon, 18 pt, `#FFFFFF`.
- Width: full-width, 16 pt horizontal margins. Height: 48 pt, BorderRadius.circular(12).
- Background: AppColors.primary `#00478D`. Font: Inter SemiBold 14 pt, `#FFFFFF`.
- Top margin: 24 pt.

---

## 5. States & interactions

### 5.1 Chip selection (radio-group)

- Tap unselected chip: selects it, deselects previous (setState).
- Tap already-selected chip: no change.
- One chip always selected; cannot reach empty state.

### 5.2 Text field states

| State | Border | Background |
|-------|--------|------------|
| Resting | 1 pt `#E5E7EB` | `#FFFFFF` |
| Focused | 2 pt `#00478D` | `#FFFFFF` |
| Filled (blurred) | 1 pt `#E5E7EB` | `#FFFFFF` |

No character counter displayed.

### 5.3 Image upload zone states

| State | Visual |
|-------|--------|
| Empty | Dashed zone with icon + labels (§4.6) |
| Image selected | Thumbnail fills zone; X button at top-trailing corner |
| Tapped | Camera/gallery picker opens |

### 5.4 Submit button states

| State | Visual |
|-------|--------|
| Default (enabled) | `#00478D` fill, white label + send icon |
| Pressed | `#003F7D` fill (10% darkened) |
| Loading | CircularProgressIndicator(color: white, strokeWidth: 2) replaces label; onPressed: null |
| Disabled | N/A — design has no disabled state; button always enabled |

### 5.5 Submission flow

1. User taps submit — _isSubmitting = true — button shows spinner.
2. onSubmit(type, message, image?) awaited.
3. Success: Navigator.pushReplacement to FeedbackSuccessScreen (report-success screen).
4. Error: ScaffoldMessenger.showSnackBar with "שגיאה: [error]", _isSubmitting = false.

### 5.6 Back navigation

Tapping the back arrow pops the route without submitting. No confirmation dialog in the Stitch design.

---

## 6. Data & controller contract

### 6.1 Widget interface (design-target signature)

`dart
FeedbackScreen({
  required String productId,           // Supabase product UUID
  required String productName,         // e.g. "חלב אורגני 3%"
  required String? productBarcode,     // e.g. "7290001234567"; null hides barcode row
  required String? productImageUrl,    // thumbnail URL; null shows placeholder icon
  required Future<void> Function(
    String type,      // chip key
    String message,   // may be empty string — field is optional
    XFile? image,     // null if user did not upload
  ) onSubmit,
})
`

### 6.2 Local controller state

`dart
String _selectedType = 'allergens_wrong';   // design default
final TextEditingController _messageController = TextEditingController();
XFile? _selectedImage;                       // null = no image
bool _isSubmitting = false;
`

### 6.3 Issue type keys

| Hebrew label | Key |
|---|---|
| "אלרגנים שגויים" | `allergens_wrong` |
| "רכיבים לא נכונים" | `ingredients_wrong` |
| "תמונה לא תואמת" | `image_mismatch` |
| "אחר" | `other` |

### 6.4 Submission payload

The onSubmit callback delivers: chip key (type), trimmed message text (may be empty), and optional XFile image. The screen does not call SupabaseClient directly — the caller wires the callback.

---

## 7. Open questions / design-vs-app deltas

### 7.1 Bottom nav visibility — routing delta

The Stitch screenshot renders the DD-2 canonical bottom nav at the bottom of the canvas (active tab: "סריקה", index 1). The current app pushes FeedbackScreen as a standalone MaterialPageRoute without a bottom nav.

**Recommendation:** Decide whether FeedbackScreen should be embedded within the MainContainer scaffold or remain a full-screen modal route. Other product-detail screens (product-details-avoid, product-details-safe) similarly show the nav in Stitch — this is a recurring pattern. No code change pending product decision.

### 7.2 Issue-type category mismatch — app delta

Current app _feedbackTypes keys: allergen_missing / allergen_wrong / product_info_wrong / other.
Design chips: allergens_wrong / ingredients_wrong / image_mismatch / other.

**Delta:** four categories differ in keys and Hebrew labels. App and any Supabase enum/column storing the type must be updated. allergen_missing has no design equivalent.

### 7.3 Image upload — missing in app

FeedbackScreen has no image-upload feature. The design prominently includes it as a dedicated upload zone.

**Delta:** requires image_picker dependency and a Supabase Storage upload path. The onSubmit callback signature must accept XFile?.

### 7.4 Details field — required vs. optional — app delta

App guards submission with: if (_messageController.text.trim().isEmpty) return — making the field effectively required.
Design labels it "פרטים נוספים (אופציונלי)" with no required marker.

**Delta:** remove the empty-text guard; a chip selection alone (with or without image) is sufficient to submit.

### 7.5 Product context card — missing fields — app delta

App receives productName only. Design shows product name + barcode in a card with a thumbnail image.

**Delta:** add productBarcode and productImageUrl to the widget constructor.

### 7.6 Submit button label — minor copy delta

App: "שלח דיווח". Design: "שלח דיווח לבדיקה".

**Delta:** update button label string.

### 7.7 Default selected chip — app delta

App initialises _selectedType = 'other'. Design pre-selects "אלרגנים שגויים" (allergens_wrong).

**Delta:** change initialiser to _selectedType = 'allergens_wrong'.