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

    testWidgets('renders the spec headline + body copy (SU-4, SU-5)',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('המוצר נוסף בהצלחה!'), findsOneWidget);
      expect(
        find.text(
          'המוצר עובר כעת לבדיקת הקהילה. אנו דואגים שכל פריט במאגר '
          'שלנו עומד בתקני הבטיחות המחמירים ביותר.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the success illustration (SU-3)', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders the pending/verification badge pair (SU-6)',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('ממתין לאישור'), findsOneWidget);
      expect(find.text('סטטוס בדיקה'), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    testWidgets('renders brand app-bar + filled CTA + bottom nav (SU-7, SU-8, SU-9)',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('בטוח לאכול'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'חזרה לקהילה'),
        findsOneWidget,
      );
      // `Icons.groups` appears twice: once as the CTA leading icon, once as
      // the active "קהילה" nav destination's selected icon.
      expect(find.byIcon(Icons.groups), findsNWidgets(2));
      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('CTA tap invokes onReturnToCommunity (§5.2)', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(buildSubject(
        onReturnToCommunity: () => tapped++,
      ));

      await tester.tap(find.widgetWithText(FilledButton, 'חזרה לקהילה'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('bottom-nav taps fall back to onReturnToCommunity when onNavTap is null',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(buildSubject(
        onReturnToCommunity: () => tapped++,
      ));

      // Tap the home destination — when onNavTap is null the fallback fires.
      await tester.tap(find.text('בית'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('bottom-nav taps invoke onNavTap with the tapped index when provided',
        (tester) async {
      int? lastIndex;
      await tester.pumpWidget(buildSubject(
        onNavTap: (index) => lastIndex = index,
      ));

      await tester.tap(find.text('בית'));
      await tester.pump();

      expect(lastIndex, 0);
    });
  });
}
