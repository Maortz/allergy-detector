import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/onboarding_screen.dart';

void main() {
  testWidgets('App shows onboarding screen elements', (tester) async {
    final testAllergens = [
      const Allergen(id: '1', nameHe: 'בוטנים'),
    ];

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

    expect(find.text('בחר אלרגנים'), findsOneWidget);
    expect(find.text('בוטנים'), findsOneWidget);
  });
}
