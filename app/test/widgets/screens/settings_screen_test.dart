import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/widgets/skeleton_box.dart';
import 'package:app/theme/app_colors.dart';
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

    testWidgets('displays user avatar and name with Hebrew text', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('משתמש'), findsOneWidget);
    });

    // 1x1 transparent PNG, base64-encoded — a valid image for Image.memory.
    const tinyPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
        'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

    testWidgets('renders the saved avatar image on the profile view (#260)', (
      tester,
    ) async {
      testProfile = testProfile.copyWith(avatarData: tinyPngBase64);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // The saved picture is shown, not the default person placeholder.
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets(
      'falls back to the person placeholder when no avatar is set (#260)',
      (tester) async {
        // sampleProfile has no avatarData.
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.person), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to the placeholder for corrupted base64 avatar data (#260)',
      (tester) async {
        // Not valid base64 — base64Decode throws FormatException; the screen
        // must treat it like an absent picture rather than crashing.
        testProfile = testProfile.copyWith(avatarData: 'not-valid-base64!!!');
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(Image), findsNothing);
        expect(find.byIcon(Icons.person), findsOneWidget);
      },
    );

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

    testWidgets(
      'tapping a filter chip propagates the level via onProfileUpdated',
      (tester) async {
        UserProfile? updated;
        await tester.pumpWidget(
          createWidgetUnderTest(onProfileUpdated: (p) => updated = p),
        );

        await tester.ensureVisible(find.text('לא בטוח מכיל אלרגנים'));
        await tester.tap(find.text('לא בטוח מכיל אלרגנים'));
        await tester.pump();

        expect(updated, isNotNull);
        expect(updated!.productFilterLevel, ProductFilterLevel.showAll);
      },
    );

    testWidgets('tapping the already-selected level is a no-op', (
      tester,
    ) async {
      testProfile = testProfile.copyWith(
        productFilterLevel: ProductFilterLevel.safeOnly,
      );
      var calls = 0;
      await tester.pumpWidget(
        createWidgetUnderTest(onProfileUpdated: (_) => calls++),
      );

      await tester.ensureVisible(find.text('בטוח לחלוטין ללא חשש עקבות'));
      await tester.tap(find.text('בטוח לחלוטין ללא חשש עקבות'));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('displays navigation menu items with Hebrew labels', (
      tester,
    ) async {
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

      // One pencil on the avatar overlay + one in the "ערוך פרופיל" button (ST3).
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
    });

    testWidgets('shows the "ערוך פרופיל" edit-profile text button (ST3)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ערוך פרופיל'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    Color? iconBgColorFor(WidgetTester tester, IconData icon) {
      final iconWidget = tester.widget<Icon>(find.byIcon(icon));
      // The icon sits inside a 40x40 Container with a BoxDecoration color.
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.byIcon(icon), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      // Reference iconWidget to assert it resolved (keeps lints happy).
      expect(iconWidget.icon, icon);
      return decoration.color;
    }

    testWidgets('contribution-history row uses the green icon tint (ST9)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        iconBgColorFor(tester, Icons.volunteer_activism),
        AppColors.safeBackground,
      );
    });

    testWidgets('help-center row uses the amber icon tint (ST9)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        iconBgColorFor(tester, Icons.help_center),
        AppColors.cautionBackground,
      );
    });

    testWidgets(
      'menu rows use the RTL-forward chevron_left trailing icon (ST10)',
      (tester) async {
        testProfile = testProfile.copyWith(isAdmin: false);
        await tester.pumpWidget(createWidgetUnderTest());

        // Default (non-admin) profile renders 5 rows, each with a chevron_left.
        expect(find.byIcon(Icons.chevron_left), findsNWidgets(5));
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets('hides the admin "נהל מותגים" row for non-admin users (ST8)', (
      tester,
    ) async {
      testProfile = testProfile.copyWith(isAdmin: false);
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נהל מותגים'), findsNothing);
    });

    testWidgets('shows the admin "נהל מותגים" row for admin users (ST8)', (
      tester,
    ) async {
      testProfile = testProfile.copyWith(isAdmin: true);
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נהל מותגים'), findsOneWidget);
    });

    testWidgets('logout button is a filled light-red FilledButton (ST11)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        find.widgetWithText(FilledButton, 'התנתק מהחשבון'),
        findsOneWidget,
      );
      expect(find.byType(OutlinedButton), findsNothing);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'התנתק מהחשבון'),
      );
      final bg = button.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(bg, AppColors.avoidBackground);
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
      },
    );

    testWidgets(
      'isLoading renders the profile skeleton in place of the avatar',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(isLoading: true));

        expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
        // Real profile block is hidden while loading.
        expect(find.text('משתמש'), findsNothing);
        expect(find.byIcon(Icons.edit), findsNothing);
      },
    );

    testWidgets('appearance section is hidden when no callback is wired', (
      tester,
    ) async {
      // Default: onThemeModeChanged null → no appearance picker (issue #168).
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('מראה'), findsNothing);
    });

    testWidgets('appearance section shows Light / Dark / System when wired', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(onThemeModeChanged: (_) {}),
      );

      expect(find.text('מראה'), findsOneWidget);
      expect(find.text('בהיר'), findsOneWidget);
      expect(find.text('כהה'), findsOneWidget);
      expect(find.text('מערכת'), findsOneWidget);
    });

    testWidgets('tapping an appearance option propagates the ThemeMode', (
      tester,
    ) async {
      ThemeMode? picked;
      await tester.pumpWidget(
        createWidgetUnderTest(
          themeMode: ThemeMode.system,
          onThemeModeChanged: (m) => picked = m,
        ),
      );

      await tester.ensureVisible(find.text('כהה'));
      await tester.tap(find.text('כהה'));
      await tester.pump();

      expect(picked, ThemeMode.dark);
    });

    testWidgets('tapping the already-selected appearance is a no-op', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        createWidgetUnderTest(
          themeMode: ThemeMode.dark,
          onThemeModeChanged: (_) => calls++,
        ),
      );

      await tester.ensureVisible(find.text('כהה'));
      await tester.tap(find.text('כהה'));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets(
        'tapping an option updates the highlight immediately even when the '
        'themeMode prop is not refreshed (#257)', (tester) async {
      // Simulates the pushed-route case: the parent does NOT feed a new
      // themeMode prop back after the callback, yet the selection must move.
      await tester.pumpWidget(createWidgetUnderTest(
        themeMode: ThemeMode.system,
        onThemeModeChanged: (_) {},
      ));

      FontWeight? weightOf(String label) =>
          tester.widget<Text>(find.text(label)).style?.fontWeight;

      // Initially "מערכת" is the selected (bold) option.
      expect(weightOf('מערכת'), FontWeight.w600);
      expect(weightOf('כהה'), FontWeight.w400);

      await tester.ensureVisible(find.text('כהה'));
      await tester.tap(find.text('כהה'));
      await tester.pump();

      // After the tap the highlight moves to "כהה" and clears from "מערכת",
      // without any prop refresh from the parent.
      expect(weightOf('כהה'), FontWeight.w600);
      expect(weightOf('מערכת'), FontWeight.w400);
    });
  });
}
