import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/brand.dart';

void main() {
  group('Brand', () {
    const fullJson = {
      'id': 'b1',
      'name': 'TestBrand',
      'logo_url': 'https://example.com/logo.png',
      'is_verified': true,
      'last_updated': '2026-01-01T00:00:00.000Z',
      'notes': 'some notes',
    };

    test('fromJson parses all fields', () {
      final brand = Brand.fromJson(fullJson);
      expect(brand.id, 'b1');
      expect(brand.name, 'TestBrand');
      expect(brand.logoUrl, 'https://example.com/logo.png');
      expect(brand.isVerified, true);
      expect(brand.lastUpdated, DateTime.utc(2026, 1, 1));
      expect(brand.notes, 'some notes');
    });

    test('fromJson handles missing optional fields', () {
      final brand = Brand.fromJson({'name': 'Minimal'});
      expect(brand.id, isNull);
      expect(brand.logoUrl, isNull);
      expect(brand.isVerified, false);
      expect(brand.lastUpdated, isNull);
      expect(brand.notes, isNull);
    });

    test('toJson omits id when null', () {
      const brand = Brand(name: 'NewBrand', isVerified: false);
      final json = brand.toJson();
      expect(json.containsKey('id'), false);
      expect(json['name'], 'NewBrand');
    });

    test('toJson includes id when set', () {
      const brand = Brand(id: 'abc', name: 'ExistingBrand');
      final json = brand.toJson();
      expect(json['id'], 'abc');
    });

    test('copyWith updates specified fields', () {
      const original = Brand(id: 'x', name: 'Original', isVerified: false);
      final copy = original.copyWith(name: 'Updated', isVerified: true);
      expect(copy.id, 'x');
      expect(copy.name, 'Updated');
      expect(copy.isVerified, true);
    });

    test('copyWith preserves unspecified fields', () {
      const original =
          Brand(id: 'x', name: 'A', logoUrl: 'https://img.com', notes: 'n');
      final copy = original.copyWith(name: 'B');
      expect(copy.logoUrl, 'https://img.com');
      expect(copy.notes, 'n');
    });
  });
}
