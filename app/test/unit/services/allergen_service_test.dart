import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';

void main() {
  group('AllergenService', () {
    test('Allergen model correctly parses from JSON', () {
      final json = {'id': '1', 'name_he': 'גלוטן', 'name_en': 'Gluten'};
      final allergen = Allergen.fromJson(json);
      
      expect(allergen.id, '1');
      expect(allergen.nameHe, 'גלוטן');
      expect(allergen.nameEn, 'Gluten');
    });

    test('allergens list can be mapped from response data', () {
      final data = [
        {'id': '1', 'name_he': 'גלוטן', 'name_en': 'Gluten'},
        {'id': '2', 'name_he': 'חלב', 'name_en': 'Milk'},
      ];
      
      final allergens = data
          .map((json) => Allergen.fromJson(json))
          .toList();
      
      expect(allergens.length, 2);
      expect(allergens[0].nameHe, 'גלוטן');
      expect(allergens[1].nameHe, 'חלב');
    });
  });
}