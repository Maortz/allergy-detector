import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/screens/favorites_screen.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/services/favorites_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget buildSubject({
    ValueChanged<int>? onNavChanged,
    int currentNavIndex = 3,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: FavoritesScreen(
          userProfile: const UserProfile(),
          currentNavIndex: currentNavIndex,
          onNavIndexChanged: onNavChanged ?? (_) {},
          // Never hit Supabase in tests.
          productResolver: (_) async => null,
        ),
      ),
    );
  }

  group('empty variant', () {
    testWidgets('shows empty state heading', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('לא שמרת מוצרים עדיין'), findsOneWidget);
    });

    testWidgets('shows scan CTA button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('סרוק מוצר'), findsOneWidget);
    });

    testWidgets('scan CTA navigates to index 1', (tester) async {
      int? tappedIndex;
      await tester
          .pumpWidget(buildSubject(onNavChanged: (i) => tappedIndex = i));
      await tester.pumpAndSettle();
      await tester.tap(find.text('סרוק מוצר'));
      await tester.pump();
      expect(tappedIndex, 1);
    });

    testWidgets('shows favorite_border icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });

  group('list variant', () {
    Future<void> seedFavorite() => FavoritesService.add(
          const Product(id: 'p1', nameHe: 'חלב תנובה', brandNameHe: 'תנובה'),
        );

    testWidgets('renders persisted favorites', (tester) async {
      await seedFavorite();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('חלב תנובה'), findsOneWidget);
      expect(find.text('תנובה'), findsOneWidget);
      // Empty-state heading is gone.
      expect(find.text('לא שמרת מוצרים עדיין'), findsNothing);
    });

    testWidgets('removing a favorite empties the list', (tester) async {
      await seedFavorite();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      expect(find.text('חלב תנובה'), findsNothing);
      expect(find.text('לא שמרת מוצרים עדיין'), findsOneWidget);
    });
  });
}
