import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/widgets/skeleton_box.dart';
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
      UserProfile? profile,
      List<RecentActivity>? recentActivity,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            userProfile: profile ?? testProfile,
            allergens: testAllergens,
            onProfileUpdated: onProfileUpdated ?? (_) {},
            onScanTap: onScanTap ?? () {},
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            recentActivity: recentActivity,
            isLoading: isLoading,
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

    group('recent activity respects productFilterLevel (#41)', () {
      // Mock activity items in home_screen.dart:
      //   safe    → 'חלב שולו 5%'
      //   caution → 'לחם מחמצת'
      //   avoid   → 'שוקולד מריר'

      testWidgets('showAll shows every item (no hiding)', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          profile: testProfile.copyWith(
            productFilterLevel: ProductFilterLevel.showAll,
          ),
        ));

        expect(find.text('חלב שולו 5%'), findsOneWidget);
        expect(find.text('לחם מחמצת'), findsOneWidget);
        expect(find.text('שוקולד מריר'), findsOneWidget);
        expect(find.text('אין מוצרים העונים על המסנן'), findsNothing);
      });

      testWidgets('cautionAndAbove hides the avoid item', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          profile: testProfile.copyWith(
            productFilterLevel: ProductFilterLevel.cautionAndAbove,
          ),
        ));

        expect(find.text('חלב שולו 5%'), findsOneWidget);
        expect(find.text('לחם מחמצת'), findsOneWidget);
        expect(find.text('שוקולד מריר'), findsNothing);
      });

      testWidgets('safeOnly hides caution + avoid items', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          profile: testProfile.copyWith(
            productFilterLevel: ProductFilterLevel.safeOnly,
          ),
        ));

        expect(find.text('חלב שולו 5%'), findsOneWidget);
        expect(find.text('לחם מחמצת'), findsNothing);
        expect(find.text('שוקולד מריר'), findsNothing);
      });

      testWidgets('re-renders when the profile updates to a stricter level',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          profile: testProfile.copyWith(
            productFilterLevel: ProductFilterLevel.showAll,
          ),
        ));
        expect(find.text('שוקולד מריר'), findsOneWidget);

        // Parent updates the profile — IndexedStack would rebuild children.
        await tester.pumpWidget(createWidgetUnderTest(
          profile: testProfile.copyWith(
            productFilterLevel: ProductFilterLevel.safeOnly,
          ),
        ));

        expect(find.text('חלב שולו 5%'), findsOneWidget);
        expect(find.text('לחם מחמצת'), findsNothing);
        expect(find.text('שוקולד מריר'), findsNothing);
      });
    });

    group('Tier 2 state variants', () {
      testWidgets('empty recentActivity renders the no-scans empty state',
          (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(recentActivity: const []),
        );

        expect(find.text('טרם סרקת מוצרים'), findsOneWidget);
        expect(find.text('הסריקות שתבצע יופיעו כאן'), findsOneWidget);
        // The mock fallback rows are gone.
        expect(find.text('חלב שולו 5%'), findsNothing);
      });

      testWidgets('isLoading renders shimmer skeletons', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(isLoading: true));

        expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
        // Loading masks both the safety card and the activity rows.
        expect(find.text('הפרופיל שלך פעיל'), findsNothing);
        expect(find.text('חלב שולו 5%'), findsNothing);
      });

      testWidgets(
          'activity present but filtered out renders the filter empty state',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          profile: testProfile.copyWith(
            productFilterLevel: ProductFilterLevel.safeOnly,
          ),
          recentActivity: const [
            RecentActivity(
              name: 'במבה',
              brand: 'אסם',
              time: 'היום',
              status: AllergenStatus.avoid,
            ),
          ],
        ));

        expect(find.text('אין מוצרים העונים על המסנן'), findsOneWidget);
        // Distinct from the no-scans state.
        expect(find.text('טרם סרקת מוצרים'), findsNothing);
      });
    });
  });
}
