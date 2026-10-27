import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.isTwoColumn (#410)', () {
    test('threshold value is 600', () {
      expect(AppBreakpoints.twoColumn, 600);
    });
    test('600 belongs to the wide bucket (inclusive)', () {
      expect(AppBreakpoints.isTwoColumn(600), isTrue);
    });
    test('599.9 and 599 stay single-column', () {
      expect(AppBreakpoints.isTwoColumn(599.9), isFalse);
      expect(AppBreakpoints.isTwoColumn(599), isFalse);
    });
    test('phone and desktop widths', () {
      expect(AppBreakpoints.isTwoColumn(390), isFalse);
      expect(AppBreakpoints.isTwoColumn(1920), isTrue);
    });
  });
}
