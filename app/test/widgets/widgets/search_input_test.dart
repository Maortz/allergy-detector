import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/search_input.dart';

void main() {
  group('SearchInput', () {
    testWidgets('displays default Hebrew hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchInput(),
          ),
        ),
      );

      expect(find.text('חפש מוצר או מרכיב...'), findsOneWidget);
    });

    testWidgets('displays custom hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchInput(hintText: 'חפש שם...'),
          ),
        ),
      );

      expect(find.text('חפש שם...'), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchInput(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      String searchText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchInput(
              onChanged: (value) => searchText = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'חלב');
      await tester.pump();

      expect(searchText, 'חלב');
    });

    testWidgets('accepts external controller', (tester) async {
      final controller = TextEditingController(text: 'initial text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchInput(controller: controller),
          ),
        ),
      );

      expect(find.text('initial text'), findsOneWidget);
    });

    testWidgets('text field is right-aligned for Hebrew', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchInput(),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textAlign, TextAlign.right);
    });
  });
}