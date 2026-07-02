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
        'AC6/#344: renders the pure-Flutter Safe Food Lab illustration, not a raw image asset',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // The 1×1 placeholder asset rendered as a solid black block (#327); the
      // real art (#344) ships as a hand-built CustomPaint scene, so no raw
      // Image must remain in the illustration slot. Scope the negative
      // assertion to the illustration panel so an Image added elsewhere in the
      // tree (e.g. nav bar, bento card) can't misfire this regression guard.
      final illustration = find.byKey(const Key('all_clear_illustration'));
      expect(illustration, findsOneWidget);
      expect(
        find.descendant(of: illustration, matching: find.byType(Image)),
        findsNothing,
      );
      // The real "Safe Food Lab" illustration is painted in pure Flutter.
      expect(
        find.descendant(
          of: illustration,
          matching: find.byKey(const Key('safe_food_lab_illustration')),
        ),
        findsOneWidget,
      );
      // Decorative only — excluded from the semantics tree (§4.6).
      expect(
        find.ancestor(
          of: illustration,
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC2: hero is decorated with sparkle glints', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Four star glints surround the 96 pt hero circle (§4.2).
      expect(find.byIcon(Icons.star), findsNWidgets(4));
    });
  });
}
