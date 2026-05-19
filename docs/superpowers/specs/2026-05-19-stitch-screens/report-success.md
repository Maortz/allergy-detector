# דיווח נשלח בהצלחה / Report — Success Confirmation
Stitch screen: projects/16588854804615693446/screens/4bb210f9ac7143e0a6d1558dd950a62d
Maps to: app/lib/screens/feedback_success_screen.dart

---

## 1. Purpose & context

This is the **terminal confirmation screen** of the Report Issue flow. It is shown immediately after the user submits a product-issue report (e.g. incorrect allergen data, wrong label) and the report is successfully transmitted. Its sole purpose is to confirm receipt, set expectations that the submission will be reviewed, and return the user to the main app.

The screen is **not part of a wizard** — it does not display wizard chrome (no progress bar, no "חזרה"/"המשך" footer). It replaces the report form entirely after a successful submission.

**Entry point:** Navigated to programmatically after the report-issue form's submit action completes (success path only). The back stack should be cleared so the user cannot navigate back into the form.

**Exit points:** A single "חזרה לדף הבית" primary button returns the user to the Home tab (index 0 of the main `IndexedStack`/`NavigationBar`). The bottom navigation bar is also present and functional, allowing direct tab switching. No other exit.

**Relationship to `add-product-success.md`:** Both screens share the same structural pattern — centered success illustration, headline, body copy, badge pair, single CTA, bottom nav. They diverge in copy, badge content, CTA destination (Home vs. Community), illustration color tokens, and app-bar title. Keep the `FeedbackSuccessScreen` and `AddProductSuccessScreen` widget implementations parallel.

---

## 2. Visual layout breakdown

The screen uses a **light grey scaffold background** (`#F8F9FA`, `surface-bright` in the design-system token map — approximately `AppColors.surfaceVariant` or `Colors.grey[50]`; token TBD) with a fixed top app bar and a fixed bottom navigation bar.

Canvas: 390 pt wide / 780 px at 2×. Total Stitch height: 1816 px (908 pt).

| Zone | Approximate height | Content |
|---|---|---|
| App bar (fixed) | 56 pt | Flow-specific title "דיווח מועבר", avatar top-right, menu icon |
| Top spacer (under fixed bar) | ~24 pt | Grey scaffold padding |
| Success illustration | ~300 pt (max-w 300 pt square) | Circular white container + teal `check_circle` icon, decorative network background image |
| Gap | ~24 pt | `mb-lg` spacing |
| Headline | ~38 pt | "הדיווח נשלח בהצלחה!" — Public Sans Bold 30 pt |
| Body copy | ~48 pt | 2-line Hebrew text, Inter Regular 16 pt |
| Gap | ~32 pt | `mb-xl` |
| Badge row | ~40 pt | Two inline badges side-by-side |
| Gap | ~32 pt | `mb-xl` |
| Primary CTA button | 48 pt | "חזרה לדף הבית", full-width, `#005EB8` (`primary-container`) |
| Footer | ~56 pt | "תודה על תרומתך..." + brand line, 60% opacity |
| Bottom nav (fixed) | 56 pt + safe area | 4-tab nav, "בית" active |

**No white card wrapper:** Unlike `add-product-success` which centers content in a white rounded card, this screen renders content **directly on the grey scaffold** with a floating circular illustration element. The illustration circle is white with a large drop shadow, acting as the visual anchor.

---

## 3. Component inventory

| # | Component | Source | Notes |
|---|---|---|---|
| 1 | App bar — flow title variant | see _components-glossary.md#app-bar | Title "דיווח מועבר" (not brand "בטוח לאכול"); avatar + menu icon. Hybrid of brand-bar structure with a flow-specific label (see §7.1). |
| 2 | Success illustration / checkmark | Screen-specific (§4.1) | Circular white container with `shadow-xl`, `check_circle` FILL 1 icon in teal (`secondary`), decorative background image at 10% opacity |
| 3 | Headline text | Screen-specific copy (§4.2) | "הדיווח נשלח בהצלחה!" |
| 4 | Body copy | Screen-specific copy (§4.3) | Submission confirmation and community-safety message |
| 5 | Badge pair | Screen-specific (§4.4) | "נבדק ע״י מערכת" + "קהילה בטוחה"; not the shared `status-pill` |
| 6 | Primary CTA button | see _components-glossary.md#primary-button | "חזרה לדף הבית", Standard variant, `#005EB8` fill, icon `arrow_forward` (see §7.2) |
| 7 | Footer text | Screen-specific (§4.5) | "תודה על תרומתך לבטיחות המזון בישראל" + brand line; decorative, 60% opacity |
| 8 | Bottom navigation bar | see _components-glossary.md#bottom-nav | "בית" tab active (index 0); follows DD-2 / DD-4 canonical 4-tab nav |

**No wizard chrome** (no progress bar, no "חזרה"/"המשך" footer). This is a post-flow screen presented within the main app chrome.

---

## 4. Sub-components / element design

### 4.1 Success illustration / checkmark

A centered compound visual element sitting on the grey scaffold:

- **Outer container:** `Container` with `BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 24, spreadRadius: 4, color: Colors.black.withOpacity(0.12))])`. Diameter: ~120 pt (design-system `p-xl = 32 pt` padding around the icon; icon ~80 pt → total ~112–120 pt).
- **Border:** 4 pt solid `secondary-container` = `#78F8DD` (light teal). This is a teal accent, NOT Medical Blue.
- **Background image (decorative):** A faint network/mesh image at 10% opacity (`Opacity(opacity: 0.1)`), `scale: 1.1`, positioned absolutely behind the white circle in a `Stack`. The image is purely decorative — no alt text required for accessibility.
- **Icon:** `Icons.check_circle` (FILL 1 — use the filled variant), size ~80 pt, color `secondary` = `#006B5B` (dark teal). Token: `AppColors.secondary` (token TBD; see §7.5).
- **Entry animation (optional):** `ScaleTransition` from 0.8 → 1.0 over 400 ms with `Curves.easeOutBack`, triggered once on `initState` via an `AnimationController`. Implement only if confirmed in design review.

> **Color note:** The teal (`#006B5B` icon, `#78F8DD` border) comes from the design-system `secondary` / `secondary-container` tokens. This is distinct from the `#0D9488` used in `add-product-success.md`'s illustration. See §7.5 for the token alignment question.

### 4.2 Headline

- Text: **"הדיווח נשלח בהצלחה!"** (verbatim, with exclamation mark).
- Style: Public Sans Bold 30 pt (design-system `h1`: `fontSize: 30px, lineHeight: 38px, fontWeight: 700`), color `#00478D` (`AppColors.primary`). Token: `AppTypography.h1`.
- Alignment: `TextAlign.center`.
- Note: Uses `h1` (30 pt), one size larger than `add-product-success`'s `h2` (24 pt) — intentional visual weight for the report confirmation.

### 4.3 Body copy

- Text: **"המידע נשלח לבדיקה ויעודכן בקרוב. יחד אנחנו שומרים על הקהילה בטוחה."** (verbatim, may wrap across 2–3 lines).
- Style: Inter Regular 16 pt (`body-md`: `fontSize: 16px, lineHeight: 24px, fontWeight: 400`), color `#424752` (`on-surface-variant`). Token: `AppTypography.bodyMd`.
- Alignment: `TextAlign.center`.
- Horizontal padding: `EdgeInsets.symmetric(horizontal: 8)` (`px-sm`).

### 4.4 Badge pair ("report-status-badge-pair")

A horizontal `Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min)` with `gap: 8 pt` (`gap-sm`) between two badges. These are **not** the shared `status-pill` component (which encodes allergen safety verdicts). They are screen-specific informational badges about the submission's processing status.

**Badge A — "נבדק ע״י מערכת" (Verified by system):**
- Background: `secondary-container` at 30% opacity — `rgba(120, 248, 221, 0.30)`, light teal wash.
- Border: 1 pt solid `secondary-fixed-dim` = `#59DBC1` (light teal).
- Border-radius: `BorderRadius.circular(12)` (`rounded-xl`).
- Padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` (`px-md py-sm`).
- Icon: `Icons.verified` (FILL 1), 18 pt, color `secondary` = `#006B5B`.
- Label: Inter SemiBold 14 pt (`label-bold`), color `on-secondary-container` = `#007261`.
- Icon–label gap: 8 pt.

**Badge B — "קהילה בטוחה" (Safe community):**
- Background: `primary-fixed` at 20% opacity — `rgba(214, 227, 255, 0.20)`, light blue wash.
- Border: 1 pt solid `primary-fixed-dim` = `#A9C7FF` (light blue).
- Border-radius: `BorderRadius.circular(12)` (`rounded-xl`).
- Padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` (`px-md py-sm`).
- Icon: `Icons.groups` (FILL 1), 18 pt, color `primary` = `#00478D`.
- Label: Inter SemiBold 14 pt (`label-bold`), color `on-primary-fixed-variant` = `#00468C` (≈ Medical Blue).
- Icon–label gap: 8 pt.

These badges are unique to this screen. Do not add to the glossary unless they reappear on other screens.

### 4.5 Primary CTA button — "חזרה לדף הבית"

- see _components-glossary.md#primary-button (Standard variant).
- Label: **"חזרה לדף הבית"** (verbatim).
- Leading icon (RTL right side): `Icons.arrow_forward`, 24 pt, `Colors.white`. In RTL, `arrow_forward` renders as a leftward arrow (←) — verify on device; see §7.2.
- Background: `primary-container` = `#005EB8` (darker Medical Blue). Token: `AppColors.primaryContainer` (token TBD; see §7.4).
- Text color: `Colors.white`.
- Width: full-width within 16 pt horizontal margins.
- Height: 48 pt, border-radius 12 pt (`rounded-xl`).
- Positioned directly on the grey scaffold below the badge row, with ~32 pt gap above.

### 4.6 Footer

A centered footer block rendered at 60% opacity (`Opacity(opacity: 0.6)`), positioned below the CTA with ~32 pt top margin:

- **Line 1:** "תודה על תרומתך לבטיחות המזון בישראל" — Inter Medium 12 pt (`label-sm`), color `on-surface` = `#191C1D`.
- **Line 2:** `Row(mainAxisAlignment: MainAxisAlignment.center)` with:
  - `Icons.health_and_safety`, `#00478D` (`AppColors.primary`).
  - "בדיקת אלרגנים" — Public Sans Black (weight 900) 18 pt, `#005EB8`.
  - Gap: 8 pt between icon and text.
- The footer is decorative and optional — see §7.3 for the brand-name delta.

---

## 5. States & interactions

### 5.1 Default / only state

This screen has a single display state. There are no loading, error, or empty variants — the screen is only reached on the success path of the report-issue flow.

### 5.2 "חזרה לדף הבית" button tap

- **Action:** Pop the report flow from the navigation stack and navigate to the Home tab (index 0 of `MainContainer`'s `IndexedStack`).
- **Flutter routing:** `Navigator.of(context).pushAndRemoveUntil(...)` back to `MainContainer` with `initialIndex: 0`, OR invoke a callback/event on `AppShell` to switch tab index to 0. The back stack must not allow returning to the report form or the success screen.
- **No loading state** on the button — navigation is synchronous once the report is already persisted.

### 5.3 Bottom navigation bar taps

- The bottom nav is present and functional on this screen (post-flow, main app chrome).
- **"בית" (index 0) is the active tab.**
- Tapping any other tab navigates to that tab and removes this screen from the stack.
- See _components-glossary.md#bottom-nav for tab definitions and active-state styling.

### 5.4 Back gesture / hardware back

- Tapping hardware back or swipe-back should behave identically to the "חזרה לדף הבית" button — it must NOT re-enter the report form. The back stack must be cleared when navigating to this screen.

### 5.5 Entry animation (optional)

The Stitch HTML specifies `transform transition-transform duration-700 hover:scale-105` on the illustration circle. On Flutter: `ScaleTransition` (0.8 → 1.0, 400 ms, `Curves.easeOutBack`) triggered once on `initState`. Implement only after design review confirms it.

---

## 6. Data & controller contract

### 6.1 Inputs (what the screen receives)

The success screen requires **no runtime data** beyond confirmation that the report was submitted. The design uses generic confirmation copy — no report ID, product name, or timestamp is displayed.

```dart
// Proposed widget signature (no data dependencies):
class FeedbackSuccessScreen extends StatelessWidget {
  final VoidCallback onReturnToHome;  // navigates to Home tab (index 0)
  const FeedbackSuccessScreen({super.key, required this.onReturnToHome});
}
```

If the entry animation (§5.5) is implemented, use `StatefulWidget` with `SingleTickerProviderStateMixin` for the `AnimationController`.

### 6.2 Controller / state

- **No controller needed** for the display logic. The screen is entirely static display + one tap handler.
- The upstream report-issue form (or its controller) is responsible for the Supabase insert. This screen is navigated to only after that insert succeeds.
- If the animation is added: one `AnimationController` (duration 400 ms), one `CurvedAnimation`, one `ScaleTransition` — dispose in `dispose()`.

### 6.3 App-side delta

The target file `app/lib/screens/feedback_success_screen.dart` may exist as a stub or placeholder. Implementation checklist:

1. Verify the file exists and inspect its current widget signature.
2. Replace placeholder content with the full layout described in §2 and §4.
3. Wire `onReturnToHome` callback to the tab-switching mechanism in `AppShell` / `MainContainer` (index 0).
4. Navigate to this screen from the report form using `Navigator.pushReplacement` or `pushAndRemoveUntil` so the back stack is cleared.
5. Decide whether to use the flow-specific app bar title "דיווח מועבר" or the standard brand bar "בטוח לאכול" (see §7.1).

---

## 7. Open questions / design-vs-app deltas

### 7.1 App bar title: "דיווח מועבר" vs. standard brand bar <!-- DELTA -->

The Stitch screenshot renders **"דיווח מועבר"** (Public Sans Bold, `#005EB8`) alongside the avatar and menu icon — a hybrid of the brand-bar structure with a flow-specific label. Other post-flow screens (e.g. `add-product-success`) use the standard brand bar "בטוח לאכול". Recommendation: use the standard brand bar "בטוח לאכול" for consistency; "דיווח מועבר" appears to be a Stitch-specific naming artifact. This is a screen-local delta only.

### 7.2 CTA icon directionality: `arrow_forward` in RTL context <!-- DELTA -->

The Stitch HTML uses `Icons.arrow_forward` as the button's leading icon. In Flutter with `TextDirection.rtl`, `arrow_forward` renders pointing left (←), which is semantically correct for "proceed / return." The icon appears to the LEFT of the label text in the Stitch screenshot (leading in LTR layout = right side in RTL). Verify on device. If directionality is ambiguous, prefer `Icons.home` for semantic clarity, or confirm whether `PrimaryButton` in the glossary needs a `leadingIcon` parameter added.

### 7.3 Footer brand name: "בדיקת אלרגנים" vs. "בטוח לאכול" <!-- DELTA -->

The footer renders **"בדיקת אלרגנים"** as the brand/app name. The app and all other screens use **"בטוח לאכול"**. This is a Stitch design artifact — an alternate brand name. On implementation, use "בטוח לאכול", or omit the footer brand line entirely if it adds no user value.

### 7.4 CTA background: `primary-container` (#005EB8) vs. `primary` (#00478D) <!-- DELTA -->

The CTA uses `bg-primary-container` (`#005EB8`), slightly darker than `AppColors.primary` (`#00478D`). This may be a Stitch token-mapping artifact, or intentional emphasis. On implementation, use `AppColors.primary` (`#00478D`) per the standard `primary-button` spec unless a distinct `AppColors.primaryContainer` token is explicitly introduced. Screen-local delta; no cross-screen conflict.

### 7.5 Success illustration color: `secondary` tokens vs. `AppColors.success` <!-- DELTA -->

The illustration uses `secondary` (`#006B5B`) and `secondary-container` (`#78F8DD`) from the design-system. `add-product-success.md` uses `#0D9488` (labelled `AppColors.success` — token TBD). These are different teal shades from different token families. Both screens convey "success" but draw from different buckets. Before implementation, align on a single token strategy: either introduce `AppColors.success` covering both screens, or use `AppColors.secondary` consistently and document that secondary = success color family.

### 7.6 Bottom nav tab 2: "חיפוש" in Stitch HTML vs. canonical "סריקה" <!-- DD-4 ARTIFACT -->

The Stitch HTML for this screen renders tab 2 as **"חיפוש"** (Search). Per DD-4, the canonical tab 2 is **"סריקה"** (Scan). This is a known stale Stitch artifact. Follow the DD-2 / DD-4 canonical nav in implementation; do not use "חיפוש".
