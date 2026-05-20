# הוספת מוצר - שלב 2 / Add Product — Step 2 (Photos)
Stitch screen: projects/16588854804615693446/screens/bbda540783f94818b581f4d7dd8f7811
Maps to: app/lib/screens/add_product_screen.dart

## 1. Purpose & context  (wizard step 2 of 4)

This is step 2 of a 4-step "Add New Product" wizard. The user has already entered the product name and barcode (step 1); now they are asked to photograph two views of the product packaging — the **product front** (חזית המוצר) and the **ingredients list** (רשימת רכיבים). Steps 3 and 4 collect allergen selections.

The screen serves a dual purpose: (a) capture product images for the Supabase database so future users see the packaging, and (b) provide a photo of the ingredients list that may be used to assist allergen parsing. Both photos are optional — the screen offers a "דילוג והזנה ידנית" (Skip — Manual Entry) escape hatch.

Progress at this step: step 2 of 4 → **50% complete**.

No bottom navigation bar is shown — this is a modal wizard flow (see _components-glossary.md#bottom-nav).

## 2. Visual layout breakdown

Canvas: 780 × 2714 px @2× (390 pt wide). Background: `#F8F9FA`.

### App bar (top)
- White background, no elevation.
- **RTL leading (right):** "הוספת מוצר חדש" — Public Sans SemiBold 16 pt, `#1F2937`.
- **RTL trailing (left):** `arrow_back` / `✕` close icon, `#374151`, 24 pt — exits the wizard entirely.
- See [_components-glossary.md#app-bar](_components-glossary.md#app-bar) — Wizard bar variant.

### Progress indicator
- Below app bar, full-width, ~12 pt vertical padding, `#F8F9FA` background.
- Right-aligned text row: "שלב 2 מתוך 4" — Inter Regular 12 pt, `#6B7280`; and "הוספת תמונות" — Inter SemiBold 12 pt, `#00478D` (step subtitle on the same line or immediately below).
- "50% הושלמו" — Inter SemiBold 12 pt, `#00478D`, right-aligned.
- Linear progress track: full-width, 4 pt height, background `#E5E7EB`, filled portion `#00478D` at **50%**, border-radius 2 pt.

### Section heading block
- "הוספת מוצר - שלב 2" — Public Sans Bold 18 pt, `#1F2937`, right-aligned, ~16 pt horizontal padding, ~16 pt top margin.
- Sub-instruction: "צלמו את המוצר כדי שנוכל לנתח את המידע בצורה מדויקת" — Inter Regular 13 pt, `#6B7280`, right-aligned, ~4 pt below heading.

### Photo upload tile — "חזית המוצר" (Product Front)
- Large card: full-width minus 32 pt horizontal margins, ~140 pt tall, background `#FFFFFF`, border 1.5 pt dashed `#D1D5DB` (or solid `#E5E7EB`), border-radius 12 pt.
- Centred content (icon above, label below):
  - `photo_camera` icon — 32 pt, `#00478D`.
  - "חזית המוצר" — Inter SemiBold 14 pt, `#1F2937`, centred.
  - Sub-label: "ודאו שהלוגו והשם ברורים" — Inter Regular 12 pt, `#6B7280`, centred.
- Tappable — opens device camera or photo picker.
- Empty state shown in screenshot (no photo captured yet).

### Photo upload tile — "רשימת רכיבים" (Ingredients List)
- Same card dimensions and styling as חזית המוצר tile.
- Centred content:
  - `receipt_long` icon — 32 pt, `#00478D`.
  - "רשימת רכיבים" — Inter SemiBold 14 pt, `#1F2937`, centred.
  - Sub-label: "צלמו מקרוב ובחדות" — Inter Regular 12 pt, `#6B7280`, centred.
- Tappable — opens device camera or photo picker.
- Empty state shown in screenshot.

### Tip / lightbulb note
- Below the two tiles, ~16 pt horizontal margin, ~12 pt top margin.
- Light-blue container `#EBF4FF`, border-radius 8 pt, padding 12 pt.
- `lightbulb` icon `#00478D` 16 pt on right (RTL leading) + body text Inter Regular 12 pt `#374151`.
- Exact Hebrew text: "כדאי לצלם במקום עם תאורה טובה ולהימנע מהשתקפויות של אור ישיר על האריזה. זה יעזור לנו לנתח את המידע בצורה מדויקת יותר."

### Caption line
- Below tip note, centred: "תמונות ברורות עוזרות לשמור על בטיחותך" — Inter Regular 12 pt, `#6B7280`.

### Reference / example photo
- Below caption: a reference photograph of a grocery product (cracker-style box) with an overlay text demonstrating desired image quality — used as a visual hint to users.
- Not interactive; decorative illustration.

### Navigation area (bottom)
- **"המשך" (Continue) button** — `primary-button` filled, `#00478D` background, white text Inter SemiBold 14 pt, height 48 pt, border-radius 12 pt, full-width within 16 pt margins. Icon: `arrow_back` (RTL: trailing / left side of button). See [_components-glossary.md#primary-button](_components-glossary.md#primary-button).
- Below the primary button: **"דילוג והזנה ידנית"** — styled as a plain text link (not a button), Inter Regular 13 pt, `#00478D`, centred. Tapping skips photo capture and advances directly to step 3 (or allows manual allergen entry).
- No "חזרה" (Back) button visible in the screenshot — unlike step 3's two-button row, this screen shows a single primary CTA + a text-link skip option.
- No standard bottom navigation bar — wizard modal flow.

Resolved per _design-decisions.md#dd-5: the canonical wizard chrome specifies a "חזרה" (outlined) back button on steps **2, 3, and 4** (not step 1). Step 2 therefore **should include a "חזרה" back button**, navigating to step 1. The Stitch design omitting it is a Stitch artifact (§7 delta). See `_components-glossary.md#wizard-chrome`.

## 3. Component inventory

| Element | Design-system token | Font | Icon name | Exact Hebrew copy | Notes |
|---|---|---|---|---|---|
| App bar | see glossary | — | `arrow_back` (✕ close) | "הוספת מוצר חדש" | see _components-glossary.md#app-bar — Wizard bar variant |
| Progress step label | `#6B7280` | Inter Regular 12 pt | — | "שלב 2 מתוך 4" | — |
| Progress step subtitle | `AppColors.primary` `#00478D` | Inter SemiBold 12 pt | — | "הוספת תמונות" | step title next to step counter |
| Progress percent label | `AppColors.primary` `#00478D` | Inter SemiBold 12 pt | — | "50% הושלמו" | — |
| Progress bar track | `#E5E7EB` bg / `#00478D` fill | — | — | — | 4 pt height, border-radius 2 pt, 50% fill |
| Section title | `#1F2937` | Public Sans Bold 18 pt | — | "הוספת מוצר - שלב 2" | — |
| Section sub-instruction | `#6B7280` | Inter Regular 13 pt | — | "צלמו את המוצר כדי שנוכל לנתח את המידע בצורה מדויקת" | — |
| Upload tile — front | `#FFFFFF` bg, `#D1D5DB` dashed border | Inter SemiBold 14 pt | `photo_camera` (`#00478D`, 32 pt) | "חזית המוצר" / "ודאו שהלוגו והשם ברורים" | see §4 for tile spec |
| Upload tile — ingredients | `#FFFFFF` bg, `#D1D5DB` dashed border | Inter SemiBold 14 pt | `receipt_long` (`#00478D`, 32 pt) | "רשימת רכיבים" / "צלמו מקרוב ובחדות" | see §4 for tile spec |
| Tip note | `#EBF4FF` bg | Inter Regular 12 pt `#374151` | `lightbulb` `#00478D` 16 pt | (see §2 for verbatim text) | same container style as step 3 info note |
| Caption | `#6B7280` | Inter Regular 12 pt | — | "תמונות ברורות עוזרות לשמור על בטיחותך" | centred below tip |
| Reference photo | — | — | — | — | decorative illustration, not interactive |
| Continue button | see glossary | Inter SemiBold 14 pt | `arrow_back` (RTL trailing) | "המשך" | see _components-glossary.md#primary-button |
| Skip text link | `#00478D` | Inter Regular 13 pt | — | "דילוג והזנה ידנית" | plain `TextButton`, no border, centred |

## 4. Sub-components / element design  (photo capture/upload tiles, thumbnails)

### Progress bar
- `LinearProgressIndicator(value: 0.50, backgroundColor: Color(0xFFE5E7EB), color: Color(0xFF00478D))`.
- Wrapped in `ClipRRect(borderRadius: BorderRadius.circular(2))` for rounded ends.
- Preceded by right-aligned `Row` with step label + step subtitle + percentage.

### Photo upload tile (empty state)
Both upload tiles share identical structure; only the icon and label text differ.

```
GestureDetector(
  onTap: () => _pickPhoto(slot),  // opens camera/gallery picker
  child: Container(
    width: double.infinity,
    height: 140,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: Color(0xFFD1D5DB),
        width: 1.5,
        style: BorderStyle.solid,  // dashed border via CustomPainter or DashedBorder package
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(slotIcon, size: 32, color: Color(0xFF00478D)),
      SizedBox(height: 8),
      Text(slotTitle, style: TextStyle(
        fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937))),
      SizedBox(height: 4),
      Text(slotSubLabel, style: TextStyle(
        fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: Color(0xFF6B7280))),
    ]),
  ),
)
```

- `slotIcon` / `slotTitle` / `slotSubLabel` per slot:

| Slot | Icon | Title | Sub-label |
|---|---|---|---|
| Front | `photo_camera` | "חזית המוצר" | "ודאו שהלוגו והשם ברורים" |
| Ingredients | `receipt_long` | "רשימת רכיבים" | "צלמו מקרוב ובחדות" |

### Photo upload tile (thumbnail state — after photo captured)
When a photo is captured/selected the tile transitions to display the thumbnail:

- Same `Container` frame (140 pt tall, 12 pt border-radius).
- `Image.file` or `Image.memory` fills the container (`BoxFit.cover`).
- Overlay: a small `photo_camera` or `edit` re-shoot icon badge (24 pt, white icon, `#00478D` circular background, 4 pt from bottom-right corner).
- Border changes to solid `#00478D` 1.5 pt to signal "captured".
- The title/sub-label text is hidden once thumbnail is shown.

### Tip / lightbulb note
- `Container(decoration: BoxDecoration(color: Color(0xFFEBF4FF), borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.all(12))`.
- `Row(crossAxisAlignment: CrossAxisAlignment.start)`: `Icon(Icons.lightbulb, color: Color(0xFF00478D), size: 16)` on right (RTL) + `SizedBox(width: 8)` + `Expanded(child: Text(...))`.
- Same container style as the info note in step 3 — identical visual treatment, different icon (`lightbulb` vs `info`).

### Navigation area
- `Column` at bottom:
  - `ElevatedButton` — "המשך", `#00478D` bg, white text, height 48 pt, border-radius 12 pt, full-width within 16 pt margins. Icon: `Icons.arrow_back` (Material, 18 pt, white, RTL trailing = left of text in RTL layout).
  - `SizedBox(height: 12)`.
  - `TextButton` — "דילוג והזנה ידנית", no border, `#00478D` text, centred, Inter Regular 13 pt.

## 5. States & interactions  (empty / photo added / upload progress / error)

| State | Trigger | Visual change |
|---|---|---|
| Empty (initial) | Screen loads | Both tiles show icon + title + sub-label; dashed grey border; no thumbnail |
| Photo added — front | User taps front tile → selects/captures image | Front tile shows thumbnail; border → solid `#00478D`; re-shoot badge appears |
| Photo added — ingredients | User taps ingredients tile → selects/captures image | Ingredients tile shows thumbnail; border → solid `#00478D`; re-shoot badge appears |
| Both photos added | Both slots filled | Both tiles show thumbnails; "המשך" button remains active (photos optional — skip link still visible) |
| Upload in progress | User taps "המשך" with photos present | "המשך" button shows `CircularProgressIndicator` (white, strokeWidth 2) while images upload to Supabase Storage; button disabled during upload |
| Upload error | Network failure during upload | Tile or toast shows error state; retry affordance (TBD — not shown in Stitch design) |
| Skip chosen | User taps "דילוג והזנה ידנית" | Photos skipped; wizard advances to step 3 with `photoFront = null` and `photoIngredients = null` in wizard state |
| Continue tapped (no photos) | "המשך" tapped with both tiles empty | Wizard advances to step 3 — photos are optional; no validation error |
| Continue tapped (1+ photos) | "המשך" tapped with ≥1 photo | Uploads present photos, then advances to step 3 |
| Close tapped | User taps `✕` / `arrow_back` in app bar | Confirmation dialog ("לצאת מהוספת מוצר?") then dismisses wizard |
| Camera permission denied | OS denies camera/gallery access | OS permission dialog; on permanent denial show app-level error toast (TBD) |

## 6. Data & controller contract  (wizard state carried across steps)

**Wizard state fields owned by step 2:**
- `File? photoFront` — selected/captured image file for product front. `null` if skipped.
- `File? photoIngredients` — selected/captured image file for ingredients list. `null` if skipped.

**Wizard state carried forward from step 1:**
- `String productName` — product name/barcode entered in step 1.

**Carried forward to steps 3 & 4:**
- `photoFront` and `photoIngredients` are held in wizard state. Actual upload to Supabase Storage is deferred to final submission (step 4 "Submit") — or triggered on "המשך" from step 2 (implementation choice; see §7.3).

**Photo capture mechanism:**
- Web: `ImagePicker` from `image_picker` package, `ImageSource.gallery` only (no camera on web without plugin).
- Android/iOS: `ImagePicker`, both `camera` and `gallery` sources. Show a `showModalBottomSheet` picker to let the user choose.

**Upload target (on final submit):**
- Supabase Storage bucket: `product-images` (assumed — not confirmed in schema).
- Path pattern: `products/{productId}/front.jpg` and `products/{productId}/ingredients.jpg`.
- After upload, store the public URL in the `products` row (`image_url` and `ingredients_image_url` columns — TBD; current schema not confirmed).

**Callbacks / methods (on `AddProductController` or equivalent):**
- `onPhotoSelected(PhotoSlot slot, File file)` — saves photo to wizard state for the given slot (`front` | `ingredients`).
- `onNext()` — advances to step 3; optionally triggers background upload.
- `onSkip()` — advances to step 3 with both photo fields null.
- `onClose()` — exits wizard with confirmation dialog.

## 7. Open questions / design-vs-app deltas

1. **Back button on step 2** — Resolved per _design-decisions.md#dd-5. Canonical wizard chrome: "חזרה" (outlined) back button is present on steps 2, 3, and 4. Step 2 **must include** a "חזרה" button navigating back to step 1. The Stitch design omitting it is a Stitch artifact; implement the canonical two-button row (חזרה + המשך) per `_components-glossary.md#wizard-chrome`.

2. **"דילוג והזנה ידנית" destination** — does "Skip — Manual Entry" jump directly to step 3 (allergen selection with no photos), or to a completely different manual-entry form? The wording "הזנה ידנית" implies a separate text-input flow rather than just skipping photos. Clarify with PM.

3. **Photo upload timing** — should images be uploaded to Supabase Storage when the user taps "המשך" from step 2 (eager), or only on final wizard submit at step 4 (deferred)? Deferred is simpler and avoids orphaned uploads if the user cancels mid-wizard. The Stitch design does not specify; recommend deferred.

4. **Dashed vs. solid border on tiles** — the screenshot shows what appears to be a dashed border on the empty upload tiles, consistent with "drop zone" UX patterns. Flutter's `BoxDecoration.border` does not natively support dashed borders; a `CustomPainter` or third-party package (e.g., `dashed_border_2`) would be needed. Confirm whether dashed or solid is required.

5. **Thumbnail re-shoot affordance** — the Stitch design does not show a thumbnail state in the screenshot (both tiles are empty). The re-shoot badge and thumbnail treatment in §4 are inferred from standard photo-upload UX. Confirm exact thumbnail design with designer / Stitch screen variant.

6. **Web platform — camera access** — `mobile_scanner` (used for barcode scanning) is declared platform-aware/web-safe in the app. The `image_picker` plugin must similarly be confirmed as web-compatible for gallery access. Camera capture on web typically requires additional configuration.

7. **Supabase Storage schema** — no `product-images` bucket or `image_url` / `ingredients_image_url` columns are confirmed in the current `supabase/schema.sql`. Schema additions needed before this feature is shippable.

8. **Wizard step count label** — step 3's screen spec describes the step subtitle as "75% הושלמו" for a 4-step wizard, consistent with step 2 being "50% הושלמו". Verify the sub-title label next to "שלב 2 מתוך 4" is "הוספת תמונות" (matches HTML extraction) or something else.

---

## Resolved cross-screen note

**Element:** Wizard bottom-navigation button pattern.

Resolved per _design-decisions.md#dd-5 (canonical wizard chrome). The canonical pattern for steps 2, 3, and 4 is a two-button row: `OutlinedButton` ("חזרה") + `primary-button` ("המשך"). Step 2's Stitch design showing only "המשך" + "דילוג והזנה ידנית" with no "חזרה" is a Stitch rendering artifact. Implement the canonical two-button footer for step 2; the "דילוג והזנה ידנית" skip link may be retained as a tertiary option below the button row if PM confirms it is needed. See `_components-glossary.md#wizard-chrome`.
