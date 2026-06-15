import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/screens/app_preferences_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder switchFor(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      );

  testWidgets('defaults both notification toggles to on when unset',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesScreen()));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(switchFor('התראות על מוצרים חדשים')).value,
      isTrue,
    );
    expect(
      tester.widget<SwitchListTile>(switchFor('עדכוני אלרגנים')).value,
      isTrue,
    );
  });

  testWidgets('restores persisted toggle state from SharedPreferences',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'pref_notify_new_products': false,
      'pref_notify_allergen_updates': true,
    });
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesScreen()));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(switchFor('התראות על מוצרים חדשים')).value,
      isFalse,
    );
    expect(
      tester.widget<SwitchListTile>(switchFor('עדכוני אלרגנים')).value,
      isTrue,
    );
  });

  testWidgets('toggling a notification preference persists the new value',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(switchFor('התראות על מוצרים חדשים'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pref_notify_new_products'), isFalse);
    expect(
      tester.widget<SwitchListTile>(switchFor('התראות על מוצרים חדשים')).value,
      isFalse,
    );
  });

  testWidgets('clear-cache action removes cached search data', (tester) async {
    SharedPreferences.setMockInitialValues({
      'search_cache': '{"x":[]}',
      'search_cache_timestamp': '2026-01-01T00:00:00.000Z',
    });
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('נקה מטמון חיפוש'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('search_cache'), isNull);
    expect(find.text('מטמון החיפוש נוקה'), findsOneWidget);
  });
}
