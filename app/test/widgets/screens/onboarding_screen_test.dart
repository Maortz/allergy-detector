import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/onboarding_screen.dart';
import 'package:app/screens/onboarding_step_2_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/theme/app_typography.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    late UserProfile testProfile;
    late List<Allergen> testAllergens;

    setUp(() {
      testProfile = const UserProfile(
        selectedAllergenIds: {},
        hasCompletedOnboarding: false,
      );
      testAllergens = TestFixtures.sampleAllergens;
    });

    Widget createWidgetUnderTest({
      UserProfile? profile,
      ValueChanged<UserProfile>? onProfileUpdated,
    }) {
      return MaterialApp(
        home: OnboardingScreen(
          allergens: testAllergens,
          userProfile: profile ?? testProfile,
          onProfileUpdated: onProfileUpdated ?? (_) {},
        ),
      );
    }

    testWidgets('displays welcome message in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ברוכים הבאים ל-SafeBite'), findsOneWidget);
    });

    testWidgets('welcome headline uses titleLg token (22pt SemiBold)', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final headline = tester.widget<Text>(
        find.text('ברוכים הבאים ל-SafeBite'),
      );

      expect(headline.style?.fontSize, AppTypography.titleLg.fontSize);
      expect(headline.style?.fontWeight, AppTypography.titleLg.fontWeight);
    });

    testWidgets('displays description text in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        find.text('בחרו את האלרגנים שאתם רוצים להימנע מהם ואנחנו נוודא שתמיד תדעו מה בטוח לאכול.'),
        findsOneWidget,
      );
    });

    testWidgets('displays step indicator in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('שלב 1 מתוך 2'), findsOneWidget);
    });

    testWidgets('displays allergen selection count in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('בחרו אלרגנים (0 נבחרו)'), findsOneWidget);
    });

    testWidgets('displays allergen grid with Hebrew labels', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('גלוטן'), findsOneWidget);
      expect(find.text('חלב'), findsOneWidget);
    });

    testWidgets('displays continue button in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('המשך'), findsOneWidget);
    });

    testWidgets('displays disclaimer text in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(
        find.text('המידע מבוסס על נתונים גולמיים ואינו מהווה תחליף לייעוץ רפואי מקצועי.'),
        findsOneWidget,
      );
    });

    testWidgets('continue button is disabled when no allergens selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'המשך'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('displays all allergen options', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('continue button is enabled when allergens selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        profile: const UserProfile(
          selectedAllergenIds: {'1'},
          hasCompletedOnboarding: false,
        ),
      ));

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'המשך'),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping continue navigates to OnboardingStep2Screen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        profile: const UserProfile(
          selectedAllergenIds: {'1'},
          hasCompletedOnboarding: false,
        ),
      ));

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingStep2Screen), findsOneWidget);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays shield icon', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });
}