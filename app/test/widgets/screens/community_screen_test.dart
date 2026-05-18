import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/community_screen.dart';

void main() {
  group('CommunityScreen Widget Tests', () {
    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CommunityScreen(
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
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
  });
}