import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/search_screen.dart';
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

  // Regression for #92: the "show only safe" toggle in SearchScreenContent now
  // folds into ProductFilterLevel.safeOnly and shares statusFor severity
  // semantics with the level filter, instead of using the raw flat allergen
  // list. A may_contain-only match (caution) must therefore be admitted by
  // cautionAndAbove (toggle off) and hidden by safeOnly (toggle on) — both
  // driven by the same statusFor verdict the card displays.
  //
  // These tests drive the *production* decision: the real toggle→level mapping
  // (SearchScreenContent.effectiveFilterLevel) feeding the real admission check
  // (ProductFilterLevel.allows(statusFor(product))) — the exact expression
  // SearchScreenContent._filteredResults evaluates. They are not a copy of it,
  // so a regression in that mapping fails them.
  group('search filter severity semantics (#92)', () {
    final cautionOnlyProduct = Product(
      id: 'p2',
      nameHe: 'עוגיות',
      brandNameHe: 'מותג',
      brandTrustScore: 0.5,
      allergens: [
        const ProductAllergen(
            allergenId: 'a2', allergenNameHe: 'אגוזים', severity: 'may_contain'),
      ],
    );

    // Exercises the production filter decision end-to-end via the real
    // toggle→level resolver and the real allows/statusFor pair.
    bool admitsProduct(
        {required bool toggleOn,
        required ProductFilterLevel level,
        required UserProfile profile,
        required Product product}) {
      final effective = SearchScreenContent.effectiveFilterLevel(
        showOnlySafe: toggleOn,
        configuredLevel: level,
      );
      return effective.allows(profile.statusFor(product));
    }

    test('caution product visible at cautionAndAbove with toggle off', () {
      const profile = UserProfile(selectedAllergenIds: {'a2'});
      expect(profile.statusFor(cautionOnlyProduct), AllergenStatus.caution);
      expect(
        admitsProduct(
          toggleOn: false,
          level: ProductFilterLevel.cautionAndAbove,
          profile: profile,
          product: cautionOnlyProduct,
        ),
        true,
      );
    });

    test('caution product hidden when "show only safe" toggle is on', () {
      const profile = UserProfile(selectedAllergenIds: {'a2'});
      expect(
        admitsProduct(
          toggleOn: true,
          level: ProductFilterLevel.cautionAndAbove,
          profile: profile,
          product: cautionOnlyProduct,
        ),
        false,
      );
    });

    test('non-matching product stays visible with toggle on', () {
      const profile = UserProfile(selectedAllergenIds: {'a99'});
      expect(profile.statusFor(cautionOnlyProduct), AllergenStatus.safe);
      expect(
        admitsProduct(
          toggleOn: true,
          level: ProductFilterLevel.cautionAndAbove,
          profile: profile,
          product: cautionOnlyProduct,
        ),
        true,
      );
    });
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
