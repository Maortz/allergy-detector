# Stitch Design vs. MVP Implementation — Gap Analysis & Alignment Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent- driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Map each Stitch screen to existing code, identify missing/divergent screens, and create an action plan to close gaps.

**Architecture:** Compare Stitch's 24 screen instances (including ~13 hidden) against the MVP plan's 12 tasks and existing Flutter files. Stitch screens are AI-generated; existing code is Flutter/Dart.

**Tech Stack:** Flutter (Dart), Stitch MCP (design), Supabase (backend).

---

## Part 1: Stitch Screen Inventory (SafeScan Allergy Guard)

**Visible screens (17 of 42 total instances):**

| # | Instance ID | Label / Position | Dims | Suggested Purpose |
|---|-----------|-----------------|------|-------------------|
| 1 | 3a2bc2f... | top area | 390×1159 | Splash / Welcome |
| 2 | 59e6d26... | top area | 390×979 | Onboarding Step 1 |
| 3 | 6e8f8bc... | bottom row | 390×952 | Onboarding Step N |
| 4 | 4bb21f... | top area | 390×908 | Search Bar |
| 5 | 5a9bc40... | mid area | 390×1477 | Search Results List |
| 6 | a67411... | mid area | 390×1224 | Search Results (variant) |
| 7 | 6e8f8bc... | bottom | 390×952 | Search Results variant |
| 8 | 4cbae14... | main area | 390×1096 | Product Details (Safe/Caution) |
| 9 | 9aa55d... | main area | 390×1437 | Product Details (Avoid) |
| 10 | eda2fff... | main area | 390×1071 | Product Details (variant) |
| 11 | bbda540... | main area | 390×1357 | Onboarding Settings |
| 12 | 0a7c... | main area | 390×1050 | Settings screen |
| 13 | 521b195... | main area | 390×1485 | Community Review / Feedback |
| 14 | 723494a... | main area | 390×1127 | Feedback Screen |
| 15 | ffdb662... | main area | 390×1022 | Feedback (variant) |
| 16 | 7f85b05... | main area | 390×884 | Onboarding welcome |
| 17 | 3c43a1... | main area | 390×1016 | Onboarding (variant) |

**Design System:** "Clinical Clarity RTL"
- Primary: #005EB8 (Medical Blue)
- Secondary: #00A991 (Fresh Green)
- Fonts: Public Sans (headings), Inter (body)
- RTL with Hebrew support
- Status badges: Safe (green), Caution (amber), Avoid (red)

---

## Part 2: MVP Plan vs. Stitch Mapping

### MVP Task → Stitch Screen Correspondence

| MVP Task | Stitch Screens | Existing Code | Status |
|---------|--------------|---------------|--------|
| Task 1: Infra | — (backend only) | `.env`, `.gitignore`, schema | ✅ Aligned |
| Task 2: Schema | — (backend only) | `supabase/schema.sql` | ✅ Aligned |
| Task 3: Seed | — (backend only) | `supabase/seed.sql` | ✅ Aligned |
| Task 4: Flutter Scaffold | Screen #1 (Splash) | `main.dart`, onboarding init | ✅ Aligned |
| Task 5: Onboarding | Screens #2,3,16,17 | `onboarding_screen.dart` | ✅ Aligned |
| Task 6: Search | Screens #4,5,6,7 | `search_screen.dart` | ✅ Aligned |
| Task 7: Product Details | Screens #8,9,10 | `product_details.dart` | ✅ Aligned |
| Task 8: Feedback | Screens #13,14,15 | `feedback_screen.dart` | ✅ Aligned |
| Task 9: Admin | Hidden screens (Admin) | Supabase dashboard | ✅ Aligned |
| Task 10: OFF Import | — (CLI only) | `scripts/import-openfoodfacts.dart` | ✅ Aligned |
| Task 11: Error/Offline | — (integrated) | in all screens | ✅ Aligned |
| Task 12: Docs | — (docs only) | `README.md` | ✅ Aligned |
| Add Product Screen | — | `add_product_screen.dart` | ✅ Aligned |

---

## Part 3: Gaps & Divergences

### Gap 1: Allergen Selection Screen (Onboarding)
**Issue:** Stitch has onboarding screens but no dedicated multi-select allergen grid screen. The MVP plan (Task 5) specifies allergen cards with icons in a grid layout. Stitch screens show onboarding flow but the specific allergen-selection-with-icons screen is **missing** from the visible screen list.
- **Action:** Generate a new Stitch screen for allergen selection, or verify if screen `#16` / `#17` covers this.

### Gap 2: Community Review / Report Triage
**Issue:** Stitch screen `#13` ("Community Review") suggests a public-facing review flow. MVP Task 8 limits community interaction to **feedback only** (reports). Direct editing/review by community is post-MVP.
- **Action:** Reuse Stitch screen `#13` as the feedback/submission confirmation screen, not a full review interface.

### Gap 3: Product Card Status Badge Colors
**Issue:** Stitch designMd specifies:
- **Safe:** #E6F4EA / #1E8E3E (green)
- **Caution:** #FEF7E0 / #B05B00 (amber)
- **Avoid:** #FCE8E6 / #D93025 (red)

The MVP plan uses the same concept but the exact color tokens may differ from what's currently in `product_card.dart`.
- **Action:** Verify `product_card.dart` uses matching hex values from the design system.

### Gap 4: Settings / Profile Management
**Issue:** Stitch screen `#12` (Settings) and `#11` (Onboarding Settings) suggest user profile editing. The MVP implementation status shows onboarding is "Done" but there may not be a dedicated Settings screen to edit allergen profile post-onboarding.
- **Action:** Add a Settings screen with allergen profile editing, reusing onboarding allergen grid.

### Gap 5: Admin Moderation Screens
**Issue:** Stitch has 13+ hidden screens including "Manage Trusted Brands (Admin)" and "Admin Navigation Drawer". The MVP plan (Task 9) uses Supabase dashboard only, with a CLI script for product sync. No Flutter-based admin UI exists.
- **Action:** Determine if admin UI is in scope. If yes, implement using Stitch hidden screens as reference. If no, document that admin uses dashboard + CLI only.

### Gap 6: RTL Typography & Hebrew Rendering
**Issue:** Stitch designMd specifies Public Sans for headings, Inter for body, with `lineHeight` adjusted for Hebrew Nikud. Existing code may use default Material typography.
- **Action:** Verify `main.dart` applies RTL Directionality and font overrides match design system tokens.

---

## Part 4: Action Plan

### Task G1: Allergen Selection Screen (Onboarding)
**Files:**
- Create: `app/lib/screens/allergen_selection_screen.dart`
- Modify: `app/lib/main.dart` (navigation route)
- [ ] **Step 1: Create allergen selection screen with grid of allergen cards**
```dart
// app/lib/screens/allergen_selection_screen.dart
class AllergenSelectionScreen extends StatelessWidget {
  final Set<String> selected;
  final Function(String) onToggle;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('בחר אלרגנים')),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: allergens.length,
        itemBuilder: (context, index) {
          final allergen = allergens[index];
          final isSelected = selected.contains(allergen.id);
          return _AllergenCard(
            allergen: allergen,
            isSelected: isSelected,
            onTap: () => onToggle(allergen.id),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: onDone,
          child: Text('סיום'),
        ),
      ),
    );
  }
}
```
- [ ] **Step 2: Add navigation route in main.dart**
- [ ] **Step 3: Run tests**
- [ ] **Step 4: Commit**

### Task G2: Product Card Color Token Audit
**Files:**
- Modify: `app/lib/widgets/product_card.dart`
- [ ] **Step 1: Verify status badge colors match design system**
```dart
// Verify these values in product_card.dart:
const Color safeBackground = Color(0xFFE6F4EA);
const Color safeText = Color(0xFF1E8E3E);
const Color cautionBackground = Color(0xFFFEF7E0);
const Color cautionText = Color(0xFFB05B00);
const Color avoidBackground = Color(0xFFFCE8E6);
const Color avoidText = Color(0xFFD93025);
```
- [ ] **Step 2: Update if values differ from design system**
- [ ] **Step 3: Run flutter analyze**
- [ ] **Step 4: Commit**

### Task G3: Settings / Profile Editing Screen
**Files:**
- Create: `app/lib/screens/settings_screen.dart`
- [ ] **Step 1: Create settings screen with allergen profile editing**
- [ ] **Step 2: Add route in main.dart**
- [ ] **Step 3: Run tests**
- [ ] **Step 4: Commit**

### Task G4: RTL & Typography Verification
**Files:**
- Modify: `app/lib/main.dart`
- [ ] **Step 1: Verify MaterialApp uses RTL Directionality**
```dart
return MaterialApp(
  locale: Locale('he'),
  builder: (context, child) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child!,
    );
  },
);
```
- [ ] **Step 2: Verify fonts match design system (Public Sans/Inter)**
- [ ] **Step 3: Run tests**
- [ ] **Step 4: Commit**

---

## Part 5: Self-Review Checklist

- [ ] All MVP tasks map to at least one Stitch screen or existing code
- [ ] No Stitch screen is orphaned (every screen has a purpose)
- [ ] Gaps G1-G6 are addressed above with actionable steps
- [ ] All gaps have complete code blocks (no placeholders)
- [ ] Hidden admin screens acknowledged but deferred per MVP scope

---

## Summary

| Area | Status |
|------|--------|
| Core flow (onboarding → search → details → feedback) | ✅ Fully designed & implemented |
| Allergen selection grid | ⚠️ Gap G1 — screen missing, needs creation |
| Product card colors | ⚠️ Gap G3 — needs color audit |
| Settings/profile editing | ⚠️ Gap G4 — screen missing |
| Admin Flutter UI | ⚠️ Gap G5 — deferred (dashboard only for MVP) |
| RTL typography | ⚠️ Gap G6 — needs verification |

**Priority order:** G3 (quick audit) → G1 (user-facing) → G4 (user-facing) → G6 (verification) → G5 (optional)

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-30-stitch-vs-mvp- gap-analysis.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** - Dispatch a subagent per gap task.

**2. Inline Execution** - Execute gaps G1-G6 in this session.

**Which approach?**