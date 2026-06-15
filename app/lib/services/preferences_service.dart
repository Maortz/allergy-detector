import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preference toggles surfaced by `AppPreferencesScreen`
/// (issue #188, settings-profile §4.3).
///
/// Local-only via SharedPreferences, mirroring the rest of the MVP (no
/// Supabase-backed settings). Each toggle persists immediately on change and is
/// restored on re-entry. Both notification toggles default to `true` so the
/// user is opted in until they explicitly turn a category off.
///
/// The [SharedPreferences] instance is cached lazily in [_prefs] and reused
/// across every read/write — `getInstance()` is effectively a singleton after
/// the first call, so caching it avoids redundant event-loop round-trips
/// (issue #226).
class PreferencesService {
  static const _newProductsKey = 'pref_notify_new_products';
  static const _allergenUpdatesKey = 'pref_notify_allergen_updates';

  static SharedPreferences? _prefs;

  /// Lazily resolves and caches the shared [SharedPreferences] instance.
  static Future<SharedPreferences> _instance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Whether "new products" notifications are enabled. Defaults to `true`.
  static Future<bool> newProductsNotifications() async {
    final prefs = await _instance();
    return prefs.getBool(_newProductsKey) ?? true;
  }

  /// Persists the "new products" notification toggle.
  static Future<void> setNewProductsNotifications(bool value) async {
    final prefs = await _instance();
    await prefs.setBool(_newProductsKey, value);
  }

  /// Whether "allergen updates" notifications are enabled. Defaults to `true`.
  static Future<bool> allergenUpdateNotifications() async {
    final prefs = await _instance();
    return prefs.getBool(_allergenUpdatesKey) ?? true;
  }

  /// Persists the "allergen updates" notification toggle.
  static Future<void> setAllergenUpdateNotifications(bool value) async {
    final prefs = await _instance();
    await prefs.setBool(_allergenUpdatesKey, value);
  }

  /// Drops the cached instance so a fresh [SharedPreferences] is resolved on
  /// the next call. Test-only: required because `SharedPreferences`
  /// `setMockInitialValues` swaps the backing store between cases, and a stale
  /// cached instance would otherwise keep serving the previous store.
  @visibleForTesting
  static void resetForTest() => _prefs = null;
}
