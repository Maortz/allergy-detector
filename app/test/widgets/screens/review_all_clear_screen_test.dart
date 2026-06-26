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
      ValueChanged<int>? onNavTap,
    }) =>
        MaterialApp(
          home: ReviewAllClearScreen(
            totalPointsEarned: points,
            productsScanned: scanned,
            onReturnHome: onReturnHome,
            onNavTap: onNavTap,
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

    testWidgets(
        'bottom-nav forwards the tapped index to onNavTap (not collapsed to Home)',
        (tester) async {
      int? lastIndex;
      await tester.pumpWidget(buildSubject(onNavTap: (i) => lastIndex = i));

      final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
      navBar.onTap(0);

      expect(lastIndex, 0,
          reason:
              'Spec §7.1: tapping any other tab must route to that tab, not collapse to Home.');
    });

    testWidgets(
        'AC5: secondary line is a disabled TextButton, not a bare Text',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      final button = find.widgetWithText(
        TextButton,
        'תוצאות הסקירה נשמרו בפרופיל שלך',
      );
      expect(button, findsOneWidget,
          reason:
              'Spec §4.5: the ghost-link affordance must render as a TextButton.');
      // Non-navigating per §7.5: no tap handler.
      expect(tester.widget<TextButton>(button).onPressed, isNull);
    });

    testWidgets(
        'AC6/#327: renders a decorative panel, not a raw black image asset',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // The 1×1 placeholder asset rendered as a solid black block (#327); no
      // raw Image must remain in the tree.
      expect(find.byType(Image), findsNothing);
      // An on-theme decorative panel is shown instead.
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    });

    testWidgets('AC2: hero is decorated with sparkle glints', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Four star glints surround the 96 pt hero circle (§4.2).
      expect(find.byIcon(Icons.star), findsNWidgets(4));
    });
  });
}
