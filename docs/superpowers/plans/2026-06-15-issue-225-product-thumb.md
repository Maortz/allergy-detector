# Plan: Extract shared ProductThumb widget (issue #225)

Branch `agent/issue-225-product-thumb` already created.

## Goal

Extract the duplicated 48×48 product-thumbnail block from `MyReviewsScreen._ProductThumb`
and the inlined block in `ContributionHistoryScreen._ContributionCard` into a single shared
`ProductThumb` widget at `app/lib/widgets/product_thumb.dart`.

## Key constraint (preserve current visuals exactly)

The two existing thumbs differ only in fallback icon:
- MyReviewsScreen → `Icons.rate_review_outlined`
- ContributionHistoryScreen → `Icons.shopping_basket`

So `ProductThumb` takes a required `fallbackIcon` so each caller keeps its current icon.

## Tasks (TDD)

### T1 — Widget test (red)
Create `app/test/widgets/product_thumb_test.dart`:
- renders the fallback icon when `imageUrl` is null
- renders an `Image` (no fallback icon) when `imageUrl` is non-null
- honors a custom `fallbackIcon`

### T2 — Widget (green)
Create `app/lib/widgets/product_thumb.dart`:
- `ProductThumb` StatelessWidget, `const` constructor
- params: `final String? imageUrl;` `final IconData fallbackIcon;`
- 48×48 Container, `AppColors.surfaceContainerHighest`, radius 8, `Clip.antiAlias`
- `Image.network(..., fit: BoxFit.cover, errorBuilder: ...)` falling back to `Icon(fallbackIcon, color: AppColors.onSurfaceVariant)`; same icon when imageUrl null

### T3 — Replace usages
- `my_reviews_screen.dart`: delete private `_ProductThumb`, import + use
  `ProductThumb(imageUrl: review.imageUrl, fallbackIcon: Icons.rate_review_outlined)`
- `contribution_history_screen.dart`: replace inlined Container block with
  `ProductThumb(imageUrl: contribution.imageUrl, fallbackIcon: Icons.shopping_basket)`

### Verify
- `flutter pub get`
- `flutter analyze lib test` → 0 issues
- `flutter test` → all green

### A6 — Spec index
No screen behavior changes; MyReviewsScreen/ContributionHistoryScreen Code column stays ✓.
Internal refactor only — no column changes needed (note in PR body).

### A7 — drift check
`git fetch origin && git log origin/master..HEAD --oneline`

### A8 — commit + PR (Closes #225)

### A9 — comment on #225, release agent-in-progress
