import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/onboarding_screen.dart';

void main() {
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

  // Use a realistic tall phone surface so the fixed-height header, hero banner,
  // disclaimer and continue button all fit without overflowing the default
  // 800x600 test viewport. Resets after each test.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('OnboardingScreen V-Art (OB1–OB4)', () {
    testWidgets('OB1: renders the SafeBite brand header with a close icon',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      expect(find.text('SafeBite'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Spec §4.1: SafeBite sits at RTL-trailing (visual left), the ✕ at
      // RTL-leading (visual right). Guards against the Row children being
      // ordered for LTR by mistake.
      final brandX = tester.getCenter(find.text('SafeBite')).dx;
      final closeX = tester.getCenter(find.byIcon(Icons.close)).dx;
      expect(brandX, lessThan(closeX));
    });

    testWidgets('OB2: renders the hero asset, not the shield placeholder',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/onboarding_hero.jpg');
      expect(image.fit, BoxFit.cover);
      // The placeholder icon must no longer be in the live tree.
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });

    testWidgets('OB3: shows the consent-on-tap disclaimer copy',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      expect(
        find.text(
          'בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('המידע מבוסס על נתונים גולמיים'),
        findsNothing,
      );
    });

    testWidgets('OB4: continue button is 48pt tall with radius-12 corners',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());

      // The button text confirms we target the right SizedBox.
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
