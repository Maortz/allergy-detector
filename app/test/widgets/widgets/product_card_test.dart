import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/product_card.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';

void main() {
  group('ProductCard', () {
    final safeProduct = Product(
      id: 'prod-1',
      nameHe: 'פסטו בולו',
      brandNameHe: 'טרה',
      isKosher: true,
      allergens: [
        ProductAllergen(allergenId: '99', allergenNameHe: 'לא רלוונטי', severity: 'contains'),
      ],
    );

    final avoidProduct = Product(
      id: 'prod-2',
      nameHe: 'לחם חיטה',
      brandNameHe: 'מאפה',
      isKosher: false,
      allergens: [
        ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
      ],
    );

    final cautionProduct = Product(
      id: 'prod-3',
      nameHe: 'עוגיות',
      brandNameHe: 'בית אפייה',
      isKosher: true,
      allergens: [
        ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'may_contain'),
      ],
    );

    testWidgets('displays Hebrew product name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: safeProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
            ),
          ),
        ),
      );

      expect(find.text('פסטו בולו'), findsOneWidget);
    });

    testWidgets('displays brand name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: safeProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
            ),
          ),
        ),
      );

      expect(find.text('טרה'), findsOneWidget);
    });

    testWidgets('displays kosher badge when product is kosher', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: safeProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
            ),
          ),
        ),
      );

      expect(find.text('כשר'), findsOneWidget);
    });

    testWidgets('shows "הימנע" status when product contains user allergen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: avoidProduct,
              userProfile: const UserProfile(selectedAllergenIds: {'1'}),
            ),
          ),
        ),
      );

      expect(find.text('הימנע'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous), findsOneWidget);
    });

    testWidgets('shows "זהירות" status when product may contain user allergen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: cautionProduct,
              userProfile: const UserProfile(selectedAllergenIds: {'1'}),
            ),
          ),
        ),
      );

      expect(find.text('זהירות'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('shows "בטוח" status when no allergens match', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: safeProduct,
              userProfile: const UserProfile(selectedAllergenIds: {'1'}),
            ),
          ),
        ),
      );

      expect(find.text('בטוח'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: safeProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('calls onReport when report button is pressed', (tester) async {
      bool reported = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: safeProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
              onReport: () => reported = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('דווח בעיה'));
      await tester.pump();

      expect(reported, true);
    });

    testWidgets('displays contains allergens section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: avoidProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
            ),
          ),
        ),
      );

      expect(find.text('מכיל:'), findsOneWidget);
      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('displays may contain allergens section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: cautionProduct,
              userProfile: const UserProfile(selectedAllergenIds: {}),
            ),
          ),
        ),
      );

      expect(find.text('עשוי להכיל:'), findsOneWidget);
      expect(find.text('גלוטן'), findsOneWidget);
    });
  });
}