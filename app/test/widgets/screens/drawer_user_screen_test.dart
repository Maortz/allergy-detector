import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/drawer_user_screen.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  Future<void> pumpDrawer(
    WidgetTester tester, {
    VoidCallback? onLogout,
    DrawerDestination? activeDestination,
    String? appVersion,
    String? userName,
  }) async {
    // Give a phone-height surface so the drawer Column (with its Spacer)
    // lays out without the 1px overflow seen in the default 800x600 test
    // viewport; the screen renders full-height in production.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DrawerUserScreen(
            userName: userName ?? 'דנה',
            onLogout: onLogout ?? () {},
            activeDestination: activeDestination,
            appVersion: appVersion,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DrawerUserScreen DU9 logout button', () {
    testWidgets('renders logout as a FilledButton, not a ListTile',
        (tester) async {
      await pumpDrawer(tester);

      // The logout affordance is a FilledButton.icon (regression guard
      // against reverting to the old ListTile).
      expect(find.byType(FilledButton), findsOneWidget);

      // No ListTile should carry the logout label.
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('התנתקות'),
        ),
        findsNothing,
      );
    });

    testWidgets('logout button shows the "התנתקות" label (copy regression guard)',
        (tester) async {
      await pumpDrawer(tester);

      final labelFinder = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('התנתקות'),
      );
      expect(labelFinder, findsOneWidget);

      // The old copy must not be present.
      expect(find.text('יציאה'), findsNothing);
    });

    testWidgets('logout button uses the destructive token colors',
        (tester) async {
      await pumpDrawer(tester);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;
      const states = <WidgetState>{};
      expect(
        style.backgroundColor!.resolve(states),
        AppColorsExt.light().destructiveSubtle,
      );
      expect(
        style.foregroundColor!.resolve(states),
        AppColorsExt.light().onDestructiveSubtle,
      );
    });

    testWidgets('tapping the logout button invokes onLogout once',
        (tester) async {
      var calls = 0;
      await pumpDrawer(tester, onLogout: () => calls++);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });
  });

  group('DrawerUserScreen V-Art fixes', () {
    // DU3 — greeting prefix
    testWidgets('header shows "שלום, [name]" greeting (DU3)', (tester) async {
      await pumpDrawer(tester, userName: 'דנה');
      expect(find.text('שלום, דנה'), findsOneWidget);
      // Old format (name only) must not appear as a standalone text
      expect(find.text('דנה'), findsNothing);
    });

    // DU4 — subtitle default
    testWidgets('subtitle defaults to "בטוח לאכול" when no subtitle passed (DU4)', (tester) async {
      await pumpDrawer(tester);
      expect(find.text('בטוח לאכול'), findsOneWidget);
    });

    // DU8 — row 4 label
    testWidgets('row 4 label is "ביקורות שלי" not "ביקורת קהילה" (DU8)', (tester) async {
      await pumpDrawer(tester);
      expect(find.text('ביקורות שלי'), findsOneWidget);
      expect(find.text('ביקורת קהילה'), findsNothing);
    });

    // DU12 — row 2 label
    testWidgets('row 2 label is "היסטוריית סריקה" (DU12)', (tester) async {
      await pumpDrawer(tester);
      expect(find.text('היסטוריית סריקה'), findsOneWidget);
      expect(find.text('היסטוריה'), findsNothing);
    });

    // DU6 — active-row highlight colour
    testWidgets('active row renders selectedTileColor primaryTint (DU6)', (tester) async {
      await pumpDrawer(tester, activeDestination: DrawerDestination.profile);
      // Find the selected ListTile
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      final activeTile = tiles.firstWhere(
        (t) => t.selected == true,
        orElse: () => throw TestFailure('no selected ListTile found'),
      );
      expect(activeTile.selectedTileColor, AppColorsExt.light().primaryTint);
    });

    // DU7 — divider between the two row groups (after row 4)
    testWidgets('divider exists between main rows and utility rows (DU7)', (tester) async {
      await pumpDrawer(tester);
      // There should be at least one Divider in the nav items area
      expect(find.byType(Divider), findsWidgets);
    });

    // DU10 — footer version row
    testWidgets('version string appears in footer when appVersion is supplied (DU10)', (tester) async {
      await pumpDrawer(tester, appVersion: 'v1.2.3');
      expect(find.text('v1.2.3'), findsOneWidget);
    });

    testWidgets('no version row when appVersion is null (DU10)', (tester) async {
      await pumpDrawer(tester, appVersion: null);
      // No version text in any form
      expect(find.textContaining('v1'), findsNothing);
    });

    // DU11 — white background
    testWidgets('drawer body background is surfaceContainerLowest (white) (DU11)', (tester) async {
      await pumpDrawer(tester);
      // Verify the Scaffold (outer container) uses the white token
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.surfaceContainerLowest);
    });
  });
}
