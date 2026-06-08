import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/models/allergen.dart';

void main() {
  group('Product', () {
    test('has correct properties', () {
      const product = Product(
        id: '1',
        nameHe: 'מוצר בדיקה',
        barcode: '123456789',
        brandNameHe: 'מותג בדיקה',
        brandTrustScore: 0.8,
        isKosher: true,
      );
      expect(product.id, '1');
      expect(product.nameHe, 'מוצר בדיקה');
      expect(product.barcode, '123456789');
      expect(product.brandNameHe, 'מותג בדיקה');
      expect(product.brandTrustScore, 0.8);
      expect(product.isKosher, true);
    });

    test('fromJson creates instance correctly', () {
      final json = {
        'id': '2',
        'name_he': 'מוצר מJSON',
        'barcode': '987654321',
        'brands': {'name_he': 'מותג', 'trust_score': 0.9},
        'is_kosher': true,
      };
      final product = Product.fromJson(json);
      expect(product.id, '2');
      expect(product.nameHe, 'מוצר מJSON');
      expect(product.barcode, '987654321');
      expect(product.brandNameHe, 'מותג');
      expect(product.brandTrustScore, 0.9);
      expect(product.isKosher, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': '3', 'name_he': 'מוצר בסיסי'};
      final product = Product.fromJson(json);
      expect(product.id, '3');
      expect(product.barcode, isNull);
      expect(product.brandId, isNull);
      expect(product.brandNameHe, isNull);
      expect(product.isKosher, false);
    });

    test('containsAllergens getter filters by severity', () {
      final product = Product(
        id: '1',
        nameHe: 'Test',
        allergens: [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
          ProductAllergen(allergenId: '2', allergenNameHe: 'חלב', severity: 'may_contain'),
        ],
      );
      expect(product.containsAllergens.length, 1);
      expect(product.containsAllergens.first.allergenId, '1');
    });

    test('mayContainAllergens getter filters by severity', () {
      final product = Product(
        id: '1',
        nameHe: 'Test',
        allergens: [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
          ProductAllergen(allergenId: '2', allergenNameHe: 'חלב', severity: 'may_contain'),
        ],
      );
      expect(product.mayContainAllergens.length, 1);
      expect(product.mayContainAllergens.first.allergenId, '2');
    });

    test('default isKosher is false', () {
      final product = Product(id: '1', nameHe: 'Test');
      expect(product.isKosher, false);
    });

    test('default isArchived is false', () {
      final product = Product(id: '1', nameHe: 'Test');
      expect(product.isArchived, false);
    });

    test('default allergens is empty list', () {
      final product = Product(id: '1', nameHe: 'Test');
      expect(product.allergens, isEmpty);
      expect(product.containsAllergens, isEmpty);
      expect(product.mayContainAllergens, isEmpty);
    });
  });

  group('ProductAllergen', () {
    test('has correct properties', () {
      final productAllergen = ProductAllergen(
        allergenId: '1',
        allergenNameHe: 'גלוטן',
        severity: 'contains',
      );
      expect(productAllergen.allergenId, '1');
      expect(productAllergen.allergenNameHe, 'גלוטן');
      expect(productAllergen.severity, 'contains');
    });

    test('severityLevel parses known wire values', () {
      final contains = ProductAllergen(
          allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains');
      final mayContain = ProductAllergen(
          allergenId: '2', allergenNameHe: 'חלב', severity: 'may_contain');
      expect(contains.severityLevel, AllergenSeverity.contains);
      expect(mayContain.severityLevel, AllergenSeverity.mayContain);
    });

    test('severityLevel treats unknown severity fail-safe as contains', () {
      for (final raw in const ['trace', 'unknown', 'CONTAINS', '', 'typo']) {
        final pa = ProductAllergen(
            allergenId: '1', allergenNameHe: 'גלוטן', severity: raw);
        expect(pa.severityLevel, AllergenSeverity.contains,
            reason: 'severity "$raw" should resolve fail-safe to contains');
      }
    });
  });

  group('unknown severity safety hole (#105)', () {
    test('product with unknown severity is surfaced via containsAllergens', () {
      final product = Product(
        id: '1',
        nameHe: 'Test',
        allergens: [
          ProductAllergen(
              allergenId: '1', allergenNameHe: 'גלוטן', severity: 'trace'),
        ],
      );
      expect(product.containsAllergens.length, 1);
      expect(product.mayContainAllergens, isEmpty);
    });

    test('statusFor returns avoid for a selected unknown-severity allergen', () {
      final product = Product(
        id: '1',
        nameHe: 'Test',
        allergens: [
          ProductAllergen(
              allergenId: '1', allergenNameHe: 'גלוטן', severity: 'trace'),
        ],
      );
      const profile = UserProfile(selectedAllergenIds: {'1'});
      expect(profile.statusFor(product), AllergenStatus.avoid);
    });
  });
}