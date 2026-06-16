import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/onboarding_screen.dart';
import 'package:app/screens/onboarding_step_2_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

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
        find.text('בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי'),
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

    testWidgets('displays hero banner image', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(createWidgetUnderTest());

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName,
          'assets/images/onboarding_hero.jpg');
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });
  });

  group('OnboardingScreen V-Art (OB1–OB4)', () {
    final allergens = <Allergen>[
      const Allergen(id: 'peanuts', nameHe: 'בוטנים', nameEn: 'peanuts'),
      const Allergen(id: 'milk', nameHe: 'חלב', nameEn: 'milk'),
      const Allergen(id: 'eggs', nameHe: 'ביצים', nameEn: 'eggs'),
    ];

    Widget buildSubject() {
      return MaterialApp(
        home: OnboardingScreen(
          allergens: allergens,
          userProfile: const UserProfile(),
          onProfileUpdated: (_) {},
        ),
      );
    }

    testWidgets('OB1: renders SafeBite brand header with close icon at correct RTL positions', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      expect(find.text('SafeBite'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      final brandX = tester.getCenter(find.text('SafeBite')).dx;
      final closeX = tester.getCenter(find.byIcon(Icons.close)).dx;
      expect(brandX, lessThan(closeX));
    });

    testWidgets('OB2: renders the hero asset, not the shield placeholder', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/onboarding_hero.jpg');
      expect(image.fit, BoxFit.cover);
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });

    testWidgets('OB3: shows the consent-on-tap disclaimer copy', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      expect(
        find.text('בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי'),
        findsOneWidget,
      );
      expect(find.textContaining('המידע מבוסס על נתונים גולמיים'), findsNothing);
    });

    testWidgets('OB4: continue button is 48pt tall with radius-12 corners', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      final continueText = find.text('המשך');
      expect(continueText, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(of: continueText, matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.height, 48);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final shape = button.style!.shape!.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });
  });
}