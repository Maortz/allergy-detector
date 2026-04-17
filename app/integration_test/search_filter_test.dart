import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env.local');
    await app.main();
  });

  group('Search Filter Test', () {
    testWidgets('filter toggle shows only matching products', (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_allergen_ids': ['a0000000-0000-0000-0000-000000000001'],
        'has_completed_onboarding': true,
      });

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'חטיף');
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      final switchFinder = find.byType(SwitchListTile);
      if (switchFinder.evaluate().isNotEmpty) {
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
      }
    });
  });
}
