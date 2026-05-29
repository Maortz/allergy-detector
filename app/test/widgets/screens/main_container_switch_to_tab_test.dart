import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/feedback_success_screen.dart';
import 'package:app/screens/main_container.dart';
import 'package:app/screens/review_all_clear_screen.dart';
import 'package:app/widgets/bottom_nav_bar.dart';

/// Regression coverage for issue #58 — terminal screens (FeedbackSuccess,
/// ReviewAllClear, AddProductSuccess) used to wire every bottom-nav tap to
/// `_goHome()` (index 0), so tapping "קהילה" or "מועדפים" landed on Home.
/// The fix routes their default `onNavTap` through [MainContainer.switchToTab],
/// which pops back to the live [MainContainer] and selects the tapped tab.
void main() {
  group('MainContainer.switchToTab default fallback', () {
    testWidgets('pops a pushed FeedbackSuccessScreen back to the underlying root',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const _RootSentinel(),
        ),
      );

      navKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => FeedbackSuccessScreen(onHome: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackSuccessScreen), findsOneWidget);

      // Default onNavTap delegates to MainContainer.switchToTab — which pops
      // until the first route. Even without a live MainContainer mounted
      // (rootKey.currentState is null), the pop half must still run so the
      // user isn't stranded on the terminal screen.
      final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
      navBar.onTap(2);
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackSuccessScreen), findsNothing);
      expect(find.byType(_RootSentinel), findsOneWidget);
    });

    testWidgets('pops a pushed ReviewAllClearScreen back to the underlying root',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const _RootSentinel(),
        ),
      );

      navKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => const ReviewAllClearScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReviewAllClearScreen), findsOneWidget);

      final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
      navBar.onTap(0);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewAllClearScreen), findsNothing);
      expect(find.byType(_RootSentinel), findsOneWidget);
    });

    testWidgets(
        'no-ops safely when terminal screen is rendered alone (no MainContainer)',
        (tester) async {
      // The terminal screen is the only route — nothing to pop. The helper
      // must not throw or assert.
      await tester.pumpWidget(
        MaterialApp(
          home: FeedbackSuccessScreen(onHome: () {}),
        ),
      );

      final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
      expect(() => navBar.onTap(0), returnsNormally);
      await tester.pump();
      expect(find.byType(FeedbackSuccessScreen), findsOneWidget);
    });
  });
}

class _RootSentinel extends StatelessWidget {
  const _RootSentinel();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('root')));
}
