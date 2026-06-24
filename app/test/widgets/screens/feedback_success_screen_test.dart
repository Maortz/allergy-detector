import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/feedback_success_screen.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/widgets/bottom_nav_bar.dart';

void main() {
  group('FeedbackSuccessScreen Widget Tests', () {
    Widget buildSubject({
      VoidCallback? onHome,
      ValueChanged<int>? onNavTap,
      ThemeData? theme,
    }) =>
        MaterialApp(
          theme: theme,
          home: FeedbackSuccessScreen(
            onHome: onHome ?? () {},
            onNavTap: onNavTap,
          ),
        );

    testWidgets('renders the report-sent confirmation copy', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('הדיווח נשלח בהצלחה!'), findsOneWidget);
      expect(
        find.text('המידע נשלח לבדיקה ויעודכן בקרוב. יחד אנחנו שומרים על הקהילה בטוחה.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders the success/community badge pair', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('נבדק ע״י מערכת'), findsOneWidget);
      expect(find.text('קהילה בטוחה'), findsOneWidget);
    });

    testWidgets('has app-bar title, filled home CTA, and bottom nav', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('דיווח נשלח'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'חזרה לדף הבית'), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('does not render the review-next gamification widgets', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('תודה על תרומתך!'), findsNothing);
      expect(find.text('נקודות קהילה'), findsNothing);
      expect(find.text('דירוג שבועי'), findsNothing);
      expect(find.text('בדיקה הבאה מחכה לך!'), findsNothing);
    });

    testWidgets('home CTA invokes onHome', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onHome: () => tapped = true));

      await tester.tap(find.widgetWithText(FilledButton, 'חזרה לדף הבית'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
        'bottom-nav forwards the tapped index to onNavTap (not collapsed to Home)',
        (tester) async {
      int? lastIndex;
      await tester
          .pumpWidget(buildSubject(onNavTap: (i) => lastIndex = i));

      final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
      navBar.onTap(2);

      expect(lastIndex, 2,
          reason:
              'Spec §5.3: tapping any other tab must route to that tab, not collapse to Home.');
    });

    testWidgets('renders under the dark theme without exception (#290)',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(onNavTap: (_) {}, theme: buildDarkAppTheme()),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('הדיווח נשלח בהצלחה!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
