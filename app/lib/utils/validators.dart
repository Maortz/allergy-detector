/// Form-field validation helpers, kept out of widgets for testability.
class Validators {
  Validators._();

  /// Matches `local@domain.tld` — requires a non-empty local part, a single
  /// `@`, and a domain with at least one dot before a non-empty TLD.
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns `true` when [value] is a structurally valid email address.
  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());
}
