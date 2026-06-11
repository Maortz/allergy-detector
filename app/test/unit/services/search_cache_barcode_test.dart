import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/models/product.dart';
import 'package:app/services/search_cache.dart';

Product _product(String barcode) => Product(
      id: 'id-$barcode',
      nameHe: 'מוצר $barcode',
      barcode: barcode,
      brandNameHe: 'מותג',
    );

/// Rewinds the barcode cache's freshness timestamp by [age] so TTL expiry can
/// be exercised deterministically without sleeping.
Future<void> _ageBarcodeCache(Duration age) async {
  final prefs = await SharedPreferences.getInstance();
  final aged = DateTime.now().toUtc().subtract(age);
  await prefs.setString(
      'search_cache_barcode_timestamp', aged.toIso8601String());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SearchCache barcode cache', () {
    test('miss on an empty cache', () async {
      expect(await SearchCache.loadBarcode('7290000000001'), isNull);
    });

    test('hit after save returns the cached product', () async {
      await SearchCache.saveBarcode('7290000000001', _product('7290000000001'));

      final hit = await SearchCache.loadBarcode('7290000000001');
      expect(hit, isNotNull);
      expect(hit!.id, 'id-7290000000001');
      expect(hit.nameHe, 'מוצר 7290000000001');
      expect(hit.barcode, '7290000000001');
    });

    test('miss for a different barcode', () async {
      await SearchCache.saveBarcode('111', _product('111'));
      expect(await SearchCache.loadBarcode('222'), isNull);
    });

    test('entry within TTL is still served', () async {
      await SearchCache.saveBarcode('111', _product('111'));
      await _ageBarcodeCache(SearchCache.staleThreshold - const Duration(minutes: 1));
      expect(await SearchCache.loadBarcode('111'), isNotNull);
    });

    test('entry past TTL expires (returns null)', () async {
      await SearchCache.saveBarcode('111', _product('111'));
      await _ageBarcodeCache(SearchCache.staleThreshold + const Duration(minutes: 1));
      expect(await SearchCache.loadBarcode('111'), isNull);
    });

    test('barcode cache is independent of the text-search cache', () async {
      await SearchCache.saveBarcode('111', _product('111'));
      await SearchCache.save('cookies', [_product('999')]);

      // Each namespace resolves its own key without cross-talk.
      expect(await SearchCache.loadBarcode('111'), isNotNull);
      expect(await SearchCache.loadBarcode('999'), isNull);
      expect(await SearchCache.load('cookies'), hasLength(1));
    });

    test('preserves allergen payload through a round-trip', () async {
      final product = Product(
        id: 'p',
        nameHe: 'חלב',
        barcode: '111',
        allergens: [
          ProductAllergen(
            allergenId: 'milk',
            allergenNameHe: 'חלב',
            severity: 'contains',
          ),
        ],
      );
      await SearchCache.saveBarcode('111', product);

      final hit = await SearchCache.loadBarcode('111');
      expect(hit!.containsAllergens, hasLength(1));
      expect(hit.containsAllergens.single.allergenId, 'milk');
    });

    test('stored payload is valid JSON under the barcode key', () async {
      await SearchCache.saveBarcode('111', _product('111'));
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('search_cache_barcode');
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), isA<Map<String, dynamic>>());
    });
  });
}
