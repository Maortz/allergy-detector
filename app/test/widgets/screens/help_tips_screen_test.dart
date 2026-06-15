import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/help_tips_screen.dart';

void main() {
  group('HelpTipsScreen', () {
    testWidgets('renders the app-bar title and tip cards', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpTipsScreen()));

      expect(find.text('טיפים לבטיחות'), findsOneWidget);
      // Static tip copy drawn from spec §7.3 — assert key headings render.
      expect(find.text('בדוק תמיד את רשימת הרכיבים המלאה'), findsOneWidget);
      expect(find.text('שים לב לאזהרות "עשוי להכיל"'), findsOneWidget);
      expect(find.text('מוצרי יבוא — בדוק את המקור'), findsOneWidget);
      expect(find.text('נסה לסרוק שוב מדי פעם'), findsOneWidget);
    });

    testWidgets('lays out under RTL directionality', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpTipsScreen()));

      // The screen wraps its Scaffold in an RTL Directionality.
      final dir = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.byType(Scaffold),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(dir.textDirection, TextDirection.rtl);
    });
  });
}
