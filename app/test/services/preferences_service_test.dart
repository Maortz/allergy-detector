import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PreferencesService.resetForTest);

  group('PreferencesService', () {
    test('defaults both notification toggles to true when unset', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await PreferencesService.newProductsNotifications(), isTrue);
      expect(await PreferencesService.allergenUpdateNotifications(), isTrue);
    });

    test('restores persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'pref_notify_new_products': false,
        'pref_notify_allergen_updates': true,
      });

      expect(await PreferencesService.newProductsNotifications(), isFalse);
      expect(await PreferencesService.allergenUpdateNotifications(), isTrue);
    });

    test('persists a toggle and reads it back through the cached instance',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.setNewProductsNotifications(false);
      await PreferencesService.setAllergenUpdateNotifications(false);

      // Same cached instance must reflect the writes within a test.
      expect(await PreferencesService.newProductsNotifications(), isFalse);
      expect(await PreferencesService.allergenUpdateNotifications(), isFalse);
    });

    test('resetForTest drops the cached instance so a new mock store is read',
        () async {
      SharedPreferences.setMockInitialValues({
        'pref_notify_new_products': false,
      });
      // Prime the cache against the first store.
      expect(await PreferencesService.newProductsNotifications(), isFalse);

      // Swap in a different backing store and reset the cache.
      SharedPreferences.setMockInitialValues({
        'pref_notify_new_products': true,
      });
      PreferencesService.resetForTest();

      expect(await PreferencesService.newProductsNotifications(), isTrue);
    });
  });
}
