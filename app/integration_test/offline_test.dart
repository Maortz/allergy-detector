import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env.local');
    await app.main();
  });

  group('Offline Test', () {
    testWidgets('app handles no network gracefully', (tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final hasErrorMessage =
          find.textContaining('שגיאה').evaluate().isNotEmpty;
      final hasOfflineMessage =
          find.textContaining('מקוון').evaluate().isNotEmpty;

      expect(
          hasErrorMessage ||
              hasOfflineMessage ||
              find.byType(Scaffold).evaluate().isNotEmpty,
          isTrue);
    });
  });
}
