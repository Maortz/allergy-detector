import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/grid_layout.dart';

void main() {
  group('allergenGridColumns', () {
    test('keeps 3 columns on phone widths (Android unchanged, #335)', () {
      expect(allergenGridColumns(320), 3);
      expect(allergenGridColumns(360), 3);
      expect(allergenGridColumns(412), 3);
      expect(allergenGridColumns(480), 3);
    });

    test('adds columns on tablet/web widths', () {
      expect(allergenGridColumns(768), greaterThan(3));
      expect(allergenGridColumns(1024), greaterThan(allergenGridColumns(768)));
    });

    test('never exceeds 8 columns on very wide viewports', () {
      expect(allergenGridColumns(2000), 8);
      expect(allergenGridColumns(4000), 8);
    });
  });
}
