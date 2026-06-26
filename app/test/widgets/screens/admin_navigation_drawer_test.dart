import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/admin_navigation_drawer.dart';
import 'package:app/theme/app_colors.dart';

void main() {
  group('AdminNavigationDrawer Widget Tests', () {
    Future<void> pumpOpened(
      WidgetTester tester, {
      ValueChanged<AdminDrawerDestination>? onDestinationSelected,
      VoidCallback? onLogout,
      String? appVersion,
      AdminDrawerDestination? activeDestination,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            endDrawer: AdminNavigationDrawer(
              adminName: 'דנה',
              onDestinationSelected: onDestinationSelected ?? (_) {},
              onLogout: onLogout ?? () {},
              appVersion: appVersion,
              activeDestination: activeDestination,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('mounts on endDrawer slot (RTL right edge)', (tester) async {
      await pumpOpened(tester);

      final state = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      expect(state.hasEndDrawer, isTrue);
      expect(state.isEndDrawerOpen, isTrue);
    });

    testWidgets('renders the admin greeting and role chip', (tester) async {
      await pumpOpened(tester);

      expect(find.text('שלום, דנה'), findsOneWidget);
      expect(find.text('מנהל מערכת'), findsOneWidget);
    });

    testWidgets('renders both section labels and all six rows', (tester) async {
      await pumpOpened(tester);

      final scrollable = find.byType(Scrollable).first;
      for (final label in const [
        'ניהול מערכת',
        'לוח בקרה',
        'ניהול מותגים',
        'דיווחים',
        'הגדרות מערכת',
        'ניהול תוכן',
        'סריקות מוצרים',
        'ניהול קהילה',
      ]) {
        await tester.scrollUntilVisible(find.text(label), 60, scrollable: scrollable);
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('logout button uses "התנתקות" copy', (tester) async {
      await pumpOpened(tester);

      expect(find.widgetWithText(FilledButton, 'התנתקות'), findsOneWidget);
      expect(find.text('יציאה'), findsNothing);
    });

    testWidgets('tapping a row reports its destination', (tester) async {
      AdminDrawerDestination? selected;
      await pumpOpened(tester, onDestinationSelected: (d) => selected = d);

      await tester.tap(find.text('ניהול מותגים'));
      await tester.pumpAndSettle();

      expect(selected, AdminDrawerDestination.brandManagement);
    });

    testWidgets('renders the version row when appVersion is provided',
        (tester) async {
      await pumpOpened(tester, appVersion: 'v1.0.0');

      expect(find.text('v1.0.0'), findsOneWidget);
    });

    testWidgets('omits the version row when appVersion is null',
        (tester) async {
      await pumpOpened(tester);

      expect(find.textContaining('v1.0.0'), findsNothing);
    });

    testWidgets('active row is rendered with selected (highlight) state',
        (tester) async {
      await pumpOpened(
        tester,
        activeDestination: AdminDrawerDestination.dashboard,
      );

      final activeTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('לוח בקרה'),
          matching: find.byType(ListTile),
        ),
      );
      expect(activeTile.selected, isTrue);
      expect(activeTile.selectedTileColor, AppColorsExt.light().primaryTint);

      // A non-active row stays unselected.
      final inactiveTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('ניהול מותגים'),
          matching: find.byType(ListTile),
        ),
      );
      expect(inactiveTile.selected, isFalse);
    });

    testWidgets('tapping logout invokes onLogout', (tester) async {
      var loggedOut = false;
      await pumpOpened(tester, onLogout: () => loggedOut = true);

      await tester.tap(find.widgetWithText(FilledButton, 'התנתקות'));
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    });
  });
}
