import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/profile_service.dart';

void main() {
  group('ProfileService.parseIsAdmin', () {
    test('returns true when the row carries is_admin == true', () {
      expect(ProfileService.parseIsAdmin({'is_admin': true}), isTrue);
    });

    test('returns false when the row carries is_admin == false', () {
      expect(ProfileService.parseIsAdmin({'is_admin': false}), isFalse);
    });

    test('defaults to false for a null row (no profile / read failed)', () {
      expect(ProfileService.parseIsAdmin(null), isFalse);
    });

    test('defaults to false when the is_admin key is absent', () {
      expect(ProfileService.parseIsAdmin(<String, dynamic>{}), isFalse);
    });

    test('defaults to false for a non-bool is_admin value', () {
      expect(ProfileService.parseIsAdmin({'is_admin': 'true'}), isFalse);
    });
  });
}
