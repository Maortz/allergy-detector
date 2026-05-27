import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/search_scan_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('SearchScanScreen Widget Tests', () {
    late UserProfile testProfile;
    late List<Allergen> testAllergens;

    setUp(() {
      testProfile = TestFixtures.sampleProfile;
      testAllergens = TestFixtures.sampleAllergens;
    });

    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
      List<RecentScan>? recentScans,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SearchScanScreen(
            userProfile: testProfile,
            allergens: testAllergens,
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            recentScans: recentScans,
          ),
        ),
      );
    }

    testWidgets('displays search input with Hebrew hint', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('חפש מוצר או מרכיב...'), findsOneWidget);
    });

    testWidgets('displays barcode scanning section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקת ברקוד'), findsOneWidget);
      expect(find.text('הצמד את הברקוד למצלמה'), findsOneWidget);
    });

    testWidgets('displays recent scans section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נסרק לארכונה'), findsOneWidget);
      expect(find.text('חלב שולו 5%'), findsOneWidget);
      expect(find.text('שולו'), findsOneWidget);
    });

    testWidgets('hides recent scans section entirely when list is empty (spec §7.4)',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(recentScans: const []));

      // Heading + sample rows must NOT render.
      expect(find.text('נסרק לארכונה'), findsNothing);
      expect(find.text('נסרק לאחרונה'), findsNothing);
      expect(find.text('חלב שולו 5%'), findsNothing);
      expect(find.text('לחם מחמצת'), findsNothing);

      // Surrounding sections still render — the section collapsed cleanly.
      expect(find.text('סריקת ברקוד'), findsOneWidget);
      expect(find.text('טיפ בטיחות'), findsOneWidget);
    });

    testWidgets('displays safety tip section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('טיפ בטיחות'), findsOneWidget);
    });

    testWidgets('search input accepts text input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'חלב');
      await tester.pump();

      expect(find.text('חלב'), findsOneWidget);
    });
  });
}