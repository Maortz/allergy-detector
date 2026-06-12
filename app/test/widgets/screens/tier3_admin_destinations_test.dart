import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/main_container.dart';
import 'package:app/screens/admin_destination_screen.dart';
import 'package:app/screens/admin_navigation_drawer.dart';

void _noop(AdminDrawerDestination _) {}

Widget _wrap(Widget child) => MaterialApp(home: child);

Widget _buildAdminHost() {
  return MaterialApp(
    home: MainContainer(
      userProfile: const UserProfile(
        hasCompletedOnboarding: true,
        isAdmin: true,
        displayName: 'דנה',
      ),
      allergens: const [],
      onProfileUpdated: (_) {},
    ),
  );
}

Future<void> _pumpAdminHost(WidgetTester tester) async {
  // Admin drawer is taller than the default 800x600 surface (header + two
  // section groups + footer); resize to a real-phone size to avoid overflow.
  await tester.binding.setSurfaceSize(const Size(440, 950));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_buildAdminHost());
}

Future<void> _openAdminDrawerAndTap(WidgetTester tester, String rowLabel) async {
  // Admin drawer mounts on endDrawer (RTL trailing edge); open it
  // programmatically and drive the slide animation frame-by-frame.
  // pumpAndSettle is unsafe — SearchScanScreen's laser controller repeats.
  tester.firstState<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(find.text(rowLabel));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // MainContainer loads recent scans from ScanHistoryService on init; mock an
  // empty store so the platform channel resolves.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Tier-3 admin destination screens render', () {
    testWidgets('AdminDashboardScreen renders title, body and coming-soon tag',
        (tester) async {
      await tester.pumpWidget(_wrap(AdminDashboardScreen(
        onDestinationSelected: _noop,
        onLogout: () {},
      )));
      expect(find.text('לוח בקרה'), findsWidgets);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.text('בקרוב'), findsOneWidget);
    });

    testWidgets('ReportsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(ReportsScreen(
        onDestinationSelected: _noop,
        onLogout: () {},
      )));
      expect(find.text('דיווחים'), findsWidgets);
      expect(find.byIcon(Icons.report), findsOneWidget);
    });

    testWidgets('SystemSettingsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(SystemSettingsScreen(
        onDestinationSelected: _noop,
        onLogout: () {},
      )));
      expect(find.text('הגדרות מערכת'), findsWidgets);
    });

    testWidgets('ProductScansScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(ProductScansScreen(
        onDestinationSelected: _noop,
        onLogout: () {},
      )));
      expect(find.text('סריקות מוצרים'), findsWidgets);
      expect(find.byIcon(Icons.barcode_reader), findsOneWidget);
    });

    testWidgets('CommunityManagementScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(CommunityManagementScreen(
        onDestinationSelected: _noop,
        onLogout: () {},
      )));
      expect(find.text('ניהול קהילה'), findsWidgets);
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('logout button fires onLogout', (tester) async {
      var loggedOut = false;
      await tester.pumpWidget(_wrap(AdminDashboardScreen(
        onDestinationSelected: _noop,
        onLogout: () => loggedOut = true,
      )));
      // The logout button lives inside the endDrawer; open it first.
      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.text('התנתקות'));
      await tester.pump();
      expect(loggedOut, isTrue);
    });
  });

  group('MainContainer admin drawer routing (Issue #26)', () {
    testWidgets('row "לוח בקרה" pushes AdminDashboardScreen', (tester) async {
      await _pumpAdminHost(tester);
      await _openAdminDrawerAndTap(tester, 'לוח בקרה');
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('בקרוב'), findsOneWidget);
    });

    testWidgets('row "דיווחים" pushes ReportsScreen', (tester) async {
      await _pumpAdminHost(tester);
      await _openAdminDrawerAndTap(tester, 'דיווחים');
      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    testWidgets('row "הגדרות מערכת" pushes SystemSettingsScreen',
        (tester) async {
      await _pumpAdminHost(tester);
      await _openAdminDrawerAndTap(tester, 'הגדרות מערכת');
      expect(find.byType(SystemSettingsScreen), findsOneWidget);
    });

    testWidgets('row "סריקות מוצרים" pushes ProductScansScreen',
        (tester) async {
      await _pumpAdminHost(tester);
      await _openAdminDrawerAndTap(tester, 'סריקות מוצרים');
      expect(find.byType(ProductScansScreen), findsOneWidget);
    });

    testWidgets('row "ניהול קהילה" pushes CommunityManagementScreen',
        (tester) async {
      await _pumpAdminHost(tester);
      await _openAdminDrawerAndTap(tester, 'ניהול קהילה');
      expect(find.byType(CommunityManagementScreen), findsOneWidget);
    });
  });
}
