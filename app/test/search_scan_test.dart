import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/search_scan_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';

void main() {
  testWidgets('SearchScanScreen renders all main sections', (tester) async {
    final userProfile = UserProfile(
      selectedAllergenIds: {},
    );

    final allergens = <Allergen>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScanScreen(
          userProfile: userProfile,
          allergens: allergens,
          currentNavIndex: 1,
          onNavIndexChanged: (_) {},
        ),
      ),
    );

    expect(find.text('סריקת ברקוד'), findsOneWidget);
    expect(find.text('נסרק לארכונה'), findsOneWidget);
    expect(find.text('טיפ בטיחות'), findsOneWidget);
    expect(find.text('בית'), findsOneWidget);
    expect(find.text('סריקה'), findsOneWidget);
    expect(find.text('קהילה'), findsOneWidget);
    expect(find.text('מועדפים'), findsOneWidget);
  });

  testWidgets('SearchScanScreen shows search input with hint', (tester) async {
    final userProfile = UserProfile(
      selectedAllergenIds: {},
    );

    final allergens = <Allergen>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScanScreen(
          userProfile: userProfile,
          allergens: allergens,
          currentNavIndex: 1,
          onNavIndexChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('SearchScanScreen shows scanner viewport', (tester) async {
    final userProfile = UserProfile(
      selectedAllergenIds: {},
    );

    final allergens = <Allergen>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScanScreen(
          userProfile: userProfile,
          allergens: allergens,
          currentNavIndex: 1,
          onNavIndexChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(AspectRatio), findsOneWidget);
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('SearchScanScreen shows recent scans', (tester) async {
    final userProfile = UserProfile(
      selectedAllergenIds: {},
    );

    final allergens = <Allergen>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScanScreen(
          userProfile: userProfile,
          allergens: allergens,
          currentNavIndex: 1,
          onNavIndexChanged: (_) {},
        ),
      ),
    );

    expect(find.text('חלב שולו 5%'), findsOneWidget);
    expect(find.text('שולו'), findsOneWidget);
    expect(find.text('לחם מחמצת'), findsOneWidget);
    expect(find.text('לחמייה'), findsOneWidget);
  });

  testWidgets('SearchScanScreen responds to nav tap', (tester) async {
    final userProfile = UserProfile(
      selectedAllergenIds: {},
    );

    final allergens = <Allergen>[];

    int selectedIndex = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScanScreen(
          userProfile: userProfile,
          allergens: allergens,
          currentNavIndex: selectedIndex,
          onNavIndexChanged: (index) => selectedIndex = index,
        ),
      ),
    );

    await tester.tap(find.text('בית'));
    await tester.pump();

    expect(selectedIndex, 0);
  });
}