import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';

void main() {
  group('Allergen', () {
    test('has correct properties', () {
      const allergen = Allergen(id: '1', nameHe: 'גלוטן', nameEn: 'Gluten');
      expect(allergen.id, '1');
      expect(allergen.nameHe, 'גלוטן');
      expect(allergen.nameEn, 'Gluten');
    });

    test('fromJson creates instance correctly', () {
      final json = {'id': '2', 'name_he': 'חלב', 'name_en': 'Milk'};
      final allergen = Allergen.fromJson(json);
      expect(allergen.id, '2');
      expect(allergen.nameHe, 'חלב');
      expect(allergen.nameEn, 'Milk');
    });

    test('fromJson handles null optional fields', () {
      final json = {'id': '3', 'name_he': 'בוטנים'};
      final allergen = Allergen.fromJson(json);
      expect(allergen.id, '3');
      expect(allergen.nameHe, 'בוטנים');
      expect(allergen.nameEn, isNull);
      expect(allergen.iconUrl, isNull);
      expect(allergen.emoji, isNull);
    });

    test('AllergenStatus enum has three values', () {
      expect(AllergenStatus.values.length, 3);
      expect(AllergenStatus.values.contains(AllergenStatus.safe), true);
      expect(AllergenStatus.values.contains(AllergenStatus.caution), true);
      expect(AllergenStatus.values.contains(AllergenStatus.avoid), true);
    });
  });
}