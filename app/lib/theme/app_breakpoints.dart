/// Shared responsive breakpoints for the Community flow (#324, #392, #410).
///
/// The breakpoint value belongs to the wider bucket (Material 3 convention):
/// a width of exactly [twoColumn] renders the two-column layout.
///
/// Callers must pass the full body width (e.g. the `LayoutBuilder` constraints
/// of the scaffold body), not the padded content width, so every screen flips
/// at the same viewport width.
class AppBreakpoints {
  AppBreakpoints._();

  /// Minimum width (logical px) at which two-column layouts are used.
  static const double twoColumn = 600;

  /// Whether [width] (full body width) should use the two-column layout.
  static bool isTwoColumn(double width) => width >= twoColumn;
}
