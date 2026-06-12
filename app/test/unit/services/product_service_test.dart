import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/product.dart';

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

    test('Product model parses whole-number brand trust_score (int over wire)', () {
      // Postgres `float` columns can arrive as an integer over the REST wire
      // when the value is whole (e.g. `1` not `1.0`). The nested `brands` shape
      // that searchProducts / fromJson read must coerce via num.toDouble(),
      // otherwise the `as double?` cast throws a TypeError at runtime.
      final json = {
        'id': 'prod-3',
        'name_he': 'מוצר',
        'brands': {'name_he': 'תנובה', 'trust_score': 1},
      };

      final product = Product.fromJson(json);

      expect(product.brandTrustScore, 1.0);
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

    test('maps the flat add_product_with_allergens RPC row shape', () {
      // The atomic insert RPC (issue #45) returns brand fields flattened as
      // `brand_name_he` / `brand_trust_score` (not the nested `brands` object
      // the REST select returns). addProduct maps that flat shape — assert the
      // fields it reads so the mapping can't silently drift.
      final row = <String, dynamic>{
        'id': 'new-id',
        'name_he': 'מוצר חדש',
        'barcode': '7290000000001',
        'brand_id': 'brand-9',
        'ingredients': 'מים, סוכר',
        'is_kosher': true,
        'image_url': null,
        'is_archived': false,
        'brand_name_he': 'תנובה',
        // Postgres `float` can arrive as int or double over the wire.
        'brand_trust_score': 1,
      };

      final product = Product(
        id: row['id'] as String,
        nameHe: row['name_he'] as String,
        barcode: row['barcode'] as String?,
        brandId: row['brand_id'] as String?,
        brandNameHe: row['brand_name_he'] as String?,
        brandTrustScore: (row['brand_trust_score'] as num?)?.toDouble(),
        imageUrl: row['image_url'] as String?,
        ingredients: row['ingredients'] as String?,
        isKosher: row['is_kosher'] as bool? ?? false,
        isArchived: row['is_archived'] as bool? ?? false,
      );

      expect(product.id, 'new-id');
      expect(product.nameHe, 'מוצר חדש');
      expect(product.brandNameHe, 'תנובה');
      expect(product.brandTrustScore, 1.0);
      expect(product.isKosher, isTrue);
    });

    test('Product allergen filtering works', () {
      final product = Product(
        id: 'prod-1',
        nameHe: 'מוצר',
        allergens: [
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