import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';
import 'package:app/widgets/bottom_nav_bar.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    late UserProfile testProfile;
    late List<Allergen> testAllergens;

    setUp(() {
      testProfile = TestFixtures.sampleProfile;
      testAllergens = TestFixtures.sampleAllergens;
    });

    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
      ValueChanged<UserProfile>? onProfileUpdated,
    }) {
      return MaterialApp(
        home: SettingsScreen(
          userProfile: testProfile,
          allergens: testAllergens,
          onProfileUpdated: onProfileUpdated ?? (_) {},
          currentNavIndex: navIndex,
          onNavIndexChanged: onNavIndexChanged ?? (_) {},
        ),
      );
    }

    testWidgets('displays Hebrew app bar title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('בטוח לאכול'), findsOneWidget);
    });

    testWidgets('displays user avatar and name with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('משתמש'), findsOneWidget);
    });

    testWidgets('displays user email with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('displays scan count with Hebrew label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקות השבוע'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
    });

    testWidgets('displays filter section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הצג רק מוצרים בטוחים'), findsOneWidget);
      expect(find.text('סנן מוצרים לפי האלרגיות שלך'), findsOneWidget);
    });

    testWidgets('displays filter options with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('לא בטוח'), findsOneWidget);
      expect(find.text('מכיל אלרגנים'), findsOneWidget);
      expect(find.text('בטוח חלקית'), findsOneWidget);
      expect(find.text('עשוי להכיל'), findsOneWidget);
      expect(find.text('בטוח לחלוטין'), findsOneWidget);
      expect(find.text('ללא חשש עקבות'), findsOneWidget);
    });

    testWidgets('displays navigation menu items with Hebrew labels', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נהל אלרגיות'), findsOneWidget);
      expect(find.text('העדפות אפליקציה'), findsOneWidget);
      expect(find.text('היסטוריית תרומות'), findsOneWidget);
      expect(find.text('מרכז עזרה'), findsOneWidget);
      expect(find.text('אודות'), findsOneWidget);
    });

    testWidgets('displays logout button with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('התנתק מהחשבון'), findsOneWidget);
    });

    testWidgets('displays bottom navigation bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('displays menu icon in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('displays edit icon on profile avatar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}