import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/product.dart';
import 'package:app/services/product_service.dart';

void main() {
  group('ProductService', () {
    test('Product model correctly parses from JSON', () {
      final json = {
        'id': 'prod-1',
        'name_he': 'פסטו',
        'barcode': '7290123456789',
        'brand_id': 'brand-1',
        'brands': {'name_he': 'טרה', 'trust_score': 0.85},
        'is_kosher': true,
      };
      
      final product = Product.fromJson(json);
      
      expect(product.id, 'prod-1');
      expect(product.nameHe, 'פסטו');
      expect(product.brandNameHe, 'טרה');
      expect(product.brandTrustScore, 0.85);
    });

    test('Product model handles null optional fields', () {
      final json = {
        'id': 'prod-2',
        'name_he': 'מוצר',
      };
      
      final product = Product.fromJson(json);
      
      expect(product.id, 'prod-2');
      expect(product.barcode, isNull);
      expect(product.brandNameHe, isNull);
    });

    test('Product allergen filtering works', () {
      final product = Product(
        id: 'prod-1',
        nameHe: 'מוצר',
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
          ProductAllergen(allergenId: '2', allergenNameHe: 'חלב', severity: 'may_contain'),
        ],
      );
      
      expect(product.containsAllergens.length, 1);
      expect(product.containsAllergens[0].allergenId, '1');
      expect(product.mayContainAllergens.length, 1);
      expect(product.mayContainAllergens[0].allergenId, '2');
    });
  });
}