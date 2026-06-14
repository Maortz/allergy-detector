import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's appearance preference (Light / Dark / System) locally
/// and maps it to a Flutter [ThemeMode] (issue #168).
///
/// Local-only, mirroring the SharedPreferences pattern used by the rest of the
/// MVP (no Supabase-backed settings). The stored value is one of the canonical
/// strings `"light"` / `"dark"` / `"system"` under [_storageKey]; an absent or
/// unrecognised value falls back to [ThemeMode.system] so the OS preference is
/// respected by default.
class ThemeService {
  static const _storageKey = 'appearance_mode';

  /// Reads the saved appearance preference, defaulting to [ThemeMode.system].
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromStorage(prefs.getString(_storageKey));
  }

  /// Persists [mode] as its canonical storage string.
  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _toStorage(mode));
  }

  static ThemeMode _fromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
