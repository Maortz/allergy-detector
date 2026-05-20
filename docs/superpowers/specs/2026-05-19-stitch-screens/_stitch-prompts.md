# Stitch Generation Prompts

Per-screen prompts to feed to the Stitch LLM (via
`mcp__stitch__generate_screen_from_text` with `projectId:
"16588854804615693446"`) when generating missing screens listed in
`_missing-screens.md`.

When Stitch returns a screen, record its ID in `_missing-screens.md` Stitch
URL column.

---

## Shared context (paste once before each prompt OR include in every call)

```
Project: SafeBite / "בטוח לאכול" — Hebrew/RTL Flutter app for allergen safety.
Design system: "Clinical Clarity RTL" (Stitch project 16588854804615693446).
Palette: Medical Blue primary #00478D, surface bg #F8F9FA, success #0D9488,
safe #16A34A, caution #CA8A04, avoid #DC2626, on-surface #1F2937,
on-surface-variant #6B7280, outline #727783, surface-container-low #F3F4F6,
surface-container-high #E5E7EB, secondary-container teal #78F8DD.
Fonts: Public Sans (headings, Bold/SemiBold), Inter (body, Regular/Medium/SemiBold).
Spacing: 4px grid. Layout: RTL throughout (Hebrew, right-to-left).
Material 3 (NavigationBar, FilledButton allowed).
Bottom nav (when shown): בית / סריקה / קהילה / מועדפים (RTL right→left,
index 0–3), pill active indicator radius 12pt fill primary-container/40.
Apply to every screen below.
```

---

## Tier 1 prompts

### P1 — product-details-caution

```
Screen "פרטי מוצר" Caution state. Detail-bar app-bar: right-aligned title
"פרטי מוצר" Public Sans SemiBold 16pt #1F2937, arrow_back_ios trailing left
#374151.
Below app-bar: compact amber status pill (BG #FEF9C3, radius 20pt, padding
12/4pt, info icon 16pt #CA8A04, label "זהירות" Inter SemiBold 12pt #A16207)
left-aligned, with adjacent text "עלול להכיל אלרגנים: אגוזים" Inter Regular
13pt #A16207 to its left.
Product hero image full-width, 180pt tall, BoxFit.contain on white, with a
share icon 24pt #374151 overlay at bottom-trailing corner.
Product name "שוקולד חלב פרה" Public Sans Bold 22pt #1F2937 right-aligned;
subtitle "100 גרם" Inter Regular 14pt #6B7280.
Section "אלרגנים שזוהו" Public Sans SemiBold 16pt header right-aligned. Below:
horizontal Wrap of allergen chips — amber Variant D (BG #FEF9C3, border 1pt
#CA8A04, icon 16pt #CA8A04, label Inter SemiBold 13pt #A16207, radius 20pt)
for trace allergens "אגוזים" (icon nutrition), "חלב" (water_drop); plus blue
Variant A (BG #EBF4FF, border #BFDBFE, icon/label #00478D) for monitored
allergens that were NOT detected like "ביצים" (egg), "גלוטן" (grass).
Ingredients accordion "רשימת רכיבים" with list_alt icon and expand_more,
expanded body shows paragraph with the word "אגוזים" rendered in #CA8A04
Inter Bold (keyword highlight).
Report-error row "דווח על טעות" with report icon, Inter Regular 13pt #DC2626,
left-aligned.
Bottom nav 4 tabs, "סריקה" active with pill indicator.
```

---

### P2 — onboarding-step-2-notifications

```
Screen "כמעט סיימנו!" — onboarding step 2 of 2. Standalone shell, no
main-app chrome, no bottom nav.
Top: brand header row 56pt — "SafeBite" Inter Medium 16pt #00478D
right-aligned, cancel ✕ icon 24pt #374151 left.
Headline "כמעט סיימנו!" Public Sans SemiBold 22pt #1F2937 right-aligned.
Body "הזן את שמך כדי שנוכל להתאים לך את החוויה. נוכל גם לשלוח לך התראות
חכמות כשנמצא מוצר רלוונטי." Inter Regular 14pt #6B7280 right-aligned,
multi-line.
Progress row: "שלב 2 מתוך 2" Inter Regular 12pt #6B7280 right + "100%
הושלם" Inter SemiBold 12pt #00478D left of it.
LinearProgressIndicator 6pt height, 100% fill #00478D, track #E5E7EB,
radius 4pt.
Name field: label "מה השם שלך?" Inter SemiBold 14pt #191C1D right-aligned;
outlined TextField 48pt height, radius 8pt, border 1pt #727783, BG white,
RTL text, placeholder "הקלד את שמך".
Notification card: white BG, radius 12pt, padding 16pt, subtle shadow.
Centered column: notifications_active icon 32pt #00478D, then "התראות
חכמות" Inter SemiBold 14pt #1F2937 centered, body "קבל התראות כשמצאנו מוצר
חדש שעלול לסכן אותך." Inter Regular 13pt #6B7280 centered max 2 lines, then
outlined button "אפשר התראות" 40pt height with notifications_none icon 18pt
leading, border 1.5pt #00478D, label Inter SemiBold 13pt #00478D, radius 8pt.
Bottom: full-width "סיים" primary button — BG #00478D, label Inter SemiBold
14pt #FFFFFF, height 48pt, radius 12pt, 16pt horizontal margins.
```

---

### P3 — allergen-management

```
Screen "נהל אלרגיות" — Settings sub-route. No bottom nav.
Detail-bar app-bar: right-aligned title "נהל אלרגיות" Public Sans SemiBold
16pt #1F2937, arrow_back_ios trailing left.
Right-aligned counter "אלרגנים פעילים: 5" Inter Regular 13pt #6B7280, 16pt
margins, 12pt above the grid.
Allergen selection GridView: 3 columns, 12pt gap between cards, 16pt outer
margins, square 1:1 aspect ratio per card, radius 16pt.
Unselected card: white #FFFFFF BG, 1pt #E5E7EB border, centered column —
allergen icon 24pt #6B7280 on top, then label Inter SemiBold 13pt #374151
below.
Selected card: white BG, 2pt #00478D border, check_circle badge 18pt #00478D
positioned at top-start corner (RTL: top-right), icon and label colours
unchanged.
Render 12 allergens (RTL grid right→left, top→bottom): בוטנים (park), חלב
(water_drop), ביצים (egg), סויה (nutrition), חיטה (grass), אגוז מלך
(energy_savings_leaf), שקד (nature), קשיו (emoji_nature), פיסטוק (grain),
פקאן (local_florist), אגוז לוז (spa), שומשום (bubble_chart). Show some as
selected (e.g. בוטנים, חלב, ביצים, אגוז לוז, שומשום) to illustrate the
selected state.
Bottom: centered footer "השינויים נשמרים אוטומטית" Inter Regular 11pt
#6B7280, 12pt margin above safe area. No primary CTA.
```

---

### P4 — profile-edit (modal sheet)

```
Modal bottom sheet "ערוך פרופיל" — rounded top corners 16pt, white BG,
~440pt height. Dimmed scrim behind.
Top: grabber pill 4pt x 32pt #E5E7EB centered, 8pt from top.
Header row: title "ערוך פרופיל" Public Sans SemiBold 16pt #1F2937
right-aligned; cancel ✕ icon 24pt #374151 IconButton left, 16pt padding both
sides.
Avatar block centered: 80pt circle, BG #EBF4FF, border 2pt #BFDBFE. Inside:
initial letter "ד" Inter SemiBold 28pt #00478D centered (placeholder for
photo).
Below avatar, centered: "החלף תמונה" TextButton Inter Medium 13pt #00478D
with edit icon 14pt leading.
Form fields, 12pt spacing:
1. Label "שם מלא" Inter SemiBold 14pt #191C1D right-aligned. Outlined
   TextField 48pt radius 8pt border #727783 focused #00478D, BG white, RTL
   text, value "דניאל ישראלי".
2. Label "דוא״ל" Inter SemiBold 14pt #191C1D right-aligned. Outlined
   TextField 48pt, keyboardType email, RTL text, value
   "daniel@example.com".
Bottom: full-width primary button "שמור" — BG #00478D, label Inter SemiBold
14pt #FFFFFF, height 48pt, radius 12pt, 16pt horizontal margins, 16pt top
margin, 8pt bottom safe-area padding.
```

---

### P5 — admin-brand-form (modal sheet)

```
Modal bottom sheet "עריכת מותג" (or "הוספת מותג חדש" for add mode) —
rounded top 16pt, white BG, ~520pt height, dimmed scrim.
Top: grabber pill 4pt x 32pt #E5E7EB. Header row: title Public Sans
SemiBold 16pt #1F2937 right-aligned; cancel ✕ icon left.
Form (each field: label Inter SemiBold 14pt #191C1D right-aligned, then
outlined TextField 48pt, radius 8pt, border #727783 focused #00478D, BG
white, RTL text):
1. "שם המותג" — placeholder "הקלד שם מותג", required
2. "קישור ללוגו" — placeholder "https://...", optional, keyboardType url
3. Logo preview: 56pt circle, BG #EBF4FF, centered initial letter "ת" Inter
   SemiBold 22pt #00478D (or image from URL when provided)
4. "סטטוס אימות" Inter Medium 12pt #727783 right-aligned label. Below: 28pt
   x 48pt pill Switch — ON track #00478D, OFF track #E1E3E4, thumb 20pt
   white. Helper text below: "מותג זה מוצג כמותג מאומת בכל המוצרים" Inter
   Regular 12pt #9CA3AF
5. "הערות (אופציונלי)" multi-line TextField minLines 3 maxLines 6

Actions area (bottom):
- Full-width "שמור שינויים" primary button BG #00478D 48pt radius 12pt
- "ביטול" TextButton Inter Medium 14pt #374151 centered below
- 1pt #F3F4F6 divider
- Destructive "מחק מותג" TextButton Inter SemiBold 14pt #DC2626 with delete
  icon 18pt leading — edit-mode ONLY (omit for add mode)
```

---

### P6 — Dialog D-1 (wizard exit)

```
AlertDialog modal — white BG, radius 12pt, max-width 320pt, centered on
50% black scrim.
Title "לצאת מהוספת מוצר?" Public Sans SemiBold 16pt #1F2937 right-aligned,
padding 24pt top.
Body "הנתונים שהזנת לא יישמרו." Inter Regular 14pt #374151 right-aligned,
24pt horizontal padding.
Actions row right-aligned (RTL: rightmost first):
- TextButton "המשך עריכה" Inter Medium 14pt #374151
- TextButton "צא" Inter SemiBold 14pt #DC2626
8pt padding around actions.
```

---

### P7 — Dialog D-2 (logout)

```
AlertDialog modal — white BG, radius 12pt, max-width 320pt, dimmed scrim.
Title "התנתק מהחשבון?" Public Sans SemiBold 16pt #1F2937 right-aligned.
Body "כל הגדרות הפרופיל ישמרו במכשיר. תוכל להתחבר שוב בכל עת." Inter Regular
14pt #374151 right-aligned, multi-line.
Actions: TextButton "ביטול" #374151, TextButton "התנתק" #DC2626. Right-aligned.
```

---

### P8 — Dialog D-3 (brand delete)

```
AlertDialog modal — white BG, radius 12pt, max-width 320pt, dimmed scrim.
Title "האם למחוק את המותג?" Public Sans SemiBold 16pt #1F2937 right-aligned.
Body "פעולה זו אינה ניתנת לביטול. מוצרים המקושרים למותג יישארו במאגר אך
יסומנו ללא מותג." Inter Regular 14pt #374151 right-aligned.
Actions: TextButton "ביטול" #374151, TextButton "מחק" #DC2626. Right-aligned.
```

---

### P9 — Photo source picker (modal sheet)

```
Modal bottom sheet "הוסף תמונה" — rounded top 16pt, white BG, ~220pt
height, dimmed scrim.
Top: grabber pill 4pt x 32pt #E5E7EB centered.
Header: "הוסף תמונה" Inter SemiBold 16pt #1F2937 right-aligned, 16pt padding.
Three ListTile rows full-width, 56pt tall each, 16pt horizontal padding,
1pt #F3F4F6 divider between rows. RTL layout (icon leading on right):
1. photo_camera icon 24pt #00478D right + label "צילום מהמצלמה" Inter Medium
   15pt #1F2937 + chevron_left 20pt #9CA3AF trailing left
2. photo_library icon 24pt #00478D + label "בחירה מהגלריה" + chevron_left
3. close icon 24pt #DC2626 + label "ביטול" Inter SemiBold 15pt #DC2626
   (destructive style; or render as a plain row)
Bottom safe-area padding.
```

---

### P10 — FavoritesScreen (bottom-nav tab 4)

```
Screen "מועדפים" — bottom-nav tab 4. Main-app chrome.
Brand-bar app-bar 56pt: right-aligned "בטוח לאכול" Inter Medium 16pt
#00478D logo text, left-trailing menu hamburger icon 24pt #374151 + 36pt
circular avatar.
Page header block: "המוצרים השמורים שלי" Public Sans Bold 22pt #1F2937
right-aligned; subtitle "כל המוצרים שסימנת כדאי לזכור" Inter Regular 14pt
#6B7280 right-aligned, 4pt below.
Stat chip row (optional): "12 מוצרים שמורים" Inter Medium 13pt #00478D on
#EBF4FF pill, radius 20pt, padding 12/4pt.
Product list: scrollable ListView of compact product-row cards — each:
white #FFFFFF BG, radius 12pt, padding 12pt, subtle shadow, 8pt gap between
rows.
RTL row layout: status pill (right/leading) — green safe #DCFCE7 / amber
#FEF9C3 / red #FEE2E2 per status. Then text column flex: product name
Inter SemiBold 14pt #1F2937 line 1, brand·weight Inter Regular 12pt #6B7280
line 2, timestamp "נשמר לפני N ימים" Inter Regular 12pt #9CA3AF line 3.
Then thumbnail (left/trailing) 40x40pt radius 8pt, BoxFit.cover.
Show 3 sample rows: "יוגורט יווני טבעי" (safe), "במבה קלאסית" (avoid —
contains peanuts), "דגני בוקר קוואקר" (caution).
Empty state (alternative variant): bookmark_border icon 64pt #9CA3AF
centered, heading "אין מוצרים שמורים" Public Sans SemiBold 18pt #1F2937,
body "סמן מוצרים שאתה רוצה לזכור כדי שיופיעו כאן." Inter Regular 14pt
#6B7280, primary button "התחל לסרוק" #00478D 48pt radius 12pt.
Bottom nav 4 tabs, "מועדפים" active with pill indicator (favorite filled
icon #00478D, label Inter SemiBold 11pt #00478D, BG #D6E3FF at 40%).
Generate two variants: populated list + empty state.
```

---

## How to use

```dart
// Per prompt (P1 example):
mcp__stitch__generate_screen_from_text(
  projectId: "16588854804615693446",
  prompt: "<paste shared context + prompt P1 here>",
)
```

Record the returned screen ID in `_missing-screens.md` under the matching row.

Tier 2 (states) and Tier 3 (drawer destinations) prompts will be added here
as those items move into the active backlog. Currently they are tracked in
`_missing-screens.md` with ☐ status only.
