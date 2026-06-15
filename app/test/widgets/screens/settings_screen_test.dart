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
      ThemeMode themeMode = ThemeMode.system,
      ValueChanged<ThemeMode>? onThemeModeChanged,
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
            themeMode: themeMode,
            onThemeModeChanged: onThemeModeChanged,
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

    testWidgets('no longer renders the mock scan-count widget', (tester) async {
      // The hardcoded "24" / "סריקות השבוע" stat was removed in #135 (no real
      // backing data). Guard that it stays gone.
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקות השבוע'), findsNothing);
      expect(find.text('24'), findsNothing);
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

    testWidgets(
        'provides its own Scaffold so it survives a bare MaterialPageRoute push',
        (tester) async {
      // Regression for #177: SettingsScreen is pushed via a plain
      // MaterialPageRoute from the user drawer with NO surrounding Scaffold.
      // It must therefore supply its own Scaffold (Material ancestor for the
      // InkWell nav tiles + OutlinedButton logout, host for the edit sheet /
      // logout dialog). Note: deliberately NO Scaffold wrapper here.
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            userProfile: testProfile,
            allergens: testAllergens,
            onProfileUpdated: (_) {},
            currentNavIndex: 0,
            onNavIndexChanged: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsOneWidget);
      // Sanity: the Material-dependent controls still render.
      expect(find.text('התנתק מהחשבון'), findsOneWidget);
      expect(find.text('נהל אלרגיות'), findsOneWidget);
    });

    testWidgets('isLoading renders the profile skeleton in place of the avatar',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoading: true));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
      // Real profile block is hidden while loading.
      expect(find.text('משתמש'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('appearance section is hidden when no callback is wired',
        (tester) async {
      // Default: onThemeModeChanged null → no appearance picker (issue #168).
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('מראה'), findsNothing);
    });

    testWidgets('appearance section shows Light / Dark / System when wired',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        onThemeModeChanged: (_) {},
      ));

      expect(find.text('מראה'), findsOneWidget);
      expect(find.text('בהיר'), findsOneWidget);
      expect(find.text('כהה'), findsOneWidget);
      expect(find.text('מערכת'), findsOneWidget);
    });

    testWidgets('tapping an appearance option propagates the ThemeMode',
        (tester) async {
      ThemeMode? picked;
      await tester.pumpWidget(createWidgetUnderTest(
        themeMode: ThemeMode.system,
        onThemeModeChanged: (m) => picked = m,
      ));

      await tester.ensureVisible(find.text('כהה'));
      await tester.tap(find.text('כהה'));
      await tester.pump();

      expect(picked, ThemeMode.dark);
    });

    testWidgets('tapping the already-selected appearance is a no-op',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(createWidgetUnderTest(
        themeMode: ThemeMode.dark,
        onThemeModeChanged: (_) => calls++,
      ));

      await tester.ensureVisible(find.text('כהה'));
      await tester.tap(find.text('כהה'));
      await tester.pump();

      expect(calls, 0);
    });
  });
}