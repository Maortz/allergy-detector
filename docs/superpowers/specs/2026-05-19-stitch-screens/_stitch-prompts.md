# Stitch Generation Prompts

Per-screen prompts to feed to the Stitch LLM (via
`mcp__stitch__generate_screen_from_text` with `projectId:
"16588854804615693446"`) when generating missing screens listed in
`_missing-screens.md`.

When Stitch returns a screen, record its ID in `_missing-screens.md` Stitch
URL column.

**Tier 1 prompts (P1–P10) have been generated and removed from this file.**
See `_missing-screens.md` for the resulting screen IDs.

---

## Shared context (paste once before each prompt OR include in every call)

```
Project: SafeBite / "בטוח לאכול" — Hebrew/RTL Flutter app for allergen safety.
Design system: "Clinical Clarity RTL" (Stitch project 16588854804615693446).
Palette: Medical Blue primary #00478D, surface bg #F8F9FA, success #0D9488,
safe #16A34A, caution #CA8A04, avoid #DC2626, on-surface #1F2937,
on-surface-variant #6B7280, outline #727783, surface-container-low #F3F4F6,
surface-container-high #E5E7EB, secondary-container teal #78F8DD,
destructive-subtle bg #FECDD3 / fg #9F1239.
Fonts: Public Sans (headings, Bold/SemiBold), Inter (body, Regular/Medium/SemiBold).
Spacing: 4px grid. Layout: RTL throughout (Hebrew, right-to-left).
Material 3 (NavigationBar, FilledButton allowed).
Bottom nav (when shown): בית / סריקה / קהילה / מועדפים (RTL right→left,
index 0–3), pill active indicator radius 12pt fill primary-container/40.
Apply to every screen below.
```

---

## Tier 2 prompts — state variants (P11–P29)

State-variant prompts. Each is a delta against an already-generated parent
screen — keep parent chrome (app-bar, bottom-nav, header block) IDENTICAL
to the parent screen and replace ONLY the content region described.

### P11 — active-search-results empty

```
Screen "חיפוש פעיל - אין תוצאות" (active-search-results empty state).
Parent: "חיפוש פעיל - תוצאות" (existing screen).
Keep parent chrome: brand-bar app-bar 56pt with right-aligned "בטוח לאכול"
Inter Medium 16pt #00478D + hamburger menu + 36pt avatar (left/trailing);
RTL search field 48pt height with right-leading search icon and current
query text "מוצר שלא קיים"; bottom nav 4 tabs with "סריקה" active.
Content region (replaces result list): centered column, 64pt top padding —
search_off icon 64pt #9CA3AF, then heading "לא נמצאו תוצאות" Public Sans
SemiBold 18pt #1F2937 centered, then body "נסה לחפש במונחים אחרים, או הוסף
את המוצר למאגר" Inter Regular 14pt #6B7280 centered max-width 280pt, then
outlined button "הוסף מוצר חדש" 40pt height with add icon 18pt leading,
border 1.5pt #00478D, label Inter SemiBold 13pt #00478D, radius 8pt.
```

### P12 — active-search-results error (network)

```
Screen "חיפוש פעיל - שגיאת רשת" (active-search-results network error).
Parent: "חיפוש פעיל - תוצאות". Keep parent chrome identical.
Content region: centered column — cloud_off icon 64pt #DC2626 (in 88pt
circle BG #FEE2E2), then heading "אין חיבור לאינטרנט" Public Sans SemiBold
18pt #1F2937 centered, then body "בדוק את חיבור הרשת שלך ונסה שוב." Inter
Regular 14pt #6B7280 centered, then filled button "נסה שוב" — BG #00478D,
label Inter SemiBold 14pt #FFFFFF, height 44pt radius 10pt, with refresh
icon 18pt leading, 24pt horizontal padding.
```

### P13 — active-search-results loading (shimmer)

```
Screen "חיפוש פעיל - טוען" (active-search-results loading state).
Parent: "חיפוש פעיל - תוצאות". Keep parent chrome identical.
Content region: 6 shimmer product-row placeholders, each 76pt tall, white
BG, radius 12pt, padding 12pt, 8pt vertical gap. RTL row layout:
- Right (leading): 32x60pt status-pill placeholder (rounded rect 16pt
  radius, BG #E5E7EB)
- Middle: 2 stacked grey lines — top line 60% width 14pt tall, bottom line
  40% width 12pt tall, both #E5E7EB radius 4pt, 8pt vertical gap
- Left (trailing): 40x40pt square placeholder radius 8pt BG #E5E7EB
All placeholders carry a subtle shimmer-gradient overlay implied by a
diagonal lighter band #F3F4F6 → #FFFFFF → #F3F4F6.
```

### P14 — community-review empty queue

```
Screen "סקירת קהילה - תור ריק" (community-review empty queue state).
Parent: "Community Review" (existing screen).
Keep parent chrome: detail-bar app-bar with right-aligned title "סקירת
קהילה" Public Sans SemiBold 16pt #1F2937, arrow_back_ios trailing left;
right-aligned counter "0 מוצרים בתור" Inter Regular 13pt #6B7280; bottom
nav with "קהילה" active.
Content region (replaces review card): centered column — task_alt icon
72pt #16A34A inside 96pt circle BG #DCFCE7, then heading "אין מוצרים
לסקירה כרגע" Public Sans SemiBold 18pt #1F2937 centered, then body
"כל המוצרים החדשים נסקרו על ידי הקהילה. חזור מאוחר יותר." Inter Regular
14pt #6B7280 centered max-width 300pt, then outlined button "חזור לקהילה"
40pt height border 1.5pt #00478D label #00478D Inter SemiBold 13pt radius 8pt.
```

### P15 — search-scan camera permission denied

```
Screen "חיפוש וסריקה - גישה למצלמה נדחתה" (search-scan camera permission
denied). Parent: "חיפוש וסריקה" (existing screen).
Keep parent chrome: brand-bar app-bar; the upper search/scan area; bottom
nav with "סריקה" active.
Replace the scanner viewfinder area (the dark camera preview region) with
a 320pt tall placeholder card — BG #F3F4F6, radius 16pt, dashed border
1.5pt #9CA3AF, centered column — videocam_off icon 56pt #DC2626, then
"גישה למצלמה נדחתה" Inter SemiBold 16pt #1F2937 centered, then "כדי לסרוק
ברקודים, אפשר גישה למצלמה בהגדרות המכשיר." Inter Regular 13pt #6B7280
centered max-width 260pt, then filled button "פתח הגדרות" BG #00478D label
#FFFFFF Inter SemiBold 13pt height 40pt radius 8pt with settings icon 16pt
leading.
```

### P16 — search-scan recently-scanned empty (hide row)

```
Screen "חיפוש וסריקה - ללא סריקות אחרונות" (search-scan no recent scans).
Parent: "חיפוש וסריקה". Keep parent chrome and scanner area identical.
The "נסרק לאחרונה" (recently scanned) horizontal row that exists below
the scanner in the parent screen should be FULLY OMITTED in this variant
(do not render an empty placeholder — the section header and chip strip
both disappear). The "טיפים" (tips) info card below should slide up to
take its place with the standard 16pt margin from the scanner area.
```

### P17 — add-product step-1 camera unavailable

```
Screen "הוספת מוצר - שלב 1 - מצלמה לא זמינה" (add-product step-1 camera
unavailable). Parent: "הוספת מוצר - שלב 1 (Barcode)" (existing screen).
Keep parent chrome: wizard-shell app-bar with right-aligned title "הוספת
מוצר" + step counter "שלב 1 מתוך 4" + ✕ icon left; progress bar 25%
filled #00478D; section header "סרוק ברקוד" right-aligned.
Replace the scanner viewfinder region (the dark preview area) with a
placeholder card — BG #F3F4F6 radius 16pt, dashed border 1.5pt #9CA3AF,
height 280pt, centered column — no_photography icon 56pt #6B7280, then
"המצלמה אינה זמינה" Inter SemiBold 16pt #1F2937 centered, then
"במכשיר זה אין מצלמה זמינה. הזן את הברקוד ידנית למטה." Inter Regular 13pt
#6B7280 centered max-width 260pt.
Manual barcode TextField below remains unchanged. Bottom CTA "המשך"
remains; disabled until barcode entered.
```

### P18 — add-product step-1 inline validation errors

```
Screen "הוספת מוצר - שלב 1 - שגיאות אימות" (add-product step-1 inline
validation errors). Parent: "הוספת מוצר - שלב 1 (Barcode)".
Keep parent chrome and scanner area identical.
Manual barcode TextField below shows error state: border 1.5pt #DC2626,
helper text below the field — error_outline icon 14pt #DC2626 leading +
"ברקוד חייב להכיל 8 או 13 ספרות" Inter Regular 12pt #DC2626 right-aligned.
The field's current value "123" remains visible in red-tinted text #991B1B.
Bottom CTA "המשך" remains visible but disabled — BG #E5E7EB, label #9CA3AF.
```

### P19 — add-product step-2 photo tile thumbnail-filled

```
Screen "הוספת מוצר - שלב 2 - תמונות מולאו" (add-product step-2 photos
thumbnail-filled state). Parent: "הוספת מוצר - שלב 2 (Photos)" (existing
screen). Keep parent chrome and section header.
Each of the 3 photo tiles (front / ingredients / nutrition) now shows a
filled thumbnail instead of a placeholder. Each tile: full-bleed product
photograph filling the 1:1 aspect tile, radius 12pt. Top-trailing (RTL:
top-left) corner overlay: 28pt circular IconButton BG #FFFFFF with 60%
opacity, close icon 16pt #DC2626 inside — for removing the photo.
Below each tile, the placeholder text "העלה תמונה" is replaced with
inline label — check_circle icon 14pt #16A34A leading + "הועלה" Inter
SemiBold 12pt #16A34A right-aligned. The "המשך" CTA is now enabled (BG
#00478D, label #FFFFFF).
```

### P20 — add-product step-2 upload error / retry

```
Screen "הוספת מוצר - שלב 2 - שגיאת העלאה" (add-product step-2 upload
error). Parent: "הוספת מוצר - שלב 2 (Photos)". Keep parent chrome.
One of the 3 photo tiles (e.g. "תמונת מרכיבים") is shown in error state:
tile BG #FEE2E2, dashed border 1.5pt #DC2626, centered column — sync_problem
icon 32pt #DC2626, then "ההעלאה נכשלה" Inter SemiBold 13pt #991B1B centered,
then "נסה שוב" TextButton Inter SemiBold 12pt #DC2626 with refresh icon
14pt leading (no underline).
The other 2 tiles remain in their normal (placeholder or filled) state.
SnackBar at bottom: BG #DC2626, white text "ההעלאה נכשלה. בדוק את החיבור
ונסה שוב." Inter Medium 13pt right-aligned, refresh icon 18pt #FFFFFF
trailing-left, height 48pt, 8pt margin from bottom-nav, radius 8pt.
```

### P21 — add-product step-4 submit loading + error

```
Two-variant screen "הוספת מוצר - שלב 4 - שליחה" (add-product step-4 submit
states). Parent: "הוספת מוצר - שלב 4 (May Contain)". Keep parent chrome
and form content.

Variant A (loading): Bottom CTA "שלח להוספה" replaced with a centered
CircularProgressIndicator 24pt stroke 2.5pt color #FFFFFF on the same
filled-button BG #00478D 48pt height radius 12pt; button disabled to
interaction. Above the button: helper text "שולח את הנתונים..." Inter
Regular 12pt #6B7280 centered.

Variant B (error): Below the CTA: error banner full-width — BG #FEE2E2,
radius 8pt, padding 12pt, 1pt border #DC2626. RTL row: error icon 18pt
#DC2626 right-leading, then text column "שליחה נכשלה" Inter SemiBold 13pt
#991B1B line 1, "אנא נסה שוב בעוד מספר רגעים." Inter Regular 12pt #B91C1C
line 2. CTA returns to active state.
```

### P22 — admin-trusted-brands empty list

```
Screen "ניהול מותגים - רשימה ריקה" (admin-trusted-brands empty state).
Parent: "Manage Trusted Brands (Admin)" (existing screen).
Keep parent chrome: detail-bar app-bar with right-aligned title "מותגים
מאומתים" + arrow_back_ios trailing left; search field; floating "+"
add-button at bottom-trailing (left in RTL).
Content region (replaces brand list): centered column — verified icon
64pt #9CA3AF inside 96pt circle BG #F3F4F6, then heading "עדיין אין
מותגים מאומתים" Public Sans SemiBold 18pt #1F2937 centered, then body
"הוסף מותג ראשון כדי להתחיל לבנות את מאגר המותגים המאומתים." Inter Regular
14pt #6B7280 centered max-width 300pt, then filled button "הוסף מותג ראשון"
BG #00478D label #FFFFFF Inter SemiBold 13pt height 44pt radius 10pt with
add icon 18pt leading, 24pt horizontal padding.
```

### P23 — product-details image load fallback

```
Screen "פרטי מוצר - תמונה לא זמינה" (product-details image fallback state).
Parent: any of the 3 existing product-details screens (Safe / Caution /
Avoid). Keep parent chrome and content identical (status pill, name,
allergen chips, ingredients accordion).
Replace ONLY the hero product image (the full-width 180pt area near the
top): rendered as a placeholder card — BG #F3F4F6, no border, full-width
180pt tall, centered column — image_not_supported icon 48pt #9CA3AF, then
"תמונת המוצר אינה זמינה" Inter Regular 13pt #6B7280 centered.
Share icon overlay at bottom-trailing remains unchanged.
```

### P24 — review-next-item loading next item

```
Screen "המשך סקירה - טוען" (review-next-item loading next card).
Parent: "המשך סקירה (Review Next Item)" (existing screen).
Keep parent chrome: app-bar; "0 מוצרים נותרו בתור" counter; bottom nav.
Replace the central review card with a shimmer placeholder card — same
~520pt height, white BG, radius 16pt, padding 20pt. Inside placeholders:
- Top: 64x64pt square (brand logo) radius 12pt BG #E5E7EB centered
- 16pt gap; line 70% width 18pt tall BG #E5E7EB radius 4pt centered
- 8pt gap; line 50% width 14pt tall BG #E5E7EB radius 4pt centered
- 24pt gap; Wrap of 3 pill placeholders 60x24pt each BG #E5E7EB radius 12pt
- 32pt gap; two button placeholders side-by-side, each 48pt height
  radius 12pt BG #E5E7EB
All placeholders carry a subtle diagonal shimmer band.
Bottom approve/reject action bar remains, but buttons rendered as
disabled (BG #E5E7EB, no label).
```

### P25 — home-dashboard empty activity feed

```
Screen "דף הבית - ללא פעילות" (home-dashboard empty activity feed).
Parent: "דף הבית (Home Dashboard)" (existing screen).
Keep parent chrome: brand-bar app-bar; greeting hero ("שלום, דניאל!");
quick-action grid (4 tiles: סרוק, חפש, הוסף, מועדפים); bottom nav with
"בית" active.
Replace the "פעילות אחרונה" (recent activity) list region with an empty
card — white BG, radius 16pt, padding 24pt, centered column —
restore icon 48pt #9CA3AF, then "אין פעילות אחרונה" Inter SemiBold 15pt
#1F2937 centered, then "סרוק את המוצר הראשון שלך כדי להתחיל." Inter
Regular 13pt #6B7280 centered, then TextButton "התחל לסרוק" Inter SemiBold
13pt #00478D with qr_code_scanner icon 16pt leading.
```

### P26 — home-dashboard loading (shimmer)

```
Screen "דף הבית - טוען" (home-dashboard loading state).
Parent: "דף הבית (Home Dashboard)". Keep parent chrome (app-bar + bottom
nav). Replace ALL content blocks with shimmer placeholders:
- Greeting hero: white BG card radius 16pt height 120pt, inside — 2 stacked
  grey lines (60% / 40% width, 18pt / 14pt tall) #E5E7EB radius 4pt
- Quick-action grid: 4 placeholder tiles 1:1 aspect ratio, BG #F3F4F6
  radius 12pt, 12pt gap
- "פעילות אחרונה" section: section-header line placeholder 30% width 16pt
  tall #E5E7EB; below — 3 stacked activity-row placeholders (white BG
  radius 12pt height 72pt, internal 40x40pt + 2-line text placeholders,
  same pattern as Tier-2 P13)
All placeholders carry a subtle diagonal shimmer band.
```

### P27 — community-hub loading / error stats

```
Two-variant screen "קהילה - מצבי סטטיסטיקה" (community-hub stats states).
Parent: "Community Hub" (existing screen). Keep parent chrome (brand-bar
app-bar; bottom nav with "קהילה" active; page header "קהילת בטוח לאכול").

Variant A (loading): Replace the 3 stat cards (משתמשים פעילים, מוצרים
נסקרו, ביקורות חיוביות) with shimmer placeholders — white BG radius 12pt
padding 16pt, each card contains: 24pt circular placeholder BG #E5E7EB
centered; 8pt gap; line 50% width 14pt tall #E5E7EB radius 4pt; 4pt gap;
line 70% width 11pt tall #E5E7EB radius 4pt. Diagonal shimmer band.

Variant B (error): Replace the stat row with a single full-width error
card — BG #FEF9C3 radius 12pt padding 16pt 1pt border #CA8A04. RTL row:
warning_amber icon 24pt #CA8A04 right-leading; text column "לא ניתן
לטעון סטטיסטיקות" Inter SemiBold 13pt #A16207 line 1, "נסה לרענן." Inter
Regular 12pt #A16207 line 2; TextButton "רענן" Inter SemiBold 12pt
#A16207 left-trailing with refresh icon 14pt leading.
```

### P28 — settings logged-out / no-profile

```
Screen "הגדרות - ללא פרופיל" (settings logged-out / no-profile skeleton).
Parent: "Settings & Profile" (existing screen).
Keep parent chrome: detail-bar app-bar with right-aligned title "הגדרות"
+ arrow_back_ios trailing left.
Replace the profile-header block (avatar + name + email + edit button)
with a "create profile" prompt card — white BG radius 16pt padding 24pt
1pt border #E5E7EB, centered column — person_add icon 48pt #00478D inside
72pt circle BG #EBF4FF, then "צור פרופיל" Inter SemiBold 16pt #1F2937
centered, then "צור פרופיל מותאם אישית כדי לשמור את ההעדפות והאלרגיות
שלך." Inter Regular 13pt #6B7280 centered max-width 280pt, then filled
button "צור פרופיל" BG #00478D label #FFFFFF Inter SemiBold 13pt height
40pt radius 8pt.
Below the profile block, the settings menu rows remain (נהל אלרגיות,
העדפות אפליקציה, מרכז עזרה, אודות) but rendered in disabled style: icon
and label both #9CA3AF, no chevron tap affordance.
```

### P29 — contact-us success state

```
Screen "צור קשר - נשלח בהצלחה" (contact-us success state).
Parent: "Contact Us (Updated)" (existing screen).
Keep parent chrome: detail-bar app-bar with right-aligned title "צור קשר"
+ arrow_back_ios trailing left.
Replace the form (subject dropdown + message field + send button) with a
centered success column — check_circle icon 80pt #16A34A inside 112pt
circle BG #DCFCE7, 32pt top padding; then heading "פנייתך נשלחה בהצלחה"
Public Sans SemiBold 20pt #1F2937 centered; then body "ניצור איתך קשר
בתוך 24 שעות. תוכל להמשיך להשתמש באפליקציה בינתיים." Inter Regular 14pt
#6B7280 centered max-width 300pt 32pt vertical padding; then filled button
"חזרה לבית" BG #00478D label #FFFFFF Inter SemiBold 14pt height 48pt
radius 12pt 16pt horizontal margins.
```

---

## Tier 3 prompts — drawer destinations & sub-screens (P30–P45)

Full new screens reached from the right-anchored navigation drawer
(user or admin) or from in-screen tap targets. All carry the detail-bar
app-bar pattern (no bottom nav unless the destination is itself a tab,
which none of these are). Back-arrow trailing on the left (RTL).

### P30 — ScanHistoryScreen (היסטוריית סריקה)

```
Screen "היסטוריית סריקה" — user drawer destination row 2.
Detail-bar app-bar 56pt: right-aligned title "היסטוריית סריקה" Public Sans
SemiBold 16pt #1F2937, arrow_back_ios trailing left #374151.
Right-aligned counter "127 סריקות בסך הכל" Inter Regular 13pt #6B7280
+ 16pt margins.
Filter chip row (horizontal scroll RTL): chips for "הכל" (selected: BG
#EBF4FF border 1pt #00478D label #00478D Inter SemiBold 12pt), "בטוח",
"זהירות", "הימנע", "30 ימים אחרונים" — 32pt height radius 16pt
unselected style border 1pt #E5E7EB label #374151 BG white.
Scrollable ListView of date-grouped scan rows. Each date group: sticky
header "היום" / "אתמול" / "20 במאי" Inter SemiBold 12pt #6B7280 right-
aligned 16pt margin. Below each header — compact product-row cards
(same layout as FavoritesScreen list: status pill right / 2-line text /
40x40pt thumbnail left), 8pt gap, with extra third-line timestamp "נסרק
בשעה 14:32".
Empty state alt: history icon 64pt #9CA3AF centered, "אין סריקות עדיין"
Public Sans SemiBold 18pt, body "התחל לסרוק מוצרים כדי לראות אותם כאן."
14pt #6B7280, CTA "התחל לסרוק" #00478D.
```

### P31 — SavedProductsScreen (מוצרים שמורים)

```
Screen "מוצרים שמורים" — user drawer destination row 3. Functionally
similar to FavoritesScreen (bottom-nav tab 4) but reached from the drawer
rather than the tab bar — NO bottom nav.
Detail-bar app-bar 56pt: right-aligned title "מוצרים שמורים" Public Sans
SemiBold 16pt #1F2937 + arrow_back_ios trailing left.
Page header block: "כל המוצרים שסימנת לשמירה" Inter Regular 14pt #6B7280
right-aligned 8pt below title.
Stat chip row: "12 מוצרים שמורים" #00478D on #EBF4FF pill radius 20pt
padding 12/4pt + adjacent "מיין" TextButton Inter Medium 13pt #00478D
with sort icon 16pt leading.
Scrollable ListView of product-row cards (white BG radius 12pt padding
12pt subtle shadow 8pt gap). RTL row layout: status pill right; text
column (name SemiBold 14pt + brand·weight 12pt #6B7280 + "נשמר לפני N
ימים" 12pt #9CA3AF); 40x40pt thumbnail left.
Sample rows: 5 entries mixing safe/caution/avoid statuses.
```

### P32 — MyReviewsScreen (ביקורות שלי)

```
Screen "הביקורות שלי" — user drawer destination row 4. No bottom nav.
Detail-bar app-bar with right-aligned title "הביקורות שלי" + arrow_back.
Header block: "התרומה שלך לקהילה" Public Sans SemiBold 18pt right-aligned
+ stat row — 3 inline stats Inter SemiBold 14pt #00478D + label 11pt
#6B7280 below each: "8 ביקורות נשלחו" / "23 הצבעות תמיכה" / "5 ביקורות
אומתו". Separator dots between stats.
TabBar 2 tabs: "ממתינות" / "אומתו" — pill indicator BG #EBF4FF label
#00478D Inter SemiBold 13pt active; inactive label #6B7280.
ListView of review cards — white BG radius 12pt padding 16pt 8pt vertical
gap. Each card RTL row: 40x40pt product thumbnail right; text column —
product name Inter SemiBold 14pt #1F2937 line 1; review type pill (e.g.
"דיווח על אלרגן" #FEF9C3/#A16207, "עדכון רכיבים" #EBF4FF/#00478D) Inter
SemiBold 11pt radius 12pt padding 8/2pt right-aligned line 2; timestamp
"נשלחה לפני 3 ימים" Inter Regular 12pt #9CA3AF line 3. Trailing-left:
status pill — "ממתינה" (caution amber) / "אושרה" (safe green) / "נדחתה"
(avoid red).
```

### P33 — HelpCenterScreen (מרכז עזרה)

```
Screen "מרכז עזרה" — user drawer destination row 5. No bottom nav.
Detail-bar app-bar with right-aligned title "מרכז עזרה" + arrow_back.
Search bar 48pt full-width 16pt horizontal margins — radius 24pt BG
#F3F4F6 with search icon 20pt #6B7280 right-leading + placeholder "חפש
במאמרי עזרה..." Inter Regular 14pt #9CA3AF RTL text.
Section "נושאים פופולריים" Public Sans SemiBold 16pt #1F2937 right-aligned.
GridView 2 columns 12pt gap: 4 topic cards — white BG radius 12pt padding
16pt 1pt border #E5E7EB. Each: leading icon 28pt #00478D in #EBF4FF 48pt
circle (qr_code_scanner / shopping_basket / verified / settings) +
title Inter SemiBold 14pt #1F2937 centered + count "12 מאמרים" Inter
Regular 12pt #6B7280 centered.
Topic titles RTL: "סריקה ושימוש" / "אלרגיות והעדפות" / "תרומה לקהילה" /
"חשבון והגדרות".
Section "שאלות נפוצות" Public Sans SemiBold 16pt right-aligned + ListView
of expandable FAQ rows — each white BG radius 12pt padding 16pt 1pt
border #E5E7EB 8pt gap; RTL row: help_outline icon 20pt #00478D right-
leading + question text Inter SemiBold 14pt #1F2937 + expand_more chevron
20pt #9CA3AF left-trailing.
Bottom: full-width OutlinedButton "צור קשר עם התמיכה" border 1.5pt
#00478D label #00478D Inter SemiBold 14pt 48pt radius 12pt with
support_agent icon 18pt leading.
```

### P34 — AboutScreen (אודות)

```
Screen "אודות" — user drawer destination row 6. No bottom nav.
Detail-bar app-bar with right-aligned title "אודות" + arrow_back.
Hero block: app-icon 88pt rounded-square radius 20pt (BG #00478D with
white shield+leaf glyph centered) + "בטוח לאכול" Public Sans Bold 24pt
#1F2937 centered 16pt top + "גרסה 1.0.0" Inter Regular 13pt #6B7280
centered + 32pt vertical padding.
Description card white BG radius 12pt padding 16pt 1pt border #E5E7EB —
body text "אפליקציה ישראלית לזיהוי אלרגנים במזון, מבוססת קהילה. תרומותיך
עוזרות לאלפי משפחות לאכול בבטחה." Inter Regular 14pt #6B7280 right-aligned
multi-line.
Section "המשימה שלנו" Public Sans SemiBold 14pt right-aligned + body
"להנגיש מידע אמין על אלרגנים במוצרי מזון בישראל, באמצעות תרומות הקהילה
ואימות אנושי." Inter Regular 13pt #6B7280 right-aligned.
ListTile rows 56pt each, RTL leading icon 22pt #00478D right + label
Inter Medium 14pt #1F2937 + chevron_left 18pt #9CA3AF trailing left:
"תנאי שימוש" (description) / "מדיניות פרטיות" (privacy_tip) / "רישיונות
קוד פתוח" (code) / "דרג את האפליקציה" (star_outline) / "שתף עם חברים"
(share).
Footer: centered small text "© 2026 SafeBite. כל הזכויות שמורות." Inter
Regular 11pt #9CA3AF + 16pt bottom safe-area.
```

### P35 — AppPreferencesScreen (העדפות אפליקציה)

```
Screen "העדפות אפליקציה" — settings sub-route (reached from Settings &
Profile menu). No bottom nav.
Detail-bar app-bar with right-aligned title "העדפות אפליקציה" + arrow_back.
Section "התראות" Public Sans SemiBold 14pt #6B7280 right-aligned uppercase
caption + 8pt margin.
SettingsTile rows white BG 64pt each, RTL layout — leading icon 24pt
#00478D right; text column (title Inter Medium 14pt #1F2937 + subtitle
Inter Regular 12pt #6B7280); trailing Switch 28x48pt pill (ON track
#00478D / OFF #E1E3E4, thumb 20pt white) left:
- notifications_active "התראות חכמות" + "קבל התראות על מוצרים חדשים" (ON)
- security_update_warning "התראות על אלרגנים חדשים" + "כאשר זוהו אלרגנים
  חדשים במוצרים שמורים" (ON)
- celebration "עדכוני קהילה" + "תרומות חדשות וביקורות מאומתות" (OFF)
1pt #F3F4F6 divider between rows.
Section "תצוגה". SettingsTile rows:
- dark_mode "מצב כהה" + "השתמש בערכת נושא כהה" Switch (OFF)
- text_fields "גודל טקסט" + subtitle "בינוני" — trailing chevron_left
  (navigates to size picker)
- language "שפה" + subtitle "עברית" — chevron_left
Section "מתקדם":
- storage "ניקוי מטמון" + "57 מ״ב שמורים במכשיר" + TextButton "נקה" #DC2626
- restore "אפס את כל ההעדפות" — destructive TextButton row, label
  #DC2626 with restore icon leading
```

### P36 — ContributionHistoryScreen (היסטוריית תרומות)

```
Screen "היסטוריית תרומות" — settings sub-route. No bottom nav.
Detail-bar app-bar with right-aligned title "היסטוריית תרומות" + arrow_back.
Achievement banner card: white BG radius 16pt padding 20pt 1pt border
#E5E7EB shadow; RTL row — trophy emoji or workspace_premium icon 48pt
#CA8A04 in 72pt circle BG #FEF9C3 right; text column — "תורם פעיל" Public
Sans SemiBold 16pt #1F2937 line 1, "23 תרומות מאומתות" Inter Regular 13pt
#6B7280 line 2, progress bar 4pt height 70% filled #CA8A04 track #E5E7EB
radius 2pt + "עוד 7 לרמה הבאה" Inter Regular 11pt #9CA3AF line 3.
Stat row 3 inline stats — each Inter SemiBold 18pt #00478D + label 11pt
#6B7280: "47 מוצרים" / "23 מאומתות" / "8 ממתינות".
Timeline ListView — each entry: small circle marker (#00478D filled 12pt
or #16A34A for approved) right-leading + vertical line connecting; card
content white BG radius 8pt padding 12pt 1pt border #E5E7EB; RTL row
(product thumbnail 32x32 right + text column: action type "אישרת ביקורת"
Inter SemiBold 13pt + product name 12pt #6B7280 + timestamp "לפני 2 ימים"
11pt #9CA3AF).
Date dividers between months: "מאי 2026" caption Inter SemiBold 12pt
#6B7280 right-aligned.
```

### P37 — AdminDashboardScreen (לוח בקרה)

```
Screen "לוח בקרה" — admin drawer destination row 1. Admin-only. No bottom
nav. Detail-bar app-bar with right-aligned title "לוח בקרה" + arrow_back.
Hero metrics row: 2x2 grid of metric tiles 12pt gap 16pt margins, each
1:1 aspect — white BG radius 16pt padding 16pt 1pt border #E5E7EB. Each
tile: leading icon 24pt #00478D top-right + metric value Inter SemiBold
28pt #1F2937 right-aligned + label Inter Regular 12pt #6B7280 right-aligned
+ delta chip "▲ 12%" Inter SemiBold 11pt #16A34A on #DCFCE7 pill
(or "▼" red) bottom-right.
Metrics: 1) sensors "סריקות היום: 1,247" ▲14%; 2) groups "משתמשים פעילים:
892" ▲3%; 3) inventory "מוצרים במאגר: 34,521" ▲0.4%; 4) pending "ממתינים
לאישור: 47" ▼5%.
Announcements strip: section header "הודעות מערכת" Public Sans SemiBold
16pt right-aligned + horizontal scroll PageView of announcement cards —
each 280pt wide, BG #EBF4FF radius 12pt padding 16pt 1pt border #BFDBFE.
Card: campaign icon 20pt #00478D right + title "עדכון מערכת מתוכנן" Inter
SemiBold 14pt #00478D line 1 + body "תחזוקה ב-25 במאי 02:00-04:00" Inter
Regular 12pt #1E3A8A line 2.
Quick-action row 2 columns: FilledButton "סקירת קהילה" with rate_review
icon + OutlinedButton "ניהול מותגים" with verified icon — 48pt height
radius 12pt #00478D theme.
Activity feed: section header "פעילות אחרונה" + 3 admin-action rows
(approve / reject / new-user) similar layout to contribution timeline.
```

### P38 — ReportsScreen (דיווחים)

```
Screen "דיווחים" — admin drawer destination row 3. Admin only. No bottom
nav. Detail-bar app-bar with right-aligned title "דיווחים מהמשתמשים" +
arrow_back. Right of title: badge pill "47 חדשים" BG #DC2626 label
#FFFFFF Inter SemiBold 11pt radius 12pt padding 8/2pt.
Filter chip row: "הכל" (selected) / "טעות באלרגן" / "מוצר חסר" / "תמונה
לא נכונה" / "אחר" — same chip pattern as P30.
Sort row: "מיון לפי: הכי חדש" Inter Medium 13pt #00478D right-aligned with
sort icon 16pt leading + 16pt margins.
ListView of report cards — each white BG radius 12pt padding 16pt 1pt
border #E5E7EB 8pt gap. RTL row layout:
- Severity stripe (3pt vertical bar) right edge — color encodes priority:
  #DC2626 high / #CA8A04 medium / #6B7280 low
- Text column (flex): RTL row — report type pill (e.g. "טעות באלרגן" BG
  #FEF9C3 label #A16207 SemiBold 11pt radius 12pt) right + reporter
  username "@daniel" Inter Regular 12pt #6B7280 left of pill; product name
  Inter SemiBold 14pt #1F2937 line 2; report body excerpt "מצוין כמכיל
  חלב אך אין ברשימה..." Inter Regular 13pt #374151 line 3 max-lines 2;
  timestamp "לפני 12 דקות" Inter Regular 11pt #9CA3AF line 4
- Trailing-left: chevron_left icon 20pt #9CA3AF
```

### P39 — SystemSettingsScreen (הגדרות מערכת)

```
Screen "הגדרות מערכת" — admin drawer destination row 4. Admin only. No
bottom nav. Detail-bar app-bar with right-aligned title "הגדרות מערכת"
+ arrow_back.
Section "מצב מערכת" Public Sans SemiBold 14pt #6B7280 caption right.
Status card white BG radius 16pt padding 16pt 1pt border #E5E7EB — RTL
row: status dot 12pt #16A34A right + "פעיל - כל המערכות תקינות" Inter
SemiBold 14pt #16A34A right of dot.
Section "הגדרות תוכן" — SettingsTile rows (same pattern as P35):
- shield "מצב סקירה אוטומטית" + "מערכת ML מסננת תרומות חשודות" Switch ON
- public "פתיחת הרשמת משתמשים" + "אפשר רישום משתמשים חדשים" Switch ON
- speed "מצב תחזוקה" + "השבת זמנית את האפליקציה" Switch OFF (destructive
  hint: helper text below #DC2626)
Section "מאגר נתונים":
- cloud_sync "סנכרון OpenFoodFacts" + subtitle "אחרון: לפני 3 שעות" +
  TextButton "סנכרן עכשיו" #00478D
- analytics "אנליטיקה" + subtitle "Mixpanel + Sentry פעילים" + chevron
Section "פעולות סכנה" (destructive section):
- backup "ייצא גיבוי מאגר" — TextButton row #00478D
- delete_forever "אפס את כל הדוחות" — destructive TextButton row #DC2626
  with warning helper text below "פעולה זו אינה ניתנת לביטול"
```

### P40 — ProductScansScreen (סריקות מוצרים)

```
Screen "סריקות מוצרים" — admin drawer destination row 5. Admin only.
Detail-bar app-bar with right-aligned title "סריקות מוצרים" + arrow_back.
Stat row 3 inline mini-stats Inter SemiBold 18pt #00478D + caption 11pt
#6B7280: "1,247 היום" / "8,932 השבוע" / "34,521 בסך הכל". Divider dots
between.
Time range chip row: "היום" (selected #00478D) / "7 ימים" / "30 ימים" /
"הכל" — same chip pattern.
Search field 44pt radius 8pt border #E5E7EB BG white + placeholder "חפש
לפי ברקוד או שם מוצר..." Inter Regular 13pt #9CA3AF RTL.
ListView of scan-row cards — white BG radius 12pt padding 12pt 1pt border
#E5E7EB 8pt gap. RTL row: 48x48pt product thumbnail right radius 8pt;
text column — product name Inter SemiBold 14pt + barcode "ברקוד: 7290000123456"
Inter Regular 12pt #6B7280 + scan-count chip "נסרק 47 פעמים" Inter SemiBold
11pt #00478D on #EBF4FF pill; trailing-left: status icon (check_circle
#16A34A safe / warning_amber #CA8A04 caution / cancel #DC2626 avoid)
24pt + chevron_left 20pt #9CA3AF.
```

### P41 — CommunityManagementScreen (ניהול קהילה)

```
Screen "ניהול קהילה" — admin drawer destination row 6. Admin only.
Detail-bar app-bar with right-aligned title "ניהול קהילה" + arrow_back.
TabBar 3 tabs: "משתמשים" / "ביקורות" / "דיווחים" — pill indicator BG
#EBF4FF label #00478D Inter SemiBold 13pt active; inactive #6B7280.
Tab "משתמשים" content (default):
Search field 44pt + "סנן: כל המשתמשים" dropdown chip.
Stat banner BG #EBF4FF radius 12pt padding 12pt — "8,923 משתמשים פעילים
החודש (+12%)" Inter SemiBold 13pt #00478D right-aligned with trending_up
icon 16pt leading.
ListView of user rows — white BG radius 12pt padding 12pt 1pt border
#E5E7EB. RTL row: 40pt circular avatar right (initial letter on #EBF4FF);
text column — username "דניאל ישראלי" Inter SemiBold 14pt + role pill
"תורם פעיל" Inter SemiBold 11pt #CA8A04 on #FEF9C3 radius 12pt + "47
תרומות · הצטרף 03/2025" Inter Regular 12pt #6B7280; trailing-left:
3-dot more_vert icon 20pt #6B7280 (opens row actions menu).
Special user states: badge dot 8pt #DC2626 on avatar for banned/flagged.
FAB bottom-trailing (left RTL): admin_panel_settings icon 24pt white BG
#00478D 56pt circle (opens user role-change sheet).
```

### P42 — HelpTipsScreen (טיפים)

```
Screen "טיפים לסריקה" — sub-screen reached from search-scan info card
"טיפים" tap target. No bottom nav.
Detail-bar app-bar with right-aligned title "טיפים לסריקה" + arrow_back.
Hero illustration: tips_and_updates icon 80pt #CA8A04 in 120pt circle
BG #FEF9C3 centered 24pt top padding + body "כך תפיק את המרב מהסריקה"
Public Sans SemiBold 18pt #1F2937 centered + subtitle "5 טיפים פרקטיים"
Inter Regular 13pt #6B7280 centered.
ListView of tip cards — white BG radius 16pt padding 16pt 1pt border
#E5E7EB 12pt gap. Each card RTL row: numbered badge 32pt circle BG
#EBF4FF text "1"/"2"/.. Inter SemiBold 14pt #00478D right; text column
— tip title Inter SemiBold 15pt #1F2937 line 1 + tip body Inter Regular
13pt #6B7280 multi-line.
Tip titles RTL:
1. "ודא תאורה טובה" — body about even lighting on barcode
2. "החזק את המכשיר יציב" — about steady hands at 15-20cm
3. "מקד את המסגרת על הברקוד" — about laser alignment
4. "נקה את עדשת המצלמה" — about cleaning the lens
5. "אם הברקוד פגום, הזן ידנית" — about manual fallback
Bottom: TextButton "צריך עוד עזרה?" #00478D Inter SemiBold 14pt centered
with help_outline icon 16pt leading — navigates to HelpCenterScreen.
```

### P43 — ScanInstructionsScreen (הוראות סריקה)

```
Screen "הוראות סריקה" — sub-screen reached from search-scan info card
"איך לסרוק?" tap target. No bottom nav.
Detail-bar app-bar with right-aligned title "איך לסרוק?" + arrow_back.
Step-by-step illustrated guide. 4 stacked instruction cards each white
BG radius 16pt padding 20pt 1pt border #E5E7EB 16pt gap. Each card:
- Centered illustration: 120pt square placeholder BG #EBF4FF radius 12pt
  containing a centered Material icon 56pt #00478D
- 12pt gap
- Step number badge "שלב 1" Inter SemiBold 11pt #00478D BG #EBF4FF radius
  12pt padding 8/2pt right-aligned
- Step title Inter SemiBold 16pt #1F2937 right-aligned
- Step body Inter Regular 13pt #6B7280 right-aligned multi-line

Steps (RTL order):
1. qr_code_scanner icon — "פתח את הסורק" — body "לחץ על כפתור הסריקה הכחול
   במסך הראשי או על הלשונית 'סריקה' בתפריט התחתון."
2. center_focus_strong icon — "כוון אל הברקוד" — body "מרכז את הברקוד
   בתוך המסגרת. הסורק יזהה אותו אוטומטית."
3. visibility icon — "בדוק את התוצאות" — body "המוצר יוצג עם סטטוס בטיחות
   ירוק/צהוב/אדום לפי האלרגנים שהגדרת."
4. bookmark_border icon — "שמור או דווח" — body "סמן מוצרים שאתה אוהב,
   או דווח על טעות כדי לעזור לקהילה."

Bottom: full-width FilledButton "התחל לסרוק עכשיו" BG #00478D label
#FFFFFF Inter SemiBold 14pt 48pt radius 12pt with qr_code_scanner icon
18pt leading.
```

### P44 — ActiveDiscussionScreen (דיון פעיל)

```
Screen "דיון פעיל" — sub-screen reached from community-hub insight card
"דיונים פעילים" tap target. No bottom nav.
Detail-bar app-bar with right-aligned title "דיונים בקהילה" + arrow_back.
Hero discussion card (the active spotlight): white BG radius 16pt padding
20pt subtle shadow 1pt border #E5E7EB 16pt margins. Inside:
- Top: category pill BG #FEF9C3 label "אלרגיית בוטנים" Inter SemiBold
  11pt #A16207 radius 12pt right-aligned + timestamp "פעיל" pill BG
  #DCFCE7 label #16A34A SemiBold 11pt with live-dot animation hint left
- Title "מוצרים חדשים עם אזהרת בוטנים" Public Sans SemiBold 18pt #1F2937
  right-aligned 8pt below pills
- Body excerpt Inter Regular 14pt #374151 right-aligned multi-line
  max-lines 3 12pt below title
- Engagement row: 24pt avatar stack (4 overlapping circles initials
  BG #EBF4FF border 2pt white) right; "23 משתמשים משתתפים" Inter Regular
  12pt #6B7280 right of avatars; comment icon 16pt #6B7280 + "47 הודעות"
  Inter Medium 12pt #6B7280 left of count

ListView of recent reply cards — white BG radius 12pt padding 12pt 1pt
border #E5E7EB 8pt gap. Each RTL row: 36pt avatar circle right (BG
#EBF4FF initial); text column — username + role badge Inter SemiBold
13pt + reply body Inter Regular 13pt #374151 multi-line + timestamp
"לפני 2 שעות" Inter Regular 11pt #9CA3AF.

Bottom sticky action bar: full-width OutlinedButton "הוסף תגובה" border
1.5pt #00478D label #00478D Inter SemiBold 14pt 48pt radius 12pt with
add_comment icon 18pt leading + 16pt horizontal margins + 16pt safe-area.
```

### P45 — WeeklyTipScreen (טיפ השבוע)

```
Screen "טיפ השבוע" — sub-screen reached from community-hub insight card
"טיפ השבוע" tap target. No bottom nav.
Detail-bar app-bar with right-aligned title "טיפ השבוע" + arrow_back.
Hero card 16pt margins: BG gradient (top #00478D bottom #003366) radius
20pt padding 24pt min-height 200pt. Inside RTL: badge pill BG #FFFFFF
20% opacity, label "טיפ השבוע" Inter SemiBold 11pt #FFFFFF radius 12pt
right-aligned; week range "20-26 במאי 2026" Inter Regular 12pt #FFFFFF
80% opacity right line below; title "איך לקרוא תוויות בעברית" Public Sans
Bold 22pt #FFFFFF right-aligned multi-line 12pt below; body "מדריך מהיר
להבנת רשימת רכיבים, אלרגנים מסומנים ואזהרות תזונה." Inter Regular 14pt
#FFFFFF 90% opacity 12pt below.
Section "תוכן הטיפ" Public Sans SemiBold 16pt #1F2937 right-aligned
16pt above + 12pt margins.
Article body card white BG radius 16pt padding 20pt 1pt border #E5E7EB.
Article: structured H2 sub-headings Public Sans SemiBold 15pt #1F2937
right-aligned + paragraph blocks Inter Regular 14pt #374151 right-aligned
line-height 1.6. Inline "important" callout: BG #FEF9C3 right-padded
border-right 4pt #CA8A04 padding 12pt, "חשוב לדעת:" Inter SemiBold 13pt
#A16207 + body Inter Regular 13pt #A16207.
Footer: author row — 32pt avatar + "נכתב ע״י ד״ר רחל כהן, דיאטנית
קלינית" Inter Regular 12pt #6B7280 right-aligned.
Engagement row bottom 8pt gap dividers: thumb_up_outlined 22pt #6B7280
+ count "127" SemiBold 13pt; comment_outlined 22pt + "23"; share
22pt; bookmark_border 22pt — evenly spaced inline buttons.
```

---

## How to use

```dart
// Per prompt:
mcp__stitch__generate_screen_from_text(
  projectId: "16588854804615693446",
  prompt: "<paste shared context + the prompt body here>",
)
```

Record the returned screen ID in `_missing-screens.md` under the matching
row.

**Note:** Stitch generation can take 2–5 minutes per screen and frequently
hits the MCP timeout. If a generate call returns a timeout error, do NOT
retry — wait, then poll `mcp__stitch__list_screens` to see if the screen
landed. The art often arrives even when the MCP call reports timeout.
