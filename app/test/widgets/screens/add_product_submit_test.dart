import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/product.dart';
import 'package:app/screens/add_product_screen.dart';
import 'package:app/services/product_service.dart';

class _FakeProductService extends ProductService {
  _FakeProductService({this.error = false, this.gate})
      : super(SupabaseClient(
          'http://localhost',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ));

  /// Mutable so a test can simulate a failed first attempt followed by a
  /// successful retry (flip to false between taps).
  bool error;
  final Completer<void>? gate;

  int calls = 0;
  String? lastName;
  List<String> lastContains = const [];
  List<String> lastMayContain = const [];

  @override
  Future<Product> addProduct({
    required String nameHe,
    String? brandName,
    String? barcode,
    String? ingredients,
    bool isKosher = false,
    List<String> containAllergenIds = const [],
    List<String> mayContainAllergenIds = const [],
    String? imageUrl,
  }) async {
    calls++;
    lastName = nameHe;
    lastContains = containAllergenIds;
    lastMayContain = mayContainAllergenIds;
    if (gate != null) await gate!.future;
    if (error) throw Exception('write failed');
    return const Product(id: 'new-id', nameHe: 'x');
  }
}

void main() {
  // A non-empty catalog so steps 3/4 render the allergen grid. An empty
  // catalog now intentionally shows the empty-catalog error state and blocks
  // advance (#59), which these submit-flow tests are not exercising.
  const catalog = [
    Allergen(id: 'a0000000-0000-0000-0000-000000000001', nameHe: 'חלב'),
    Allergen(id: 'a0000000-0000-0000-0000-000000000002', nameHe: 'ביצים'),
  ];
  const brands = ['תנובה', 'שטראוס'];
  Widget host(ProductService service) => MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: AddProductWizard(
          allergens: catalog,
          brands: brands,
          productService: service,
        ),
      );

  // Step-1 now requires a product name + brand (spec §7.6). Defaults fill both
  // so the wizard reaches step 4; pass an explicit [name] to override.
  Future<void> goToStep4(WidgetTester tester,
      {String name = 'מוצר בדיקה'}) async {
    await tester.enterText(find.byType(TextFormField).at(1), name);
    await tester.pump();
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('תנובה').last);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      final next = find.widgetWithText(ElevatedButton, 'המשך');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('step 4 renders the may-contain sub-instruction',
      (tester) async {
    await tester.pumpWidget(host(_FakeProductService()));
    await goToStep4(tester, name: 'מוצר');

    expect(
      find.text("סמן אלרגנים המצוינים תחת 'עלול להכיל' או 'בסביבת עבודה'"),
      findsOneWidget,
    );
  });

  // NOTE: the former "submit with empty name shows validation" case is now
  // unreachable through the UI — step-1 inline validation (spec §7.6) blocks
  // advancing past step 1 without a product name, so step 4 can never be
  // reached with an empty name. The defensive guard in `_submit` remains.

  testWidgets('successful submit persists via the service and navigates',
      (tester) async {
    final service = _FakeProductService();
    await tester.pumpWidget(host(service));
    await goToStep4(tester, name: 'מוצר בדיקה');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(service.lastName, 'מוצר בדיקה');
    expect(find.text('המוצר נוסף בהצלחה!'), findsOneWidget);
  });

  testWidgets('failed submit shows an inline error and stays on the wizard',
      (tester) async {
    final service = _FakeProductService(error: true);
    await tester.pumpWidget(host(service));
    await goToStep4(tester, name: 'מוצר');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.pump();
    await tester.pump();

    expect(find.text('אירעה שגיאה בשמירת המוצר. נסה שוב.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'סיום ושליחה'), findsOneWidget);
  });

  testWidgets('retry after a failed submit re-attempts and navigates on success',
      (tester) async {
    final service = _FakeProductService(error: true);
    await tester.pumpWidget(host(service));
    await goToStep4(tester, name: 'מוצר');

    // First attempt fails → inline error, still on the wizard.
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.pump();
    await tester.pump();
    expect(find.text('אירעה שגיאה בשמירת המוצר. נסה שוב.'), findsOneWidget);
    expect(service.calls, 1);

    // The backend recovers; re-tapping the submit CTA retries and succeeds.
    service.error = false;
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('המוצר נוסף בהצלחה!'), findsOneWidget);
  });

  testWidgets('submit shows a loading spinner while the write is in flight',
      (tester) async {
    final gate = Completer<void>();
    final service = _FakeProductService(gate: gate);
    await tester.pumpWidget(host(service));
    await goToStep4(tester, name: 'מוצר');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('המוצר נוסף בהצלחה!'), findsOneWidget);
  });

  testWidgets(
      'selecting an allergen card passes its catalog UUID (not a slug) to addProduct',
      (tester) async {
    const milkUuid = 'a0000000-0000-0000-0000-000000000001';
    const catalog = [
      Allergen(id: milkUuid, nameHe: 'חלב'),
      Allergen(id: 'a0000000-0000-0000-0000-000000000002', nameHe: 'ביצים'),
    ];
    final service = _FakeProductService();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AddProductWizard(
        allergens: catalog,
        brands: const ['תנובה', 'שטראוס'],
        productService: service,
      ),
    ));

    // step 1 → enter name + select brand (spec §7.6) → next
    await tester.enterText(find.byType(TextFormField).at(1), 'מוצר');
    await tester.pump();
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('תנובה').last);
    await tester.pumpAndSettle();
    var next = find.widgetWithText(ElevatedButton, 'המשך');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // step 2 → next
    next = find.widgetWithText(ElevatedButton, 'המשך');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // step 3 → tap the חלב allergen card → next
    final milkCard = find.text('חלב');
    await tester.ensureVisible(milkCard);
    await tester.pumpAndSettle();
    await tester.tap(milkCard);
    await tester.pumpAndSettle();
    next = find.widgetWithText(ElevatedButton, 'המשך');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // step 4 → submit
    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'סיום ושליחה'));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(service.lastContains, [milkUuid],
        reason:
            'addProduct must receive the catalog UUID, not a hardcoded slug like "milk".');
  });
}
