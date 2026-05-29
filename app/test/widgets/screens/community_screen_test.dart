import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/community_review_screen.dart';
import 'package:app/screens/community_screen.dart';

void main() {
  group('CommunityScreen Widget Tests', () {
    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
      VoidCallback? onStartReview,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CommunityScreen(
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            onStartReview: onStartReview,
          ),
        ),
      );
    }

    testWidgets('displays intro section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הכוח שלנו הוא בידע'), findsOneWidget);
      expect(find.text('יחד אנחנו בונים מאגר מזון בטוח לכולם'), findsOneWidget);
    });

    testWidgets('displays stats bento cards with Hebrew labels', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('אומתו בהצלחה'), findsOneWidget);
      expect(find.text('מוצרים נוספו'), findsOneWidget);
    });

    testWidgets('displays add product card with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הוספת מוצר חדש'), findsOneWidget);
    });

    testWidgets('displays peer review section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('12 מוצרים ממתינים לבדיקה'), findsOneWidget);
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

    testWidgets('"התחל בבדיקה" CTA invokes onStartReview override (#55)',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        createWidgetUnderTest(onStartReview: () => tapped++),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('"התחל בבדיקה" CTA pushes CommunityReviewScreen by default (#55)',
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
    });
  });
}