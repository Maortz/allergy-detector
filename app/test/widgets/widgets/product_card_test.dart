import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/product_card.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';

Widget _wrap(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    theme: buildAppTheme(),
    darkTheme: buildDarkAppTheme(),
    themeMode: themeMode,
    home: Scaffold(body: child),
  );
}

void main() {
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

  group('ProductCard', () {
    testWidgets('displays Hebrew product name', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: safeProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
        ),
      ));
      expect(find.text('פסטו בולו'), findsOneWidget);
    });

    testWidgets('displays brand name', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: safeProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
        ),
      ));
      expect(find.text('טרה'), findsOneWidget);
    });

    testWidgets('displays kosher badge when product is kosher', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: safeProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
        ),
      ));
      expect(find.text('כשר'), findsOneWidget);
    });

    testWidgets('shows "הימנע" status when product contains user allergen', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: avoidProduct,
          userProfile: const UserProfile(selectedAllergenIds: {'1'}),
        ),
      ));
      expect(find.text('הימנע'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous), findsOneWidget);
    });

    testWidgets('shows "זהירות" status when product may contain user allergen', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: cautionProduct,
          userProfile: const UserProfile(selectedAllergenIds: {'1'}),
        ),
      ));
      expect(find.text('זהירות'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('shows "בטוח" status when no allergens match', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: safeProduct,
          userProfile: const UserProfile(selectedAllergenIds: {'1'}),
        ),
      ));
      expect(find.text('בטוח'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: safeProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(Card));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('calls onReport when report button is pressed', (tester) async {
      bool reported = false;
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: safeProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
          onReport: () => reported = true,
        ),
      ));
      await tester.tap(find.text('דווח בעיה'));
      await tester.pump();
      expect(reported, true);
    });

    testWidgets('displays contains allergens section', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: avoidProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
        ),
      ));
      expect(find.text('מכיל:'), findsOneWidget);
      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('displays may contain allergens section', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: cautionProduct,
          userProfile: const UserProfile(selectedAllergenIds: {}),
        ),
      ));
      expect(find.text('עשוי להכיל:'), findsOneWidget);
      expect(find.text('גלוטן'), findsOneWidget);
    });
  });

  group('ProductCard status badge uses theme-aware colors', () {
    final glutenContains = Product(
      id: 'prod-token-1',
      nameHe: 'מוצר בדיקה',
      allergens: [
        ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
      ],
    );

    final glutenMayContain = Product(
      id: 'prod-token-2',
      nameHe: 'מוצר בדיקה',
      allergens: [
        ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'may_contain'),
      ],
    );

    testWidgets('avoid badge icon uses AppColorsExt.avoid in light mode', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: glutenContains,
          userProfile: const UserProfile(selectedAllergenIds: {'1'}),
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.dangerous));
      expect(icon.color, AppColorsExt.light().avoid);
    });

    testWidgets('avoid badge icon uses AppColorsExt.avoid in dark mode', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: glutenContains,
          userProfile: const UserProfile(selectedAllergenIds: {'1'}),
        ),
        themeMode: ThemeMode.dark,
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.dangerous));
      expect(icon.color, AppColorsExt.dark().avoid);
    });

    testWidgets('caution badge icon uses AppColorsExt.warning in light mode', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: glutenMayContain,
          userProfile: const UserProfile(selectedAllergenIds: {'1'}),
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.warning));
      expect(icon.color, AppColorsExt.light().warning);
    });

    testWidgets('safe badge icon uses AppColorsExt.success in light mode', (tester) async {
      await tester.pumpWidget(_wrap(
        ProductCard(
          product: glutenContains,
          userProfile: const UserProfile(selectedAllergenIds: {}),
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, AppColorsExt.light().success);
    });
  });
}
