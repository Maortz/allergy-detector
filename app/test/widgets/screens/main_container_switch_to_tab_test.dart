import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_profile.dart';
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

    testWidgets(
        'happy path: live MainContainer + pushed terminal — tapping tab 2 lands on tab 2',
        (tester) async {
      // Pump a real MainContainer as the home route so rootKey resolves to a
      // live state. None of MainContainer's children touch Supabase at mount
      // time (verified per direct grep) — SearchScanScreen's ScannerService
      // is constructed lazily and the scanner controller is never started in
      // tests.
      await tester.pumpWidget(
        MaterialApp(
          home: MainContainer(
            key: MainContainer.rootKey,
            userProfile: const UserProfile(hasCompletedOnboarding: true),
            allergens: const [],
            onProfileUpdated: (_) {},
          ),
        ),
      );
      // First frame is enough — pumpAndSettle would loop on
      // SearchScanScreen's repeating laser AnimationController (CLAUDE.md
      // operational note).
      await tester.pump();

      expect(MainContainer.rootKey.currentState, isNotNull);
      expect(MainContainer.rootKey.currentState!.currentIndex, 0);

      // Push the terminal screen above MainContainer via the live navigator.
      // Use Duration.zero on transitions so the laser animation doesn't gate
      // our pumps (we can't pumpAndSettle here — see comment above).
      Navigator.of(MainContainer.rootKey.currentContext!).push(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => FeedbackSuccessScreen(onHome: () {}),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(FeedbackSuccessScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FeedbackSuccessScreen),
          matching: find.byType(BottomNavBar),
        ),
        findsOneWidget,
      );

      // Two BottomNavBars are now in the tree (MainContainer's + the
      // pushed terminal screen's). Tap on the one inside FeedbackSuccessScreen.
      final terminalNavBar = tester.widget<BottomNavBar>(
        find.descendant(
          of: find.byType(FeedbackSuccessScreen),
          matching: find.byType(BottomNavBar),
        ),
      );
      terminalNavBar.onTap(2);
      await tester.pump();
      await tester.pump();

      expect(find.byType(FeedbackSuccessScreen), findsNothing,
          reason: 'pop half of switchToTab should dismiss the terminal route');
      expect(MainContainer.rootKey.currentState!.currentIndex, 2,
          reason:
              'setActiveTab half of switchToTab should land on the tapped tab');
    });
  });
}

class _RootSentinel extends StatelessWidget {
  const _RootSentinel();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('root')));
}
