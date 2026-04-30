import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/product_details.dart';

void main() {
  final testProduct = Product(
    id: 'p1',
    nameHe: 'חטיף בוטנים',
    brandNameHe: 'סניקרס',
    brandTrustScore: 0.8,
    barcode: '72900001',
    isKosher: true,
    allergens: [
      const ProductAllergen(
          allergenId: 'a1', allergenNameHe: 'בוטנים', severity: 'contains'),
      const ProductAllergen(
          allergenId: 'a2', allergenNameHe: 'אגוזים', severity: 'may_contain'),
    ],
  );

  Widget buildTestWidget(UserProfile profile) {
    return MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ProductDetailsScreen(
        product: testProduct,
        userProfile: profile,
      ),
    );
  }

  testWidgets('Shows avoid when user allergen is in contains', (tester) async {
    final profile = const UserProfile(selectedAllergenIds: {'a1'});
    await tester.pumpWidget(buildTestWidget(profile));
    expect(find.textContaining('הימנע'), findsAtLeastNWidgets(1));
  });

  testWidgets('Shows caution when user allergen is in may_contain',
      (tester) async {
    final profile = const UserProfile(selectedAllergenIds: {'a2'});
    await tester.pumpWidget(buildTestWidget(profile));
    expect(find.textContaining('זהירות'), findsAtLeastNWidgets(1));
  });

  testWidgets('Shows safe when no user allergens match', (tester) async {
    final profile = const UserProfile(selectedAllergenIds: {'a99'});
    await tester.pumpWidget(buildTestWidget(profile));
    expect(find.textContaining('בטוח'), findsAtLeastNWidgets(1));
  });

  testWidgets('Shows product details: kosher, brand', (tester) async {
    final profile = const UserProfile();
    await tester.pumpWidget(buildTestWidget(profile));
    expect(find.text('חטיף בוטנים'), findsWidgets);
    expect(find.text('סניקרס'), findsWidgets);
    expect(find.text('כשר'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('Shows detected allergens section', (tester) async {
    final profile = const UserProfile();
    await tester.pumpWidget(buildTestWidget(profile));
    expect(find.text('אלרגנים שזוהו'), findsOneWidget);
    expect(find.text('בוטנים'), findsOneWidget);
    expect(find.text('אגוזים'), findsOneWidget);
  });
}
