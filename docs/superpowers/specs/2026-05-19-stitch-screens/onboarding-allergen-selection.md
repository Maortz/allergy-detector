# Onboarding — Allergen Selection / בחירת אלרגנים
Stitch screen: projects/16588854804615693446/screens/565153749ead4760b7cb331cf3ae28a9
Maps to: app/lib/screens/onboarding_screen.dart

---

## 1. Purpose & context

This is the **first screen a new user sees** after launching the app for the
first time. It gates entry to `MainContainer`: `AppShell` checks
`UserProfile.hasCompletedOnboarding` (stored under the SharedPreferences key
`has_completed_onboarding`) and, when `false`, renders `OnboardingScreen`
instead of the main tab shell.

The screen's sole job is to let the user declare which allergens they personally
monitor. The choices are written to `UserProfile.selectedAllergenIds`, persisted
to SharedPreferences via the `ValueChanged<UserProfile> onProfileUpdated`
callback, and consumed by `ProductCard.status` wherever the user later scans or
searches for products.

The screen is presented as **step 1 of 2** of a lightweight two-step onboarding
flow (step 2 is implied by the progress indicator — not currently implemented as
a separate screen in the app). No authentication is required; the profile is
local-only.

---

## 2. Visual layout breakdown

The screen is a single `Scaffold` (no `AppBar` widget; the brand header is
rendered inline in the body) with `Directionality(textDirection: TextDirection.rtl)`
wrapping the entire tree. There is no bottom navigation bar on this screen — it
is a pre-main-shell flow.

Layout is a vertical `Column` inside a `SafeArea`, top-to-bottom:

| Zone | Height / behaviour | Content |
|---|---|---|
| **Brand header** | Fixed, ~56 pt | App name "SafeBite" (top-left in LTR, i.e. RTL trailing), close ✕ icon (top-right in LTR, i.e. RTL leading) |
| **Headline block** | Fixed, auto | Large title + step counter row + subtitle body copy |
| **Progress row** | Fixed, ~24 pt | "שלב 1 מתוך 2" label (RTL start) · "בחרו אלרגנים (N נבחרו)" counter (RTL end) |
| **Linear progress bar** | Fixed, 6 pt tall | 50 % fill at step 1 of 2 |
| **Hero banner** | Fixed, ~192 pt | Food/allergy-themed image (nuts, milk in a bowl) on a light surface background |
| **Allergen grid** | `Expanded` / scrollable | 3-column grid of allergen selection cards |
| **Disclaimer footer** | Fixed, auto | Small italic legal copy |
| **Continue button** | Fixed, 52 pt | Full-width primary CTA "המשך ←" |

**Horizontal margins:** 16 pt (`AppSpacing.margin`) left and right throughout.
**Background colour:** `AppColors.background` (`#F9FAFB` or equivalent surface-0 token).

---

## 3. Component inventory

| # | Component | Source | Notes |
|---|---|---|---|
| 1 | Brand header inline row | Screen-specific (not `app-bar`) | "SafeBite" text RTL-trailing; ✕ icon RTL-leading |
| 2 | Headline "ברוכים הבאים ל-SafeBite" | Screen-specific text widget | Public Sans SemiBold, `AppColors.onSurface` |
| 3 | Step counter row | Screen-specific | Two `Text` widgets in `Row(mainAxisAlignment: spaceBetween)` |
| 4 | Linear progress bar | Shared — see `_components-glossary.md#wizard-chrome` (partial parallel) | 50 % fill; height 6 pt; clipped with `BorderRadius.circular(4)` |
| 5 | Hero banner | Screen-specific image container | 192 pt tall, `AppColors.surfaceContainerLow` bg; fallback icon `shield_outlined` |
| 6 | Allergen selection cards (×12–13) | Screen-specific (Variant C analog) — see §4 | 3-column grid, square-ish toggle cards |
| 7 | Disclaimer text | Screen-specific `Text` | Inter Regular 11 pt, `AppColors.onSurfaceVariant`, centred |
| 8 | Continue CTA | see `_components-glossary.md#primary-button` | "המשך" label; disabled until ≥1 allergen selected |

---

## 4. Sub-components / element design

### 4.1 Brand header row

Rendered as a `Padding` + `Row` at the very top of the body (not a Flutter
`AppBar`). This avoids the standard app-bar chrome because onboarding is a
standalone flow outside `MainContainer`.

- **RTL trailing (right side):** Text "SafeBite", Inter Medium 16 pt,
  `AppColors.primary` `#00478D`.
- **RTL leading (left side):** `Icons.close` / `cancel` ✕, 24 pt,
  `AppColors.onSurfaceVariant` `#374151`. Tapping exits the onboarding flow
  (behaviour TBD — likely no-op or back-presses to exit app since there is
  no prior screen for a first-run user).
- Height: ~56 pt, consistent with `_components-glossary.md#app-bar` proportions,
  but implemented as a plain row.

### 4.2 Headline block

```
ברוכים הבאים ל-SafeBite          ← Public Sans SemiBold ~22 pt, #1F2937
בחרו את האלרגנים שאתם רוצים      ← Inter Regular 14 pt, #6B7280, multi-line
להימנע מהם ואנחנו נוודא שתמיד
תדעו מה בטוח לאכול.
```

Vertical gap between title and body: `AppSpacing.sm` (8 pt).

### 4.3 Step counter and progress bar

**Counter row** — `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)`:
- RTL start (right): `"שלב 1 מתוך 2"` — Inter Regular 12 pt,
  `AppColors.onSurfaceVariant` `#6B7280`.
- RTL end (left): `"בחרו אלרגנים (N נבחרו)"` — Inter Regular 12 pt; colour
  changes from `#6B7280` (0 selected) to `AppColors.primary` `#00478D` (≥1
  selected).

**Progress bar:**
- `LinearProgressIndicator`, height 6 pt, clipped with `BorderRadius.circular(4)`.
- Filled track: `AppColors.primary` `#00478D`.
- Unfilled track: `AppColors.surfaceContainerHigh` (token TBD — approx `#E5E7EB`).
- Value: `0.5` (fixed at step 1 of 2 — will be `1.0` on step 2).

### 4.4 Hero banner

- Container: `width: double.infinity`, height 192 pt.
- Background: `AppColors.surfaceContainerLow` (token TBD — approx `#F3F4F6`).
- Content: a food/allergen photo (nuts, milk bowl) — in the app currently
  replaced by `Icons.shield_outlined` (80 pt, `AppColors.primaryFixedDim`) as a
  placeholder.
- The Stitch design shows a real photograph. The delta from the app
  placeholder is noted in §7.

### 4.5 Allergen selection cards

These are the primary interactive element of the screen. They form a **3-column
grid** (`crossAxisCount: 3`) with 12–13 cards depending on the allergen catalog
returned by Supabase.

**Relationship to `allergen-chip` Variant C:** Variant C (wizard toggle chip in
`_components-glossary.md#allergen-chip`) is a **2-column** square card used in
the Add-Product wizard. The onboarding selection cards are visually similar in
concept (square toggle, icon + label, selected/unselected states) but differ in
**grid density (3-col vs 2-col)**, **card size**, and **selected-state colour
treatment**. They are therefore specified here as a **screen-specific selection
card** (named `OnboardingAllergenCard`, implemented as `AllergenCard` in
`app/lib/widgets/allergen_card.dart`), with Variant C noted as a close relative.

**Card geometry:**
- Grid: 3 columns, `crossAxisSpacing: AppSpacing.md` (12 pt),
  `mainAxisSpacing: AppSpacing.md` (12 pt), `childAspectRatio: 1.0` (square).
- Card width ≈ `(screenWidth − 32 − 24) / 3` ≈ ~108 pt on a 390 pt screen.
- `BorderRadius.circular(16)`.

**Unselected state:**
- Background: `AppColors.surfaceContainerLow` (token TBD — approx `#F3F4F6`).
- Border: 1 pt solid `AppColors.outlineVariant` (token TBD — approx `#E5E7EB`).
- Icon container: 48 pt circle, fill `AppColors.primaryContainer`
  (token TBD — approx `#DBEAFE` / light blue).
- Icon: 24 pt, colour `AppColors.onPrimary` (note: may be better expressed as
  `AppColors.primary`; exact token TBD from implementation).
- Label: allergen name in Hebrew, `AppTypography.labelBold`, `AppColors.onSurface`.

**Selected state:**
- Background: `AppColors.surfaceContainerLow` (unchanged — the Stitch screenshot
  shows the card surface stays light; emphasis is delivered by the border and
  icon container, not a full blue fill — contrast with Variant C which fills
  the card `#00478D`).
- Border: 2 pt solid `AppColors.primary` `#00478D`.
- Icon container: 48 pt circle, fill `AppColors.primaryFixed`
  (token TBD — approx `#BFDBFE` / mid-blue tint).
- Icon: 24 pt, colour `AppColors.onPrimaryFixed` (token TBD — near white or
  deep blue).
- Label: same as unselected — `AppTypography.labelBold`, `AppColors.onSurface`.
- A `check_circle` indicator is visible in the design (top corner of selected
  card or overlaid on the icon container — exact position from Stitch HTML
  extraction; token TBD).

**Allergen list** (13 items as shown in Stitch; order matches Stitch left-to-right,
top-to-bottom in RTL grid — i.e. right-to-left within each row):

| Hebrew name | English | Material icon (glossary mapping) |
|---|---|---|
| בוטנים | Peanuts | `park` (glossary uses `park` for peanuts) |
| חלב | Milk | `water_drop` |
| ביצים | Eggs | `egg` |
| סויה | Soy | `nutrition` |
| חיטה | Wheat/Gluten | `grass` |
| אגוזי מלך | Walnuts | `energy_savings_leaf` |
| שקדים | Almonds | `nature` |
| קשיו | Cashews | `emoji_nature` |
| פיסטוקים | Pistachios | `grain` |
| אגוזי לוז | Hazelnuts | `spa` |
| פקאנים | Pecans | `local_florist` |
| אגוזי ברזיל | Brazil nuts | `filter_vintage` |
| שומשום | Sesame | (TBD — not confirmed from screenshot) |

Note: the icon assignments above reconcile the glossary's allergen icon mapping
with the Stitch HTML extraction. Where the Stitch HTML names differ from the
glossary (e.g. "psychiatry" for walnut, "yard" for hazelnut, "forest" for
pecan), the **glossary canonical icons** take precedence (DD-3 principle: shared
component definitions win). The Stitch HTML icon names are likely auto-generated
placeholders.

**Interaction:**
- `GestureDetector.onTap` → `_toggleAllergen(allergen)` → `setState` rebuilding
  the card with new `isSelected`.
- Cards are individually tappable with no multi-select limit enforced (all 13
  may be selected simultaneously).

### 4.6 Disclaimer footer

```
המידע מבוסס על נתונים גולמיים ואינו מהווה תחליף לייעוץ רפואי מקצועי.
```

- Inter Regular 11 pt (or `AppTypography.labelSm`), `AppColors.onSurfaceVariant`.
- Centred (`TextAlign.center`).
- Padding: `EdgeInsets.fromLTRB(16, 12, 16, 8)`.

The Stitch HTML also surfaces a slightly longer variant of this disclaimer:
> "בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי"

The app currently uses the shorter form. Both convey the same intent; the longer
form is the Stitch-canonical copy (see §7.2).

### 4.7 Continue button

See `_components-glossary.md#primary-button` (Standard CTA / Primary variant).

- Label: `"המשך"`. No trailing icon in the Stitch design (the app code renders
  no icon either; the HTML extraction mentioned `arrow_back` but the screenshot
  and app code do not corroborate a visible icon).
- Height: 52 pt (app) / 48 pt (glossary canonical). Delta noted in §7.3.
- Border-radius: app uses `BorderRadius.circular(16)`; glossary specifies 12 pt.
  Delta noted in §7.3.
- **Disabled state:** when `_selectedCount == 0` → background
  `AppColors.surfaceContainerHigh`, text `AppColors.onSurfaceVariant`.
- **Enabled state:** background `AppColors.primary` `#00478D`, text white.

---

## 5. States & interactions

### 5.1 Zero-selection state (initial)

- Progress bar at 50 % (step 1 of 2), all cards unselected.
- Counter label: `"בחרו אלרגנים (0 נבחרו)"` in `#6B7280`.
- Continue button: **disabled** (grey background, grey text).
- User cannot proceed — this is the gate enforced by `onPressed: _selectedCount > 0 ? _complete : null`.

### 5.2 Partial / active selection state

- One or more cards tapped → each tapped card transitions to selected state
  (blue border, blue icon container).
- Counter label updates to `"בחרו אלרגנים (N נבחרו)"` and changes colour to
  `AppColors.primary` `#00478D`.
- Continue button: **enabled** (Medical Blue fill, white "המשך" text).

### 5.3 Selection toggle

- Tapping a selected card deselects it (reverts to unselected state).
- `UserProfile.toggleAllergen(allergen)` handles add/remove on the
  `selectedAllergenIds` set.
- Minimum selection to enable Continue: **1** allergen.
- Maximum selection: unlimited (all 13 may be selected).

### 5.4 Continue action

- `_complete()` calls `_profile.copyWith(hasCompletedOnboarding: true)`.
- The updated profile is passed to `widget.onProfileUpdated`, which bubbles up
  to `AppShell`.
- `AppShell` persists to SharedPreferences and rebuilds, replacing
  `OnboardingScreen` with `MainContainer`.
- There is no animated transition specified in the Stitch design — the
  replacement is implicit from the `AppShell` rebuild.

### 5.5 Step 2

The progress bar and counter indicate a step 2 exists. The Stitch project
contains a separate "Onboarding - Notifications / Permissions" screen (not this
spec). The current app implementation treats onboarding as single-step and
immediately navigates to `MainContainer` upon "המשך". This is a known delta
(§7.4).

---

## 6. Data & controller contract

### 6.1 Inputs (constructor)

```dart
OnboardingScreen({
  required List<Allergen> allergens,       // catalog from Supabase, fetched in AppShell
  required UserProfile userProfile,        // initial profile (hasCompletedOnboarding: false)
  required ValueChanged<UserProfile> onProfileUpdated,
})
```

`allergens` is fetched by `AppShell` at startup from the Supabase `allergens`
table (via an allergen service or direct client query). The screen renders
whatever allergens are returned — no hard-coded list.

### 6.2 Local state

```dart
late UserProfile _profile;          // copy of widget.userProfile, mutated via setState
int get _selectedCount => _profile.selectedAllergenIds.length;
```

`_profile` is a value type (immutable); each toggle calls `_profile.toggleAllergen()`
which returns a new instance, assigned back via `setState`.

### 6.3 UserProfile fields in play

| Field | Type | Default | Role |
|---|---|---|---|
| `selectedAllergenIds` | `Set<String>` | `{}` | Drives card selected-state, counter label, button enable |
| `hasCompletedOnboarding` | `bool` | `false` | Set to `true` on `_complete()`; gates navigation in `AppShell` |

### 6.4 SharedPreferences keys

| Key | Written by | Read by | Value |
|---|---|---|---|
| `has_completed_onboarding` | `AppShell` (via `onProfileUpdated` callback) | `AppShell` on launch | `bool` |
| `selected_allergen_ids` (or equivalent) | `AppShell` | `AppShell` on launch | Serialised `Set<String>` |

Exact key names are in `AppShell` / `UserProfile` persistence layer
(`app/lib/models/user_profile.dart` — not read for this spec; names may differ).

### 6.5 Output / side-effects

- No Supabase writes (read-only catalog fetch is the only network call, and it
  happens in `AppShell` before this screen is shown).
- On `_complete()`, `onProfileUpdated` is called once with the final profile.
  `AppShell` serialises and navigates.

---

## 7. Open questions / design-vs-app deltas

### 7.1 Hero banner: photo vs. placeholder icon

**Stitch design:** Shows a real food photograph (bowl with nuts, glass of milk —
stock or generated image, source unknown).
**App:** Renders `Icons.shield_outlined` (80 pt, `AppColors.primaryFixedDim`)
inside a plain `AppColors.surfaceContainerLow` container as a placeholder.

→ The spec-to-implementation plan should supply a real or AI-generated image
asset for the hero banner, or confirm the icon placeholder is intentional.

### 7.2 Disclaimer copy variant

**Stitch HTML:** `"בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי"`
**App code:** `"המידע מבוסס על נתונים גולמיים ואינו מהווה תחליף לייעוץ רפואי מקצועי."`

Both disclaim medical advice. The Stitch version is more explicit about the act
of tapping Continue as confirmation. **Stitch is the design source of truth** —
recommend aligning app copy to Stitch.

### 7.3 Continue button: height and border-radius

**Glossary canonical (`primary-button`):** height 48 pt, `BorderRadius.circular(12)`.
**App code:** `SizedBox(height: 52)`, `BorderRadius.circular(16)`.

The app diverges from the glossary on both dimensions. Implementation should
align to the glossary (48 pt / 12 pt radius) unless a screen-specific override
is explicitly chosen.

### 7.4 Single-step vs. two-step onboarding

**Stitch design:** "שלב 1 מתוך 2" — explicitly indicates a second onboarding
step (likely notifications/permissions screen).
**App:** `_complete()` immediately sets `hasCompletedOnboarding: true` and
returns to `AppShell`, skipping any step 2. The progress bar is hardcoded to
`value: 0.5`.

→ Either implement step 2 per the Stitch spec, or update the design to remove
the step indicator. This is a scope question for the product owner.

### 7.5 Allergen name variants: singular vs. plural

The Stitch design uses plural forms for most allergens ("אגוזי מלך",
"שקדים", "קשיו", "פיסטוקים", "פקאנים", "אגוזי לוז", "אגוזי ברזיל") while the
glossary's allergen icon mapping uses singular/construct forms ("אגוז מלך",
"שקד", "קשיו", "פיסטוק", "פקאן", "אגוז לוז", "צנובר"). The display name is
driven by `allergen.nameHe` from the Supabase seed data — the seed data copy
should be verified to match the Stitch design copy.

Deferred per _design-decisions.md#dd-7 (non-blocking). The Hebrew name form (plural vs singular/construct) is owned by the Supabase seed data (`supabase/seed.sql`) and is out of scope for UI specs. Specs bind allergens by ID; `allergen.nameHe` from data drives the display. Both plural and singular forms may appear in spec prose as illustrative — implementation must bind `allergen.nameHe` from the seed, not hardcode either form.

### 7.6 Brazil nuts: not in current app allergen model

"אגוזי ברזיל" (Brazil nuts) appears in the Stitch design's allergen grid but is
not listed in the `_components-glossary.md` allergen icon mapping table (which
ends at "צנובר / Pine nut"). Its Material icon assignment is `filter_vintage`
per the HTML extraction. This allergen may or may not exist in the Supabase seed
data. Icon mapping should be added to the glossary once confirmed.

### 7.7 AllergenCard selected-state: full blue fill vs. border-only

**Variant C (`allergen-chip`):** selected state fills the entire card `#00478D`
with white icon and label — a strong blue fill.
**OnboardingAllergenCard (this screen):** selected state shows a blue border
(2 pt `#00478D`) and a blue-tinted icon container circle, but the card surface
remains light. This is a genuine visual difference between the two toggle-card
patterns, intentionally specced separately in §4.5.

---

## Resolved cross-screen note

**Allergen Hebrew name plurality — deferred per DD-7 (non-blocking)**

Deferred per _design-decisions.md#dd-7. The plural vs. singular/construct form of Hebrew allergen names (e.g. "שקדים" vs "שקד", "פיסטוקים" vs "פיסטוק") is owned by the Supabase seed data and is out of scope for UI specs. Specs reference allergens by ID only; `allergen.nameHe` from the seed drives all rendered names at runtime. Either form may appear in spec prose as illustrative. The seed SQL owner / PM is responsible for choosing and applying a consistent form across the seed, the glossary icon table, and all downstream screens. This item is open (non-blocking for spec implementation).
