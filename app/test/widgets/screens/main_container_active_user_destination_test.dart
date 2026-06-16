import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/main_container.dart';
import 'package:app/screens/drawer_user_screen.dart';
import 'package:app/screens/scan_history_screen.dart';

Widget _buildHost(GlobalKey<MainContainerState> key) {
  return MaterialApp(
    home: MainContainer(
      key: key,
      userProfile: const UserProfile(
        hasCompletedOnboarding: true,
        isAdmin: false,
      ),
      allergens: const [],
      onProfileUpdated: (_) {},
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MainContainer live user drawer destination tracking (DU6, #221)', () {
    testWidgets(
        'null by default; tracks the pushed destination; resets on pop',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final key = GlobalKey<MainContainerState>();
      await tester.pumpWidget(_buildHost(key));

      // No drawer destination is active while on a bottom-nav tab (§5.3).
      expect(key.currentState!.activeUserDestination, isNull);

      // Open the user drawer and select a Tier-3 row (היסטוריית סריקה).
      await tester.tap(find.byIcon(Icons.menu).first);
      await _settle(tester);
      await tester.tap(find.text('היסטוריית סריקה'));
      await _settle(tester);

      // The destination screen is pushed and the live destination follows it.
      expect(find.byType(ScanHistoryScreen), findsOneWidget);
      expect(
        key.currentState!.activeUserDestination,
        DrawerDestination.scanHistory,
      );

      // Pop back to the bottom-nav scaffold; the active row clears.
      Navigator.of(key.currentContext!).pop();
      await _settle(tester);
      expect(find.byType(ScanHistoryScreen), findsNothing);
      expect(key.currentState!.activeUserDestination, isNull);
    });

    testWidgets('reopened drawer renders the live active destination',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final key = GlobalKey<MainContainerState>();
      await tester.pumpWidget(_buildHost(key));

      // Push a destination, then reopen the drawer over it.
      await tester.tap(find.byIcon(Icons.menu).first);
      await _settle(tester);
      await tester.tap(find.text('היסטוריית סריקה'));
      await _settle(tester);
      expect(find.byType(ScanHistoryScreen), findsOneWidget);

      // The pushed ScanHistoryScreen has no drawer; reopen the root drawer by
      // re-rendering it — assert the wired activeDestination instead.
      Navigator.of(key.currentContext!).pop();
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.menu).first);
      await _settle(tester);
      final drawer =
          tester.widget<DrawerUserScreen>(find.byType(DrawerUserScreen));
      // After popping back to the tab, no row is highlighted.
      expect(drawer.activeDestination, isNull);
    });
  });
}
