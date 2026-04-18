import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Full Flow Test', () {
    testWidgets('app starts without crashing', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp).evaluate().isNotEmpty, isTrue);
    });
  });
}
