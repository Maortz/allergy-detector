import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/screens/review_next_screen.dart';
import 'package:app/widgets/bottom_nav_bar.dart';
import 'package:app/widgets/skeleton_box.dart';

void main() {
  const gluten = Allergen(id: '1', nameHe: 'גלוטן');
  const milk = Allergen(id: '2', nameHe: 'חלב');

  PendingReview makeReview() => const PendingReview(
        id: 'r1',
        productId: 'p1',
        productName: 'חלב שקדים אורגני',
        brandName: 'EcoNature',
        categoryLabel: 'משקאות צמחיים',
        contributorNote:
            'מוצר זה ממתין לאימות קהילה בנושא הימצאות עקבות בוטנים ורכיבי חלב.',
        allergenReports: [
          AllergenReport(
            allergen: gluten,
            status: AllergenReportStatus.contains,
          ),
          AllergenReport(
            allergen: milk,
            status: AllergenReportStatus.mayContain,
          ),
        ],
      );

  Widget host(Widget child) => MaterialApp(home: child);

  group('ReviewNextScreen', () {
    // ── RN1: Hero section ──────────────────────────────────────────────────
    testWidgets('RN1: renders "תודה על תרומתך!" heading and body copy',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
      )));

      expect(find.text('תודה על תרומתך!'), findsOneWidget);
      expect(
        find.text(
            'הביקורת שלך עוזרת לאלפי משתמשים לבחור מוצרים בבטחה ובביטחון.'),
        findsOneWidget,
      );
    });

    testWidgets('RN1: hero circle uses check_circle (filled) icon',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
      )));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // ── RN2/RN3: Gamification bento ───────────────────────────────────────
    testWidgets('RN2/RN3: gamification bento shows dynamic points and count',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 30,
        productsReviewed: 3,
        nextItem: makeReview(),
      )));

      expect(find.text('+30'), findsOneWidget);
      expect(find.text('נקודות קהילה'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('מוצרים נסקרו'), findsOneWidget);
    });

    // ── RN4: Section header row ────────────────────────────────────────────
    testWidgets('RN4: section header "המוצר הבא לבדיקה" visible when nextItem set',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
      )));

      expect(find.text('המוצר הבא לבדיקה'), findsOneWidget);
    });

    testWidgets('RN4: "דלג" skip link calls onSkip', (tester) async {
      var skipped = 0;
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
        onSkip: () => skipped++,
      )));

      await tester.tap(find.text('דלג'));
      await tester.pump();

      expect(skipped, 1);
    });

    // ── RN7: Product meta ──────────────────────────────────────────────────
    testWidgets('RN7: product name and category label render', (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
      )));

      expect(find.text('חלב שקדים אורגני'), findsOneWidget);
      // Category is uppercased by the screen
      expect(find.textContaining('משקאות'), findsAtLeastNWidgets(1));
    });

    // ── RN8: Action row ────────────────────────────────────────────────────
    testWidgets('RN8: "בדוק עכשיו" button calls onCheckNow', (tester) async {
      var checked = 0;
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
        onCheckNow: () => checked++,
      )));

      // Scroll to ensure the button is visible
      await tester.ensureVisible(find.text('בדוק עכשיו'));
      await tester.tap(find.text('בדוק עכשיו'));
      await tester.pump();

      expect(checked, 1);
    });

    testWidgets('RN8: favourite icon button toggles between outlined and filled',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
      )));

      // Initially unfavourited
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      // After tap: favourited
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    // ── RN9: Ghost home button ─────────────────────────────────────────────
    testWidgets('RN9: "חזרה לדף הבית" button calls onGoHome', (tester) async {
      var wentHome = 0;
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
        onGoHome: () => wentHome++,
      )));

      await tester.ensureVisible(find.text('חזרה לדף הבית'));
      await tester.tap(find.text('חזרה לדף הבית'));
      await tester.pump();

      expect(wentHome, 1);
    });

    testWidgets('RN9: home button has a home icon', (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        onGoHome: () {},
      )));

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    // ── RN10: No bottom nav ────────────────────────────────────────────────
    testWidgets('RN10: BottomNavBar is NOT rendered (pushed route — nav suppressed)',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
      )));

      expect(
        find.byType(BottomNavBar),
        findsNothing,
        reason:
            'Spec RN10/§7.1: bottom nav must be suppressed on this pushed route.',
      );
    });

    // ── RN12: Loading skeleton ─────────────────────────────────────────────
    testWidgets('RN12: isLoading renders skeleton cards, hides real product card',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
        isLoading: true,
      )));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
      // Product name should not appear when loading
      expect(find.text('חלב שקדים אורגני'), findsNothing);
    });

    testWidgets('RN12: "בדוק עכשיו" is disabled while loading', (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        nextItem: makeReview(),
        isLoading: true,
      )));

      final checkNow = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'בדוק עכשיו'),
      );
      expect(checkNow.onPressed, isNull,
          reason: 'Buttons must be disabled while loading the next item');
    });

    // ── §5.7: Queue exhausted (nextItem == null) ───────────────────────────
    testWidgets(
        '§5.7: nextItem null hides product section and shows empty-queue message',
        (tester) async {
      await tester.pumpWidget(host(ReviewNextScreen(
        pointsEarned: 10,
        productsReviewed: 1,
        // nextItem: null — queue exhausted
      )));

      expect(find.text('המוצר הבא לבדיקה'), findsNothing,
          reason: 'Section header must be hidden when queue is exhausted');
      expect(
        find.text('אין מוצרים נוספים לסקירה כרגע'),
        findsOneWidget,
        reason: 'Empty-queue message must appear when nextItem is null',
      );
    });
  });
}
