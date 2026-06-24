import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/product_card.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/theme/app_colors.dart';

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

  group('ProductCard dark mode', () {
    final avoidProduct = Product(
      id: 'prod-dark-avoid',
      nameHe: 'לחם חיטה',
      brandNameHe: 'מאפה',
      isKosher: false,
      allergens: [
        ProductAllergen(
            allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
      ],
    );

    final cautionProduct = Product(
      id: 'prod-dark-caution',
      nameHe: 'עוגיות',
      brandNameHe: 'בית אפייה',
      isKosher: true,
      allergens: [
        ProductAllergen(
            allergenId: '1', allergenNameHe: 'גלוטן', severity: 'may_contain'),
      ],
    );

    final safeProduct = Product(
      id: 'prod-dark-safe',
      nameHe: 'פסטו',
      brandNameHe: 'טרה',
      isKosher: true,
      allergens: [
        ProductAllergen(
            allergenId: '99',
            allergenNameHe: 'לא רלוונטי',
            severity: 'contains'),
      ],
    );

    // Pumps a ProductCard using [buildDarkAppTheme] — exercises the
    // AppColorsExt.dark() token path that the light-mode tests never reach.
    Widget buildDark(Product product, UserProfile profile) => MaterialApp(
          theme: buildDarkAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: ProductCard(product: product, userProfile: profile),
          ),
        );

    testWidgets('avoid status badge renders in dark mode with dark avoid color',
        (tester) async {
      await tester.pumpWidget(buildDark(
        avoidProduct,
        const UserProfile(selectedAllergenIds: {'1'}),
      ));

      // Status label renders.
      expect(find.text('הימנע'), findsOneWidget);

      // The dark AppColorsExt extension must be registered — verify the avoid
      // color token resolves to the dark palette value, not the light fallback.
      final BuildContext ctx = tester.element(find.byType(ProductCard));
      final AppColorsExt ext = Theme.of(ctx).extension<AppColorsExt>()!;
      expect(ext.avoid, equals(AppColorsExt.dark().avoid));
      expect(ext.avoid, isNotNull);
    });

    testWidgets(
        'caution status badge renders in dark mode with dark cautionText color',
        (tester) async {
      await tester.pumpWidget(buildDark(
        cautionProduct,
        const UserProfile(selectedAllergenIds: {'1'}),
      ));

      expect(find.text('זהירות'), findsOneWidget);

      final BuildContext ctx = tester.element(find.byType(ProductCard));
      final AppColorsExt ext = Theme.of(ctx).extension<AppColorsExt>()!;
      expect(ext.cautionText, equals(AppColorsExt.dark().cautionText));
      expect(ext.cautionText, isNotNull);
    });

    testWidgets('safe status badge renders in dark mode with dark safeText color',
        (tester) async {
      await tester.pumpWidget(buildDark(
        safeProduct,
        const UserProfile(selectedAllergenIds: {'1'}),
      ));

      expect(find.text('בטוח'), findsOneWidget);

      final BuildContext ctx = tester.element(find.byType(ProductCard));
      final AppColorsExt ext = Theme.of(ctx).extension<AppColorsExt>()!;
      expect(ext.safeText, equals(AppColorsExt.dark().safeText));
      expect(ext.safeText, isNotNull);
    });
  });
}