import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('BottomNavBar renders with correct labels', (tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('בית'), findsOneWidget);
    expect(find.text('סריקה'), findsOneWidget);
    expect(find.text('קהילה'), findsOneWidget);
    expect(find.text('מועדפים'), findsOneWidget);
  });

  testWidgets('BottomNavBar responds to tap', (tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('סריקה'));
    await tester.pump();

    expect(selectedIndex, 1);
  });

  testWidgets('BottomNavBar shows correct selected tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2,
            onTap: (_) {},
          ),
        ),
      ),
    );

    final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.selectedIndex, 2);
  });
}