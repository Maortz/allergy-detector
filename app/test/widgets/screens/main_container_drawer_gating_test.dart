import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/main_container.dart';
import 'package:app/screens/admin_navigation_drawer.dart';
import 'package:app/screens/drawer_user_screen.dart';

Widget _buildHost({required bool isAdmin}) {
  return MaterialApp(
    home: MainContainer(
      userProfile: UserProfile(
        hasCompletedOnboarding: true,
        isAdmin: isAdmin,
      ),
      allergens: const [],
      onProfileUpdated: (_) {},
    ),
  );
}

Future<void> _pumpHost(WidgetTester tester, {required bool isAdmin}) async {
  // Match the real-phone surface used elsewhere so the drawer's intrinsic
  // height does not overflow the default 800x600 test viewport.
  await tester.binding.setSurfaceSize(const Size(440, 950));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_buildHost(isAdmin: isAdmin));
}

void main() {
  group('MainContainer drawer gating on isAdmin (Issue #21)', () {
    testWidgets('admin: menu icon opens the end drawer (admin variant)',
        (tester) async {
      await _pumpHost(tester, isAdmin: true);

      // The Scaffold auto-injects an endDrawer hamburger in the actions slot
      // for the admin case, so two Icons.menu exist; the AppBar's custom
      // leading button (the one wired to the gating conditional) is first.
      await tester.tap(find.byIcon(Icons.menu).first);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final state = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      expect(state.isEndDrawerOpen, isTrue);
      expect(state.isDrawerOpen, isFalse);
      expect(find.byType(AdminNavigationDrawer), findsOneWidget);
      expect(find.byType(DrawerUserScreen), findsNothing);
    });

    testWidgets('non-admin: menu icon opens the start drawer (user variant)',
        (tester) async {
      await _pumpHost(tester, isAdmin: false);

      // The Scaffold auto-injects an endDrawer hamburger in the actions slot
      // for the admin case, so two Icons.menu exist; the AppBar's custom
      // leading button (the one wired to the gating conditional) is first.
      await tester.tap(find.byIcon(Icons.menu).first);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final state = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      expect(state.isDrawerOpen, isTrue);
      expect(state.isEndDrawerOpen, isFalse);
      expect(find.byType(DrawerUserScreen), findsOneWidget);
      expect(find.byType(AdminNavigationDrawer), findsNothing);
    });
  });
}
