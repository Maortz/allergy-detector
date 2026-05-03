import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late UserProfile testProfile;
    late List<Allergen> testAllergens;

    setUp(() {
      testProfile = TestFixtures.sampleProfile;
      testAllergens = TestFixtures.sampleAllergens;
    });

    Widget createWidgetUnderTest({
      int navIndex = 0,
      VoidCallback? onScanTap,
      ValueChanged<int>? onNavIndexChanged,
      ValueChanged<UserProfile>? onProfileUpdated,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            userProfile: testProfile,
            allergens: testAllergens,
            onProfileUpdated: onProfileUpdated ?? (_) {},
            onScanTap: onScanTap ?? () {},
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('displays greeting based on time of day', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final hour = DateTime.now().hour;
      String expectedGreeting;
      if (hour < 12) {
        expectedGreeting = 'בוקר טוב';
      } else if (hour < 17) {
        expectedGreeting = 'צהריים טובים';
      } else {
        expectedGreeting = 'ערב טוב';
      }

      expect(find.text('$expectedGreeting,'), findsOneWidget);
    });

    testWidgets('displays user name', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('משתמש'), findsOneWidget);
    });

    testWidgets('displays safety status card with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הפרופיל שלך פעיל'), findsOneWidget);
    });

    testWidgets('displays quick scan card with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקה מהירה'), findsOneWidget);
      expect(find.text('בדוק מוצר חדש עכשיו'), findsOneWidget);
    });

    testWidgets('displays recent activity section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('פעילות אחרונה'), findsOneWidget);
    });

    testWidgets('displays statistics section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סטטיסטיקות'), findsOneWidget);
      expect(find.text('סריקות היום'), findsOneWidget);
      expect(find.text('בטוחים'), findsOneWidget);
    });

    

    testWidgets('calls onScanTap when quick scan card is tapped', (tester) async {
      bool scanTapped = false;

      await tester.pumpWidget(createWidgetUnderTest(
        onScanTap: () => scanTapped = true,
      ));

      await tester.tap(find.text('סריקה מהירה'));
      await tester.pump();

      expect(scanTapped, isTrue);
    });

    testWidgets('displays selected allergens in safety status card', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('גלוטן'), findsOneWidget);
      expect(find.text('חלב'), findsOneWidget);
    });
  });
}