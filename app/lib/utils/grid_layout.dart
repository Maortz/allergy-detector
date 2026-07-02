/// Layout helpers for allergen grids (onboarding + manage-allergens).
///
/// Kept out of the widgets so the column math is unit-testable and shared by
/// both screens (issue #335).
library;

/// Target side length (logical px) for a single allergen tile. The available
/// width is divided by this to decide how many columns fit.
const double _kAllergenTileTarget = 150;

/// Number of columns for the allergen grid given the available [width].
///
/// Phones keep the original 3-column layout (clamped lower bound) so existing
/// mobile sizing is unchanged; wider tablet/web viewports gain columns so each
/// card stays a consistent, design-conformant size instead of stretching to
/// fill a third of a wide window (issue #335).
int allergenGridColumns(double width) =>
    (width / _kAllergenTileTarget).floor().clamp(3, 8);
