import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ThemeService', () {
    test('defaults to system when nothing is stored', () async {
      expect(await ThemeService.load(), ThemeMode.system);
    });

    test('defaults to system for an unrecognised stored value', () async {
      SharedPreferences.setMockInitialValues({'appearance_mode': 'sepia'});
      expect(await ThemeService.load(), ThemeMode.system);
    });

    test('round-trips light', () async {
      await ThemeService.save(ThemeMode.light);
      expect(await ThemeService.load(), ThemeMode.light);
    });

    test('round-trips dark', () async {
      await ThemeService.save(ThemeMode.dark);
      expect(await ThemeService.load(), ThemeMode.dark);
    });

    test('round-trips system', () async {
      await ThemeService.save(ThemeMode.dark);
      await ThemeService.save(ThemeMode.system);
      expect(await ThemeService.load(), ThemeMode.system);
    });

    test('persists the canonical storage string', () async {
      await ThemeService.save(ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appearance_mode'), 'dark');
    });
  });
}
