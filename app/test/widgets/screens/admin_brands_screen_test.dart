// test/widgets/screens/admin_brands_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/admin_brands_screen.dart';
import 'package:app/models/brand.dart';
import 'package:app/services/brand_service.dart';
import 'package:app/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Fake BrandService — avoids live Supabase in tests.
// ---------------------------------------------------------------------------
class _FakeBrandService extends BrandService {
  List<Brand> brands;
  bool throwOnFetch;
  _FakeBrandService({this.brands = const [], this.throwOnFetch = false})
      : super(_FakeSupabaseClient());

  @override
  Future<List<Brand>> fetchBrands() async {
    if (throwOnFetch) throw Exception('network error');
    return brands;
  }

  @override
  Future<void> updateVerification(String brandId, bool isVerified) async {}
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Widget _wrap(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    );

AdminBrandsScreen _screen({
  List<Brand> brands = const [],
  bool throwOnFetch = false,
}) =>
    AdminBrandsScreen.testable(
      brandService: _FakeBrandService(
          brands: brands, throwOnFetch: throwOnFetch),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('AdminBrandsScreen — page header', () {
    testWidgets('renders H1 title "ניהול מותגים מאושרים"', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pump();
      expect(find.text('ניהול מותגים מאושרים'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pump();
      expect(
        find.text('עדכן ואמת מותגים במאגר הנתונים של הקליניקה'),
        findsOneWidget,
      );
    });
  });

  group('AdminBrandsScreen — search bento card', () {
    testWidgets('search placeholder is "הקלד שם מותג…"', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'הקלד שם מותג…'), findsOneWidget);
    });

    testWidgets('typing filters brand list in real time', (tester) async {
      final brands = [
        const Brand(id: '1', name: 'תנובה', isVerified: true),
        const Brand(id: '2', name: 'שטראוס', isVerified: false),
      ];
      await tester.pumpWidget(_wrap(_screen(brands: brands)));
      await tester.pump();

      expect(find.text('תנובה'), findsOneWidget);
      expect(find.text('שטראוס'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'תנו');
      await tester.pump();

      expect(find.text('תנובה'), findsOneWidget);
      expect(find.text('שטראוס'), findsNothing);
    });

    testWidgets('clearing search text restores full list', (tester) async {
      final brands = [
        const Brand(id: '1', name: 'תנובה', isVerified: true),
        const Brand(id: '2', name: 'שטראוס', isVerified: false),
      ];
      await tester.pumpWidget(_wrap(_screen(brands: brands)));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'תנו');
      await tester.pump();
      expect(find.text('שטראוס'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
      expect(find.text('שטראוס'), findsOneWidget);
    });
  });

  group('AdminBrandsScreen — stats card', () {
    testWidgets('shows total brand count', (tester) async {
      final brands = [
        const Brand(id: '1', name: 'תנובה', isVerified: true),
        const Brand(id: '2', name: 'שטראוס', isVerified: false),
      ];
      await tester.pumpWidget(_wrap(_screen(brands: brands)));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('מותגים רשומים'), findsOneWidget);
    });

    testWidgets('renders LinearProgressIndicator for verified percentage',
        (tester) async {
      await tester.pumpWidget(_wrap(_screen(
        brands: [
          const Brand(id: '1', name: 'תנובה', isVerified: true),
          const Brand(id: '2', name: 'שטראוס', isVerified: false),
        ],
      )));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('AdminBrandsScreen — brand row card', () {
    testWidgets('shows brand name', (tester) async {
      await tester.pumpWidget(_wrap(_screen(
        brands: [const Brand(id: '1', name: 'תנובה', isVerified: true)],
      )));
      await tester.pump();
      expect(find.text('תנובה'), findsOneWidget);
    });

    testWidgets('shows metadata line "ממתין לבדיקת רכיבים" for unverified brand',
        (tester) async {
      await tester.pumpWidget(_wrap(_screen(
        brands: [const Brand(id: '2', name: 'שטראוס', isVerified: false)],
      )));
      await tester.pump();
      expect(find.text('ממתין לבדיקת רכיבים'), findsOneWidget);
    });

    testWidgets('shows "עדכון אחרון:" prefix for verified brand with timestamp',
        (tester) async {
      final recent = DateTime.now().subtract(const Duration(days: 2));
      await tester.pumpWidget(_wrap(_screen(
        brands: [
          Brand(
            id: '1',
            name: 'תנובה',
            isVerified: true,
            lastUpdated: recent,
          ),
        ],
      )));
      await tester.pump();
      // Metadata line starts with "עדכון אחרון: "
      expect(
        find.textContaining('עדכון אחרון:'),
        findsOneWidget,
      );
    });

    testWidgets('initial-letter chip shown when no logo URL', (tester) async {
      await tester.pumpWidget(_wrap(_screen(
        brands: [const Brand(id: '1', name: 'תנובה', isVerified: true)],
      )));
      await tester.pump();
      // The Hebrew first char "ת" renders inside the chip
      expect(find.text('ת'), findsOneWidget);
      // Icons.store must NOT appear
      expect(find.byIcon(Icons.store), findsNothing);
    });
  });

  group('AdminBrandsScreen — add-brand button', () {
    testWidgets('add-brand is FilledButton not FAB', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsNothing);
      // The FilledButton.icon renders with the "הוספת מותג חדש" label
      expect(find.widgetWithText(FilledButton, 'הוספת מותג חדש'), findsOneWidget);
    });
  });

  group('AdminBrandsScreen — admin gate', () {
    testWidgets('shows denied view when isAdmin=false', (tester) async {
      await tester.pumpWidget(_wrap(
        AdminBrandsScreen.testable(
          brandService: _FakeBrandService(),
          isAdmin: false,
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('הגישה מוגבלת למנהלים בלבד'), findsOneWidget);
      // Brand list must NOT be shown when denied
      expect(find.byType(ListView), findsNothing);
    });
  });

  group('AdminBrandsScreen — empty state', () {
    testWidgets('shows empty state when no brands', (tester) async {
      await tester.pumpWidget(_wrap(_screen(brands: [])));
      await tester.pump();
      expect(find.text('אין מותגים רשומים'), findsOneWidget);
      expect(find.text('הוסף מותג חדש כדי להתחיל'), findsOneWidget);
    });
  });

  group('AdminBrandsScreen — scaffold background', () {
    testWidgets('Scaffold has AppColors.surface background', (tester) async {
      await tester.pumpWidget(_wrap(_screen()));
      await tester.pump();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.surface);
    });
  });
}
