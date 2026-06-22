import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/screens/app_preferences_screen.dart';
import 'package:app/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PreferencesService.resetForTest);

  Finder switchFor(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(SwitchListTile),
  );

  testWidgets('both notification toggles are disabled (non-interactive)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesScreen()));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(switchFor('התראות על מוצרים חדשים'))
          .onChanged,
      isNull,
    );
    expect(
      tester.widget<SwitchListTile>(switchFor('עדכוני אלרגנים')).onChanged,
      isNull,
    );
  });

  testWidgets('shows a "coming soon" caption for notifications', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('הודעות יהיו זמינות בקרוב'), findsOneWidget);
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
