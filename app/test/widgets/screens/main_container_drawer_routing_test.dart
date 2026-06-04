import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/main_container.dart';

Widget _buildHost() {
  return MaterialApp(
    home: MainContainer(
      userProfile: const UserProfile(hasCompletedOnboarding: true),
      allergens: const [],
      onProfileUpdated: (_) {},
    ),
  );
}

Future<void> _pumpHost(WidgetTester tester) async {
  // Default 800x600 surface is shorter than the drawer's intrinsic height
  // (header + 6 rows + footer ≈ 633 pt) and triggers a RenderFlex overflow
  // that fails the test before any tap. Resize to a real-phone size.
  await tester.binding.setSurfaceSize(const Size(440, 950));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_buildHost());
}

Future<void> _openDrawerAndTap(WidgetTester tester, String rowLabel) async {
  // Open the drawer programmatically — tapping the menu icon in this RTL
  // Scaffold lands the open-edge off-screen at the default test viewport,
  // which makes the row's hit-test offset unreliable.
  tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  // Drive the drawer-slide animation forward over multiple frames (single
  // pump(Duration) jumps the clock but the AnimationController needs ticks
  // to interpolate position; pumpAndSettle is unsafe — SearchScanScreen's
  // laser controller repeats forever).
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(find.text(rowLabel));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('MainContainer drawer routing (Issue #25 AC: rows route to new screens)', () {
    testWidgets('row 2 "היסטוריית סריקה" pushes ScanHistoryScreen', (tester) async {
      await _pumpHost(tester);
      await _openDrawerAndTap(tester, 'היסטוריית סריקה');
      // Destination app-bar title — proves we landed on ScanHistoryScreen,
      // not some other screen happening to render the same drawer-row label.
      expect(find.text('היסטוריית סריקה'), findsWidgets);
      expect(find.text('אין סריקות עדיין'), findsOneWidget);
    });

    testWidgets('row 3 "מוצרים שמורים" pushes SavedProductsScreen', (tester) async {
      await _pumpHost(tester);
      await _openDrawerAndTap(tester, 'מוצרים שמורים');
      expect(find.text('אין מוצרים שמורים'), findsOneWidget);
    });

    testWidgets('row 4 "ביקורות שלי" pushes MyReviewsScreen', (tester) async {
      await _pumpHost(tester);
      await _openDrawerAndTap(tester, 'ביקורות שלי');
      expect(find.text('עדיין לא כתבת ביקורות'), findsOneWidget);
    });

    testWidgets('row 5 "מרכז עזרה" pushes HelpCenterScreen', (tester) async {
      await _pumpHost(tester);
      await _openDrawerAndTap(tester, 'מרכז עזרה');
      expect(find.text('שאלות נפוצות'), findsOneWidget);
    });

    testWidgets('row 6 "אודות" pushes AboutScreen', (tester) async {
      await _pumpHost(tester);
      await _openDrawerAndTap(tester, 'אודות');
      expect(find.text('אודות האפליקציה'), findsOneWidget);
    });
  });
}
