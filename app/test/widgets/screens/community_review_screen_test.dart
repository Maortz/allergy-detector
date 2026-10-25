import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/screens/community_review_screen.dart';
import 'package:app/theme/app_theme.dart';

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

  Widget host(Widget child, {ThemeData? theme}) =>
      MaterialApp(theme: theme, home: child);

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

  testWidgets('approve failure unlocks the screen and keeps the same item',
      (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onApprove: (_) async => throw Exception('boom'),
    )));

    await tester.ensureVisible(find.text('אישור מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('אישור מוצר'));
    await tester.pump();
    await tester.pump();

    // Still on the same item — no silent advance, no permanent spinner.
    expect(find.text('מוצר ראשון'), findsOneWidget);
    expect(find.text('מוצר שני'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('שגיאה באישור המוצר. נסה שוב.'), findsOneWidget);
  });

  testWidgets('reject failure unlocks the screen and keeps the same item',
      (tester) async {
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onReject: (_, _) async => throw Exception('boom'),
    )));

    await tester.enterText(find.byType(TextField), 'נסה');
    await tester.ensureVisible(find.text('פסילת מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('פסילת מוצר'));
    await tester.pump();
    await tester.pump();

    expect(find.text('מוצר ראשון'), findsOneWidget);
    expect(find.text('מוצר שני'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('שגיאה בפסילת המוצר. נסה שוב.'), findsOneWidget);
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

  testWidgets(
      'while approve is in-flight: spinner on the tapped button, both buttons '
      'disabled, no body-level spinner', (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onApprove: (_) => gate.future,
    )));

    await tester.ensureVisible(find.text('אישור מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('אישור מוצר'));
    await tester.pump(); // start the future; enter in-flight state

    // Per-button loading: exactly one spinner, inside the decision panel —
    // the body content (product name) stays on screen (no full-body spinner).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('מוצר ראשון'), findsOneWidget);

    // Both decision buttons are disabled while in-flight (no double-submit).
    final approve = tester.widget<FilledButton>(find.byType(FilledButton).first);
    final reject = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(approve.onPressed, isNull);
    expect(reject.onPressed, isNull);

    // A second tap must not re-enter or queue another submit.
    await tester.tap(find.text('אישור מוצר'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Resolve and advance.
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('מוצר שני'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reject in-flight disables approve and shows spinner on reject',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onReject: (_, _) => gate.future,
    )));

    await tester.enterText(find.byType(TextField), 'מידע שגוי');
    await tester.ensureVisible(find.text('פסילת מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('פסילת מוצר'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final approve = tester.widget<FilledButton>(find.byType(FilledButton).first);
    final reject = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(approve.onPressed, isNull);
    expect(reject.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('מוצר שני'), findsOneWidget);
  });

  testWidgets(
      'onQueueExhausted fires after the last item is reviewed (AC6b)',
      (tester) async {
    var exhausted = 0;
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר יחיד')],
      onApprove: (_) async {},
      onQueueExhausted: () => exhausted++,
    )));

    expect(exhausted, 0, reason: 'queue still has an item on mount');

    await tester.ensureVisible(find.text('אישור מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('אישור מוצר'));
    await tester.pump();
    await tester.pump();

    expect(exhausted, 1,
        reason: 'reviewing the last item drains the queue → exhaustion fires');
  });

  testWidgets(
      'onQueueExhausted does NOT fire while items remain (AC6b)',
      (tester) async {
    var exhausted = 0;
    await tester.pumpWidget(host(CommunityReviewScreen(
      queue: [review('a', 'מוצר ראשון'), review('b', 'מוצר שני')],
      onApprove: (_) async {},
      onQueueExhausted: () => exhausted++,
    )));

    await tester.ensureVisible(find.text('אישור מוצר'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('אישור מוצר'));
    await tester.pump();
    await tester.pump();

    expect(find.text('מוצר שני'), findsOneWidget);
    expect(exhausted, 0,
        reason: 'one item still remains → no exhaustion handoff yet');
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

  testWidgets('renders under the dark theme without exception (#291)',
      (tester) async {
    await tester.pumpWidget(host(
      CommunityReviewScreen(queue: [review('a', 'מוצר')]),
      theme: buildDarkAppTheme(),
    ));

    expect(tester.takeException(), isNull);
    // Core review content still renders under dark mode.
    expect(find.text('מוצר'), findsOneWidget);
    expect(find.text('מכיל בוודאות'), findsOneWidget);
  });

  group('responsive bento layout (CR4, #392)', () {
    void setSurface(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    const productName = 'משקה שיבולת שועל';
    const allergenHeader = 'מידע על אלרגנים שהוזן:';
    const decisionHeader = 'החלטה למוצר זה:';

    testWidgets('wide viewport: allergen + decision column on the right, '
        'product card on the left', (tester) async {
      setSurface(tester, const Size(1024, 1366));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));

      final mid = tester.view.physicalSize.width / 2;
      final product = tester.getCenter(find.text(productName));
      final allergen = tester.getCenter(find.text(allergenHeader));
      final decision = tester.getCenter(find.text(decisionHeader));

      // RTL: allergen card + decision panel occupy the right column,
      // product card the left column.
      expect(product.dx, lessThan(mid));
      expect(allergen.dx, greaterThan(mid));
      expect(decision.dx, greaterThan(mid));
      // Side-by-side: the allergen header sits in the same vertical band as
      // the product card, above the product name (which is under the 1:1
      // image), not stacked below it.
      expect(allergen.dy, lessThan(product.dy));
      // Right column stacks: decision panel below the allergen card.
      expect(decision.dy, greaterThan(allergen.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow viewport keeps the single-column order',
        (tester) async {
      setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));

      final product = tester.getTopLeft(find.text(productName));
      final allergen = tester.getTopLeft(find.text(allergenHeader));
      final decision = tester.getTopLeft(find.text(decisionHeader));

      // Stacked in source order: product → allergen card → decision panel.
      expect(allergen.dy, greaterThan(product.dy));
      expect(decision.dy, greaterThan(allergen.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('boundary: 600 is two-column, 599 is stacked', (tester) async {
      setSurface(tester, const Size(600, 1200));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));
      expect(
        tester.getCenter(find.text(allergenHeader)).dy,
        lessThan(tester.getCenter(find.text(productName)).dy),
        reason: '600 dp is the two-column threshold (≥ 600)',
      );

      setSurface(tester, const Size(599, 1200));
      await tester.pump();
      expect(
        tester.getCenter(find.text(allergenHeader)).dy,
        greaterThan(tester.getCenter(find.text(productName)).dy),
        reason: '599 dp stays single-column (< 600)',
      );
    });

    testWidgets('rejection reason survives a narrow→wide resize',
        (tester) async {
      setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));
      await tester.enterText(find.byType(TextField), 'מידע שגוי');

      setSurface(tester, const Size(1024, 1366));
      await tester.pump();

      expect(find.text('מידע שגוי'), findsOneWidget);
      expect(
        tester.getCenter(find.text(allergenHeader)).dy,
        lessThan(tester.getCenter(find.text(productName)).dy),
      );
    });

    testWidgets('very wide web viewport renders without exception',
        (tester) async {
      setSurface(tester, const Size(1920, 1080));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text(decisionHeader), findsOneWidget);
    });

    testWidgets('wide layout renders under the dark theme without exception',
        (tester) async {
      setSurface(tester, const Size(1024, 1366));
      await tester.pumpWidget(host(
        CommunityReviewScreen(queue: [review('a', productName)]),
        theme: buildDarkAppTheme(),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('מכיל בוודאות'), findsOneWidget);
    });
  });
}
