import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/onboarding_screen.dart';

void main() {
  final testAllergens = [
    const Allergen(id: '1', nameHe: 'בוטנים', nameEn: 'Peanuts'),
    const Allergen(id: '2', nameHe: 'אגוזים', nameEn: 'Tree Nuts'),
    const Allergen(id: '3', nameHe: 'ביצים', nameEn: 'Eggs'),
  ];

  testWidgets('User can select allergens without logging in', (tester) async {
    UserProfile? updatedProfile;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: OnboardingScreen(
        allergens: testAllergens,
        userProfile: const UserProfile(),
        onProfileUpdated: (profile) {
          updatedProfile = profile;
        },
      ),
    ));

    expect(find.text('בחר אלרגנים'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('התחל'));
    await tester.pumpAndSettle();

    expect(updatedProfile, isNotNull);
    expect(updatedProfile!.selectedAllergenIds, contains('1'));
    expect(updatedProfile!.hasCompletedOnboarding, isTrue);
  });

  testWidgets('Start button is disabled when no allergens selected',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: OnboardingScreen(
        allergens: testAllergens,
        userProfile: const UserProfile(),
        onProfileUpdated: (_) {},
      ),
    ));

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'התחל'),
    );
    expect(button.enabled, isFalse);
  });
}
