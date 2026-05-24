# Stitch Generation Prompts

Per-screen prompts to feed to the Stitch LLM (via
`mcp__stitch__generate_screen_from_text` with `projectId:
"16588854804615693446"`) for screens tracked in `index.md`.

When Stitch returns a screen, record its ID in the **`index.md`** Screen ID
column and set its Stitch cell to ✓.

**All prompts (Tier 1 P1–P10, Tier 2 P11–P29, Tier 3 P30–P45) have been
generated.** Every backlog screen now has Stitch art (P30 ScanHistoryScreen
was the last, run 2026-05-25). This file is kept only as a reference for the
prompt style; no prompts remain outstanding. The P30 prompt is retained below
as a worked example.

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

## Tier 3 prompt — outstanding (P30)

Full new screen reached from the right-anchored user navigation drawer.
Carries the detail-bar app-bar pattern (no bottom nav). Back-arrow trailing
on the left (RTL).

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

---

## How to use

```dart
// Per prompt:
mcp__stitch__generate_screen_from_text(
  projectId: "16588854804615693446",
  prompt: "<paste shared context + the prompt body here>",
)
```

Record the returned screen ID in `index.md` under the matching row (set Stitch
✓ + paste the Screen ID).

**Note:** Stitch generation can take 2–5 minutes per screen and frequently
hits the MCP timeout. If a generate call returns a timeout error, do NOT
retry — wait, then poll `mcp__stitch__list_screens` to see if the screen
landed. The art often arrives even when the MCP call reports timeout.
