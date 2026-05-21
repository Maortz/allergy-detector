import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/onboarding_step_2_screen.dart';
import 'package:app/models/user_profile.dart';

void main() {
  Widget buildSubject({
    UserProfile? profile,
    ValueChanged<UserProfile>? onUpdated,
  }) {
    return MaterialApp(
      home: OnboardingStep2Screen(
        userProfile: profile ?? const UserProfile(selectedAllergenIds: {'1'}),
        onProfileUpdated: onUpdated ?? (_) {},
      ),
    );
  }

  testWidgets('shows headline', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('כמעט סיימנו!'), findsOneWidget);
  });

  testWidgets('finish button is disabled when name is empty', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    final btn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'סיים'),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('finish button is enabled after typing a name', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextField).first, 'ישראל ישראלי');
    await tester.pump();
    final btn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'סיים'),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('tapping finish emits profile with hasCompletedOnboarding true', (tester) async {
    UserProfile? emitted;
    await tester.pumpWidget(buildSubject(onUpdated: (p) => emitted = p));
    await tester.enterText(find.byType(TextField).first, 'ישראל ישראלי');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיים'));
    await tester.pump();
    expect(emitted, isNotNull);
    expect(emitted!.hasCompletedOnboarding, isTrue);
    expect(emitted!.displayName, 'ישראל ישראלי');
  });

  testWidgets('shows notification button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('אפשר התראות'), findsOneWidget);
  });

  testWidgets('shows step counter', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('שלב 2 מתוך 2'), findsOneWidget);
  });
}
