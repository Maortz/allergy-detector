import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/screens/community_review_screen.dart';

void main() {
  const gluten = Allergen(id: '1', nameHe: 'גלוטן', emoji: '🌾');
  const milk = Allergen(id: '2', nameHe: 'חלב', emoji: '🥛');
  const nuts = Allergen(id: '3', nameHe: 'אגוזים', emoji: '🥜');

  PendingReview review(String id, String name) => PendingReview(
        id: id,
        productId: 'p-$id',
        productName: name,
        brandName: 'EcoNature',
        categoryLabel: 'חלב ומשקאות',
        contributorNote: 'המידע מעודכן.',
        allergenReports: const [
          AllergenReport(allergen: gluten, status: AllergenReportStatus.contains),
          AllergenReport(allergen: nuts, status: AllergenReportStatus.mayContain),
          AllergenReport(allergen: milk, status: AllergenReportStatus.absent),
        ],
      );

  Widget host(Widget child) => MaterialApp(home: child);

  testWidgets('renders product info, category and queue counter', (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'משקה שיבולת שועל'), review('b', 'מוצר שני')],
    )));

    expect(find.text('משקה שיבולת שועל'), findsOneWidget);
    expect(find.text('מותג: EcoNature'), findsOneWidget);
    expect(find.text('חלב ומשקאות'), findsOneWidget);
    expect(find.text('2 נותרו'), findsOneWidget);
  });

  testWidgets('renders the three allergen-report tile states', (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר')],
    )));

    expect(find.text('מכיל בוודאות'), findsOneWidget);
    expect(find.text('עשוי להכיל'), findsOneWidget);
    expect(find.text('לא מכיל'), findsOneWidget);
    expect(find.text('המידע מעודכן.'), findsOneWidget);
  });

  testWidgets('approve calls onApprove and advances to the next item',
      (tester) async {
    PendingReview? approved;
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onApprove: (r) async => approved = r,
    )));

    await tester.ensureVisible(find.text('אישור מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('אישור מוצר'));
    await tester.pump();
    await tester.pump();

    expect(approved?.id, 'a');
    expect(find.text('מוצר שני'), findsOneWidget);
    expect(find.text('1 נותרו'), findsOneWidget);
  });

  testWidgets('reject without a reason shows validation and skips onReject',
      (tester) async {
    var rejectCalls = 0;
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר')],
      onReject: (r, reason) async => rejectCalls++,
    )));

    await tester.ensureVisible(find.text('פסילת מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('פסילת מוצר'));
    await tester.pump();

    expect(rejectCalls, 0);
    expect(find.text('יש להזין סיבת פסילה'), findsOneWidget);
  });

  testWidgets('reject with a reason calls onReject and advances', (tester) async {
    String? reason;
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onReject: (r, value) async => reason = value,
    )));

    await tester.enterText(find.byType(TextField), 'מידע שגוי');
    await tester.ensureVisible(find.text('פסילת מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('פסילת מוצר'));
    await tester.pump();
    await tester.pump();

    expect(reason, 'מידע שגוי');
    expect(find.text('מוצר שני'), findsOneWidget);
  });

  testWidgets('empty queue shows the empty state and return button',
      (tester) async {
    var returned = 0;
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: const [],
      onReturnToCommunity: () => returned++,
    )));

    expect(find.text('אין מוצרים לסקירה כרגע'), findsOneWidget);
    await tester.tap(find.text('חזרה לקהילה'));
    await tester.pump();
    expect(returned, 1);
  });

  testWidgets('history strip lists past contributions with outcome labels',
      (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר')],
      pastContributions: const [
        PastContribution(
          productId: 'x',
          productName: 'יוגורט',
          outcome: ContributionOutcome.approved,
        ),
        PastContribution(
          productId: 'y',
          productName: 'קרקר',
          outcome: ContributionOutcome.pending,
        ),
      ],
    )));

    expect(find.text('תרומות אחרונות שלך'), findsOneWidget);
    expect(find.text('יוגורט'), findsOneWidget);
    expect(find.text('אושר'), findsOneWidget);
    expect(find.text('ממתין'), findsOneWidget);
  });

  testWidgets('detail-bar AppBar title is right-aligned (centerTitle: false)',
      (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר')],
    )));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse,
        reason:
            'Spec §2 / DD-15: detail-bar title must right-align under RTL — set centerTitle: false.');
  });

  testWidgets('each allergen-tile state renders a distinct background color',
      (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר')],
    )));

    Color? bgBehind(String label) {
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      );
      final d = container.decoration;
      return d is BoxDecoration ? d.color : null;
    }

    final containsBg = bgBehind('מכיל בוודאות');
    final mayContainBg = bgBehind('עשוי להכיל');
    final absentBg = bgBehind('לא מכיל');

    expect(containsBg, isNotNull);
    expect(mayContainBg, isNotNull);
    expect(absentBg, isNotNull);
    expect({containsBg, mayContainBg, absentBg}.length, 3,
        reason:
            'Spec §4: contains/mayContain/absent tiles must use distinct tinted backgrounds, not a shared white.');
  });
}
