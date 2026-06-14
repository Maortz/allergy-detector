import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/main_container.dart';
import 'package:app/screens/admin_navigation_drawer.dart';
import 'package:app/screens/admin_destination_screen.dart';

Widget _buildHost(GlobalKey<MainContainerState> key) {
  return MaterialApp(
    home: MainContainer(
      key: key,
      userProfile: const UserProfile(
        hasCompletedOnboarding: true,
        isAdmin: true,
      ),
      allergens: const [],
      onProfileUpdated: (_) {},
    ),
  );
}

Future<void> _openAdminDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu).first);
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('MainContainer live admin destination tracking (Issue #120)', () {
    testWidgets(
        'defaults to dashboard; tracks pushed Tier-3 screen; resets on pop',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final key = GlobalKey<MainContainerState>();
      await tester.pumpWidget(_buildHost(key));

      // Default before any navigation (nav-drawer-admin.md §5.4 — dashboard is
      // pre-selected at the admin home).
      expect(
        key.currentState!.activeAdminDestination,
        AdminDrawerDestination.dashboard,
      );

      // Open the root admin drawer and select a Tier-3 row (דיווחים / reports).
      await _openAdminDrawer(tester);
      await tester.tap(find.text('דיווחים'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The Tier-3 screen is pushed and the live destination follows it.
      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(
        key.currentState!.activeAdminDestination,
        AdminDrawerDestination.reports,
      );

      // Pop back to the admin home; the active row resets to dashboard.
      Navigator.of(key.currentContext!).pop();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(ReportsScreen), findsNothing);
      expect(
        key.currentState!.activeAdminDestination,
        AdminDrawerDestination.dashboard,
      );
    });

    testWidgets('root drawer renders the live active destination',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final key = GlobalKey<MainContainerState>();
      await tester.pumpWidget(_buildHost(key));

      await _openAdminDrawer(tester);
      final drawer = tester.widget<AdminNavigationDrawer>(
        find.byType(AdminNavigationDrawer),
      );
      expect(drawer.activeDestination, AdminDrawerDestination.dashboard);
    });
  });
}
