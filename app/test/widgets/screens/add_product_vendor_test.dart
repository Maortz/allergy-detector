import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/models/allergen.dart';
import 'package:app/screens/add_product_screen.dart';
import 'package:app/services/product_service.dart';

/// Fake that records / fails the inline vendor create (#266) without touching
/// Supabase.
class _FakeProductService extends ProductService {
  _FakeProductService({this.error = false})
      : super(SupabaseClient(
          'http://localhost',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ));

  bool error;
  int addBrandCalls = 0;
  String? lastBrandName;

  @override
  Future<String> addBrand(String nameHe) async {
    addBrandCalls++;
    lastBrandName = nameHe;
    if (error) throw Exception('brand insert failed');
    return nameHe;
  }
}

void main() {
  const allergens = [
    Allergen(id: 'a0000000-0000-0000-0000-000000000001', nameHe: 'חלב'),
  ];
  const brands = ['תנובה', 'שטראוס'];

  Widget host(ProductService service) => MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: AddProductWizard(
          allergens: allergens,
          brands: brands,
          productService: service,
        ),
      );

  Future<void> openAddVendor(WidgetTester tester) async {
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('➕ הוסף מותג חדש').last);
    await tester.pumpAndSettle();
  }

  testWidgets('creating a new vendor selects it and calls addBrand once',
      (tester) async {
    final service = _FakeProductService();
    await tester.pumpWidget(host(service));

    await openAddVendor(tester);

    expect(find.text('הוספת מותג חדש'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'מותג חדש',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'שמירה'));
    await tester.pumpAndSettle();

    expect(service.addBrandCalls, 1);
    expect(service.lastBrandName, 'מותג חדש');
    // The dialog closed and the new vendor is now the selected dropdown value.
    expect(find.text('הוספת מותג חדש'), findsNothing);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>))
          .initialValue,
      'מותג חדש',
    );
  });

  testWidgets('a failed vendor create keeps the dialog with an error',
      (tester) async {
    final service = _FakeProductService(error: true);
    await tester.pumpWidget(host(service));

    await openAddVendor(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'מותג חדש',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'שמירה'));
    await tester.pumpAndSettle();

    expect(service.addBrandCalls, 1);
    // Dialog stays open with the error; nothing was selected.
    expect(find.text('הוספת מותג חדש'), findsOneWidget);
    expect(find.text('לא ניתן להוסיף מותג, נסו שוב'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>))
          .initialValue,
      isNull,
    );
  });

  testWidgets('empty vendor name shows inline validation, no service call',
      (tester) async {
    final service = _FakeProductService();
    await tester.pumpWidget(host(service));

    await openAddVendor(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'שמירה'));
    await tester.pumpAndSettle();

    expect(service.addBrandCalls, 0);
    expect(find.text('נא להזין שם מותג'), findsOneWidget);
  });
}
