import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Test', () {
    testWidgets('app launches without error', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp).evaluate().isNotEmpty, isTrue);
    });
  });
}
