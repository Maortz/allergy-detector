import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/add_product_success_screen.dart';
import 'package:app/widgets/bottom_nav_bar.dart';

void main() {
  group('AddProductSuccessScreen Widget Tests', () {
    Widget buildSubject({
      VoidCallback? onReturnToCommunity,
      ValueChanged<int>? onNavTap,
    }) =>
        MaterialApp(
          home: AddProductSuccessScreen(
            onReturnToCommunity: onReturnToCommunity ?? () {},
            onNavTap: onNavTap,
          ),
        );

    testWidgets('renders headline, body, and success check icon', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('המוצר נוסף בהצלחה!'), findsOneWidget);
      expect(
        find.textContaining('המוצר עובר כעת לבדיקת הקהילה'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders the status badge pair', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('ממתין לאישור'), findsOneWidget);
      expect(find.text('סטטוס בדיקה'), findsOneWidget);
    });

    testWidgets('renders brand app-bar and community bottom nav', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('בטוח לאכול'), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'חזרה לקהילה'), findsOneWidget);
    });

    testWidgets('community CTA invokes onReturnToCommunity', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onReturnToCommunity: () => tapped = true));

      await tester.tap(find.widgetWithText(FilledButton, 'חזרה לקהילה'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
        'bottom-nav forwards the tapped index to onNavTap (not collapsed to Community)',
        (tester) async {
      int? lastIndex;
      await tester.pumpWidget(buildSubject(onNavTap: (i) => lastIndex = i));

      final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
      navBar.onTap(0);

      expect(lastIndex, 0,
          reason:
              'Spec §5.3: tapping the Home tab must route to Home, not collapse to onReturnToCommunity.');
    });
  });
}
