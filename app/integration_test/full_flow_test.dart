import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

import 'package:app/main.dart' as app;
import 'package:app/screens/search_screen.dart';
import 'package:app/screens/product_details.dart';
import 'package:app/screens/feedback_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env.local');
    await app.main();
  });

  group('Full Flow Test', () {
    testWidgets('complete user journey', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      expect(find.text('בחר אלרגנים'), findsOneWidget);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('התחל'));
      await tester.pumpAndSettle();

      expect(find.text('חפש מוצר'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'בוטנים');
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 2));

      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailsScreen), findsOneWidget);

        if (find.text('דווח בעיה').evaluate().isNotEmpty) {
          await tester.tap(find.text('דווח בעיה'));
          await tester.pumpAndSettle();

          expect(find.byType(FeedbackScreen), findsOneWidget);
        }
      }
    });
  });
}
