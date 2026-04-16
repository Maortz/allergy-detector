import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/widgets/product_card.dart';

void main() {
  final testProduct = Product(
    id: 'p1',
    nameHe: 'חטיף בוטנים',
    brandNameHe: 'סניקרס',
    brandTrustScore: 0.8,
    allergens: [
      const ProductAllergen(
          allergenId: 'a1', allergenNameHe: 'בוטנים', severity: 'contains'),
      const ProductAllergen(
          allergenId: 'a2', allergenNameHe: 'אגוזים', severity: 'may_contain'),
    ],
  );

  testWidgets('ProductCard shows avoid for matching contains allergen',
      (tester) async {
    final profile = const UserProfile(selectedAllergenIds: {'a1'});

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ProductCard(product: testProduct, userProfile: profile),
      ),
    ));

    expect(find.text('הימנע'), findsOneWidget);
    expect(find.text('בוטנים'), findsOneWidget);
    expect(find.text('אגוזים'), findsOneWidget);
  });

  testWidgets('ProductCard shows caution for matching may_contain allergen',
      (tester) async {
    final profile = const UserProfile(selectedAllergenIds: {'a2'});

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ProductCard(product: testProduct, userProfile: profile),
      ),
    ));

    expect(find.text('זהירות'), findsOneWidget);
  });

  testWidgets('ProductCard shows safe when no allergens match', (tester) async {
    final profile = const UserProfile(selectedAllergenIds: {'a99'});

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ProductCard(product: testProduct, userProfile: profile),
      ),
    ));

    expect(find.text('בטוח'), findsOneWidget);
  });

  testWidgets('ProductCard displays product name and brand', (tester) async {
    final profile = const UserProfile();

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ProductCard(product: testProduct, userProfile: profile),
      ),
    ));

    expect(find.text('חטיף בוטנים'), findsOneWidget);
    expect(find.text('סניקרס'), findsOneWidget);
  });
}
