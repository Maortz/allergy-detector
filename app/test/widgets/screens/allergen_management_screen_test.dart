import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/allergen_management_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/widgets/state_view.dart';

void main() {
  final allergens = [
    const Allergen(id: '1', nameHe: 'חלב'),
    const Allergen(id: '2', nameHe: 'ביצים'),
    const Allergen(id: '3', nameHe: 'גלוטן'),
  ];

  Widget buildSubject({
    List<Allergen>? catalog,
    UserProfile? profile,
    ValueChanged<UserProfile>? onUpdated,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AllergenManagementScreen(
          allergens: catalog ?? allergens,
          userProfile: profile ?? const UserProfile(),
          onProfileUpdated: onUpdated ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('shows app bar title', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('נהל אלרגיות'), findsOneWidget);
  });

  testWidgets('shows correct initial counter', (tester) async {
    const profile = UserProfile(selectedAllergenIds: {'1', '2'});
    await tester.pumpWidget(buildSubject(profile: profile));
    expect(find.text('אלרגנים פעילים: 2'), findsOneWidget);
  });

  testWidgets('shows zero counter when no allergens selected', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('אלרגנים פעילים: 0'), findsOneWidget);
  });

  testWidgets('renders allergen cards for all allergens', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('חלב'), findsOneWidget);
    expect(find.text('ביצים'), findsOneWidget);
    expect(find.text('גלוטן'), findsOneWidget);
  });

  testWidgets('tapping a card calls onProfileUpdated immediately', (tester) async {
    UserProfile? updated;
    await tester.pumpWidget(buildSubject(onUpdated: (p) => updated = p));
    await tester.tap(find.text('חלב'));
    await tester.pump();
    expect(updated, isNotNull);
    expect(updated!.selectedAllergenIds.contains('1'), isTrue);
  });

  testWidgets('shows disclaimer footer', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('השינויים נשמרים אוטומטית'), findsOneWidget);
  });

  testWidgets('shows an error/empty state when the catalog is empty (#256)',
      (tester) async {
    await tester.pumpWidget(buildSubject(catalog: const []));

    expect(find.byType(StateView), findsOneWidget);
    expect(find.text('לא ניתן לטעון את רשימת האלרגנים'), findsOneWidget);
    // The blank-grid scaffolding (counter / footer) is not shown in this state.
    expect(find.text('אלרגנים פעילים: 0'), findsNothing);
    expect(find.text('השינויים נשמרים אוטומטית'), findsNothing);
  });
}
