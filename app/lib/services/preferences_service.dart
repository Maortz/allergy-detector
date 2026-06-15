import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preference toggles surfaced by `AppPreferencesScreen`
/// (issue #188, settings-profile §4.3).
///
/// Local-only via SharedPreferences, mirroring the rest of the MVP (no
/// Supabase-backed settings). Each toggle persists immediately on change and is
/// restored on re-entry. Both notification toggles default to `true` so the
/// user is opted in until they explicitly turn a category off.
class PreferencesService {
  static const _newProductsKey = 'pref_notify_new_products';
  static const _allergenUpdatesKey = 'pref_notify_allergen_updates';

  /// Whether "new products" notifications are enabled. Defaults to `true`.
  static Future<bool> newProductsNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_newProductsKey) ?? true;
  }

  /// Persists the "new products" notification toggle.
  static Future<void> setNewProductsNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newProductsKey, value);
  }

  /// Whether "allergen updates" notifications are enabled. Defaults to `true`.
  static Future<bool> allergenUpdateNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_allergenUpdatesKey) ?? true;
  }

  /// Persists the "allergen updates" notification toggle.
  static Future<void> setAllergenUpdateNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allergenUpdatesKey, value);
  }
}
