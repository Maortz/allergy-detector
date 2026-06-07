import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/product_details.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/theme/app_colors.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ProductDetailsScreen Widget Tests', () {
    late Product testProduct;
    late UserProfile testProfile;

    setUp(() {
      testProduct = TestFixtures.sampleProduct;
      testProfile = TestFixtures.sampleProfile;
    });

    Widget createWidgetUnderTest({
      Product? product,
      UserProfile? profile,
      VoidCallback? onReport,
      VoidCallback? onDeleted,
    }) {
      return MaterialApp(
        home: ProductDetailsScreen(
          product: product ?? testProduct,
          userProfile: profile ?? testProfile,
          onReport: onReport,
          onDeleted: onDeleted,
        ),
      );
    }

    testWidgets('displays product name in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('פסטו בולו'), findsWidgets);
    });

    testWidgets('displays brand name in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('טרה'), findsOneWidget);
    });

    testWidgets('displays kosher label when product is kosher', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('כשר'), findsOneWidget);
    });

    testWidgets('displays status banner for dangerous product', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הימנע – מכיל אלרגנים'), findsOneWidget);
    });

    testWidgets('avoid banner uses the solid red token, not the pink tint',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final banner = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('הימנע – מכיל אלרגנים'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(banner.color, AppColors.avoid);
      expect(banner.color, isNot(AppColors.avoidBackground));
    });

    testWidgets('displays detected allergens section in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('אלרגנים שזוהו'), findsOneWidget);
    });

    testWidgets('displays allergen names in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('גלוטן'), findsOneWidget);
      expect(find.text('חלב'), findsOneWidget);
    });

    testWidgets('displays caution labels in Hebrew for may-contain allergens', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('זהירות'), findsOneWidget);
    });

    testWidgets('displays avoid labels in Hebrew for contained allergens', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הימנע'), findsWidgets);
    });

    testWidgets('displays ingredients section when ingredients available', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('רכיבים'), findsOneWidget);
      expect(find.text('לחץ להצגת רכיבים'), findsOneWidget);
    });

    testWidgets('displays report button in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('דיווח על טעות'), findsOneWidget);
    });

    testWidgets('displays bottom navigation bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('displays share button in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('displays danger icon for avoid status', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays warning icon for caution status', (tester) async {
      final cautionProduct = Product(
        id: 'test-1',
        nameHe: 'מוצר בדיקה',
        allergens: [
          ProductAllergen(
            allergenId: '1',
            allergenNameHe: 'גלוטן',
            severity: 'may_contain',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        product: cautionProduct,
      ));

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays safe status for product without user allergens', (tester) async {
      final safeProduct = Product(
        id: 'test-1',
        nameHe: 'מוצר בטוח',
        allergens: [
          ProductAllergen(
            allergenId: '99',
            allergenNameHe: 'אלרגן אחר',
            severity: 'contains',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        product: safeProduct,
        profile: const UserProfile(
          selectedAllergenIds: {},
          hasCompletedOnboarding: true,
        ),
      ));

      expect(find.text('✓ בטוח - ללא אלרגנים עבורך'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows snackbar when share button pressed', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();

      expect(find.text('הקישור הועתק ללוח'), findsOneWidget);
    });

    testWidgets('displays product image when available', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('displays flag icon for report button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });
}