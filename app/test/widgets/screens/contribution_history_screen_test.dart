import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_contribution.dart';
import 'package:app/screens/contribution_history_screen.dart';
import 'package:app/widgets/contribution_status_pill.dart';

void main() {
  ProductContribution contribution(
          String id, String name, ContributionStatus status) =>
      ProductContribution(
        id: id,
        productName: name,
        brandName: 'מותג $id',
        status: status,
        submittedAt: DateTime(2026, 6, 14, 9),
      );

  Widget host(Widget child) => MaterialApp(home: child);

  testWidgets('renders the populated contribution list', (tester) async {
    await tester.pumpWidget(host(ContributionHistoryScreen(
      loadContributions: () async => [
        contribution('a', 'יוגורט סויה', ContributionStatus.approved),
        contribution('b', 'לחם ללא גלוטן', ContributionStatus.rejected),
      ],
    )));
    await tester.pump();

    expect(find.text('יוגורט סויה'), findsOneWidget);
    expect(find.text('לחם ללא גלוטן'), findsOneWidget);
    expect(find.text('מותג a'), findsOneWidget);
    expect(find.byType(ContributionStatusPill), findsNWidgets(2));
    expect(find.text('אושר'), findsOneWidget);
    expect(find.text('נדחה'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no contributions',
      (tester) async {
    await tester.pumpWidget(host(ContributionHistoryScreen(
      loadContributions: () async => const [],
    )));
    await tester.pump();

    expect(find.text('עדיין לא תרמת לקהילה'), findsOneWidget);
    expect(find.byType(ContributionStatusPill), findsNothing);
  });

  testWidgets('shows an error state with retry on load failure',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(ContributionHistoryScreen(
      loadContributions: () async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return [contribution('a', 'מוצר', ContributionStatus.approved)];
      },
    )));
    await tester.pump();

    expect(find.text('טעינת התרומות נכשלה'), findsOneWidget);

    await tester.tap(find.text('נסה שוב'));
    await tester.pump();
    await tester.pump();

    expect(find.text('מוצר'), findsOneWidget);
    expect(find.text('טעינת התרומות נכשלה'), findsNothing);
  });
}
