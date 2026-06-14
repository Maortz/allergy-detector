import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_contribution.dart';
import 'package:app/screens/my_reviews_screen.dart';
import 'package:app/widgets/contribution_status_pill.dart';

void main() {
  MyReview review(String id, String name, ContributionStatus status,
          {String? note}) =>
      MyReview(
        id: id,
        productName: name,
        brandName: 'מותג $id',
        note: note,
        status: status,
        submittedAt: DateTime(2026, 6, 14, 9),
      );

  Widget host(Widget child) => MaterialApp(home: child);

  testWidgets('renders the populated review list', (tester) async {
    await tester.pumpWidget(host(MyReviewsScreen(
      loadReviews: () async => [
        review('a', 'משקה שיבולת שועל', ContributionStatus.approved,
            note: 'המידע מעודכן.'),
        review('b', 'חטיף בוטנים', ContributionStatus.pending),
      ],
    )));
    await tester.pump();

    expect(find.text('משקה שיבולת שועל'), findsOneWidget);
    expect(find.text('חטיף בוטנים'), findsOneWidget);
    expect(find.text('המידע מעודכן.'), findsOneWidget);
    expect(find.byType(ContributionStatusPill), findsNWidgets(2));
    expect(find.text('אושר'), findsOneWidget);
    expect(find.text('ממתין לאישור'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no reviews',
      (tester) async {
    await tester.pumpWidget(host(MyReviewsScreen(
      loadReviews: () async => const [],
    )));
    await tester.pump();

    expect(find.text('עדיין לא כתבת ביקורות'), findsOneWidget);
    expect(find.byType(ContributionStatusPill), findsNothing);
  });

  testWidgets('shows an error state with retry on load failure',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(MyReviewsScreen(
      loadReviews: () async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return [review('a', 'מוצר', ContributionStatus.approved)];
      },
    )));
    await tester.pump();

    expect(find.text('טעינת הביקורות נכשלה'), findsOneWidget);

    await tester.tap(find.text('נסה שוב'));
    await tester.pump();
    await tester.pump();

    expect(find.text('מוצר'), findsOneWidget);
    expect(find.text('טעינת הביקורות נכשלה'), findsNothing);
  });
}
