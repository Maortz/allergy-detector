import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/screens/community_review_screen.dart';
import 'package:app/screens/community_screen.dart';
import 'package:app/widgets/skeleton_box.dart';

void main() {
  group('CommunityScreen Widget Tests', () {
    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
      VoidCallback? onStartReview,
      List<PendingReview>? pendingReviews,
      bool isLoading = false,
      bool hasError = false,
      VoidCallback? onRetry,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CommunityScreen(
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            onStartReview: onStartReview,
            pendingReviews: pendingReviews,
            isLoading: isLoading,
            hasError: hasError,
            onRetry: onRetry,
          ),
        ),
      );
    }

    testWidgets('displays intro section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הכוח שלנו הוא בידע'), findsOneWidget);
      expect(find.text('יחד אנחנו בונים מאגר מזון בטוח לכולם'), findsOneWidget);
    });

    testWidgets('displays stats bento cards with Hebrew labels', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('אומתו בהצלחה'), findsOneWidget);
      expect(find.text('מוצרים נוספו'), findsOneWidget);
    });

    testWidgets('displays add product card with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הוספת מוצר חדש'), findsOneWidget);
    });

    testWidgets('displays peer review section with Hebrew text', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // kDebugMode is true under flutter_test, so the heading reflects the
      // single stub item rather than the release-mode "אין כעת" copy.
      expect(find.text('מוצר אחד ממתין לבדיקה'), findsOneWidget);
      expect(find.text('התחל בבדיקה'), findsOneWidget);
    });

    testWidgets('displays tips section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('טיפ השבוע'), findsOneWidget);
      expect(find.text('בדוק את הרכיבים הפעילים'), findsOneWidget);
    });

    testWidgets('displays active discussion with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('דיון פעיל'), findsOneWidget);
      expect(find.text('האם "סירופ תירס" מכיל גלוטן?'), findsOneWidget);
    });

    testWidgets('"התחל בבדיקה" CTA invokes onStartReview override (#55)', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        createWidgetUnderTest(onStartReview: () => tapped++),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets(
      '"התחל בבדיקה" CTA pushes CommunityReviewScreen by default (#55)',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CommunityReviewScreen), findsNothing);

        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        // Tap → process frame → advance past MaterialPageRoute's ~300ms
        // transition with a *bounded* pump. Avoid pumpAndSettle here: per
        // CLAUDE.md it would trap any future repeating AnimationController
        // added to the pushed screen as a CI timeout.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(CommunityReviewScreen), findsOneWidget);
      },
    );

    testWidgets('empty queue + no override disables "התחל בבדיקה" CTA (#55)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(pendingReviews: const []));

      expect(find.text('אין כעת מוצרים לבדיקה'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'התחל בבדיקה'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'empty queue + override keeps "התחל בבדיקה" CTA enabled (#55)',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(
          createWidgetUnderTest(
            pendingReviews: const [],
            onStartReview: () => tapped++,
          ),
        );

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'),
        );
        expect(button.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.pump();
        expect(tapped, 1);
      },
    );

    testWidgets(
      'rebuild with pendingReviews: null clears a previously non-null queue '
      '(#137)',
      (tester) async {
        const reviews = [
          PendingReview(
            id: 'r1',
            productId: 'p1',
            productName: 'מוצר א',
            brandName: 'מותג א',
            categoryLabel: 'חטיפים',
          ),
          PendingReview(
            id: 'r2',
            productId: 'p2',
            productName: 'מוצר ב',
            brandName: 'מותג ב',
            categoryLabel: 'משקאות',
          ),
        ];

        // A tiny host that lets the test flip the incoming list to null,
        // exercising CommunityScreen.didUpdateWidget (not a fresh mount).
        late StateSetter setOuter;
        List<PendingReview>? incoming = reviews;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return CommunityScreen(
                    currentNavIndex: 0,
                    onNavIndexChanged: (_) {},
                    pendingReviews: incoming,
                  );
                },
              ),
            ),
          ),
        );

        // Two pending items → the plural heading.
        expect(find.text('2 מוצרים ממתינים לבדיקה'), findsOneWidget);
        expect(find.text('אין כעת מוצרים לבדיקה'), findsNothing);

        // Parent resets to null (e.g. logout / data clear).
        setOuter(() => incoming = null);
        await tester.pump();

        // Stale entries must be gone — the empty-state heading shows, the
        // phantom-count heading does not.
        expect(find.text('אין כעת מוצרים לבדיקה'), findsOneWidget);
        expect(find.text('2 מוצרים ממתינים לבדיקה'), findsNothing);
      },
    );

    group('Tier 2 state variants', () {
      testWidgets('isLoading renders placeholder stats + skeleton + disabled CTA',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(isLoading: true));

        // Stats fall back to the "--" placeholder.
        expect(find.text('--'), findsNWidgets(2));
        expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('hasError shows the retry banner and "?" stats',
          (tester) async {
        var retried = 0;
        await tester.pumpWidget(createWidgetUnderTest(
          hasError: true,
          onRetry: () => retried++,
        ));

        expect(
          find.text('לא ניתן לטעון נתונים — בדוק חיבור לאינטרנט.'),
          findsOneWidget,
        );
        expect(find.text('?'), findsNWidgets(2));

        await tester.tap(find.text('נסה שוב'));
        await tester.pump();
        expect(retried, 1);
      });
    });
  });
}
