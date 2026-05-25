import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/review_all_clear_screen.dart';
import 'package:app/widgets/bottom_nav_bar.dart';

void main() {
  group('ReviewAllClearScreen Widget Tests', () {
    Widget buildSubject({
      int points = 240,
      int scanned = 12,
      VoidCallback? onReturnHome,
    }) =>
        MaterialApp(
          home: ReviewAllClearScreen(
            totalPointsEarned: points,
            productsScanned: scanned,
            onReturnHome: onReturnHome,
          ),
        );

    testWidgets('renders the celebration hero', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('כל הכבוד!'), findsOneWidget);
      expect(
        find.text('אין מוצרים נוספים להיום. עזרת לקהילה לדעת במה לסמוך בבחירות המזון שלה.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('renders session-total bento stats', (tester) async {
      await tester.pumpWidget(buildSubject(points: 240, scanned: 12));

      expect(find.text('נקודות קהילה'), findsOneWidget);
      expect(find.text('240+'), findsOneWidget);
      expect(find.text('מוצרים שנסרקו'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders home CTA and community bottom nav', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('חזרה לבית'), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('home CTA invokes onReturnHome', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onReturnHome: () => tapped = true));

      await tester.tap(find.text('חזרה לבית'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
