import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/validators.dart';

void main() {
  group('Validators.isValidEmail', () {
    test('accepts well-formed addresses', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('a.b+tag@sub.domain.co.il'), isTrue);
      expect(Validators.isValidEmail('  trimmed@example.com  '), isTrue);
    });

    test('rejects the strings the old contains("@") check let through', () {
      expect(Validators.isValidEmail('@'), isFalse);
      expect(Validators.isValidEmail('foo@'), isFalse);
      expect(Validators.isValidEmail('@bar'), isFalse);
      expect(Validators.isValidEmail('foo@bar'), isFalse); // no TLD
    });

    test('rejects other malformed inputs', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('plainaddress'), isFalse);
      expect(Validators.isValidEmail('a@b@example.com'), isFalse);
      expect(Validators.isValidEmail('a b@example.com'), isFalse);
      expect(Validators.isValidEmail('user@example.'), isFalse);
    });
  });
}
