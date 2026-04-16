import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App boots and shows search', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('גלאי אלרגנים'), findsOneWidget);
    expect(find.text('חפש מוצר'), findsOneWidget);
  });
}
