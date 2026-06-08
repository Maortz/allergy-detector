import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/widgets/skeleton_box.dart';
import '../../helpers/test_fixtures.dart';

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
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            userProfile: testProfile,
            allergens: testAllergens,
            onProfileUpdated: onProfileUpdated ?? (_) {},
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            isLoading: isLoading,
          ),
        ),
      );
    }

    testWidgets('displays user avatar and name with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('משתמש'), findsOneWidget);
    });

    testWidgets('displays user email with Hebrew text', (tester) async {
      testProfile = testProfile.copyWith(email: 'user@example.com');
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

      expect(find.text('רמת סינון מוצרים'), findsOneWidget);
      expect(find.text('סנן מוצרים לפי האלרגיות שלך'), findsOneWidget);
    });

    testWidgets('displays the three filter-level chips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('לא בטוח מכיל אלרגנים'), findsOneWidget);
      expect(find.text('בטוח חלקית עשוי להכיל'), findsOneWidget);
      expect(find.text('בטוח לחלוטין ללא חשש עקבות'), findsOneWidget);
    });

    testWidgets('tapping a filter chip propagates the level via onProfileUpdated', (tester) async {
      UserProfile? updated;
      await tester.pumpWidget(createWidgetUnderTest(
        onProfileUpdated: (p) => updated = p,
      ));

      await tester.ensureVisible(find.text('לא בטוח מכיל אלרגנים'));
      await tester.tap(find.text('לא בטוח מכיל אלרגנים'));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.productFilterLevel, ProductFilterLevel.showAll);
    });

    testWidgets('tapping the already-selected level is a no-op', (tester) async {
      testProfile = testProfile.copyWith(
        productFilterLevel: ProductFilterLevel.safeOnly,
      );
      var calls = 0;
      await tester.pumpWidget(createWidgetUnderTest(
        onProfileUpdated: (_) => calls++,
      ));

      await tester.ensureVisible(find.text('בטוח לחלוטין ללא חשש עקבות'));
      await tester.tap(find.text('בטוח לחלוטין ללא חשש עקבות'));
      await tester.pump();

      expect(calls, 0);
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

    testWidgets('displays edit icon on profile avatar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('isLoading renders the profile skeleton in place of the avatar',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoading: true));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
      // Real profile block is hidden while loading.
      expect(find.text('משתמש'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });
}