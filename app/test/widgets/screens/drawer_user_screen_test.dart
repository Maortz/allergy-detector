import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/drawer_user_screen.dart';
import 'package:app/theme/app_colors.dart';

void main() {
  group('DrawerUserScreen DU9 logout button', () {
    Future<void> pumpDrawer(
      WidgetTester tester, {
      VoidCallback? onLogout,
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
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DrawerUserScreen(
              userName: 'דנה',
              onLogout: onLogout ?? () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

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
        AppColors.destructiveSubtle,
      );
      expect(
        style.foregroundColor!.resolve(states),
        AppColors.onDestructiveSubtle,
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
}
