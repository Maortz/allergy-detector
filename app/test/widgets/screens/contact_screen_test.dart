import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/contact_screen.dart';

void main() {
  group('ContactScreen Widget Tests', () {
    Widget buildSubject() => const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ContactScreen(),
          ),
        );

    Future<void> fillValidForm(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ישראל ישראלי');
      await tester.enterText(fields.at(1), 'israel@example.com');
      await tester.enterText(fields.at(2), 'שלום, יש לי שאלה');
      await tester.pump();
    }

    testWidgets(
        'shows in-place success state on valid submit (contact-us.md §5.5)',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await fillValidForm(tester);

      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();

      expect(find.text('ההודעה נשלחה בהצלחה!'), findsOneWidget);
      expect(find.text('נחזור אליכם בהקדם האפשרי.'), findsOneWidget);
      // Form fields are gone — replaced by the success view.
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('shows validation errors and stays on the form when empty',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();

      expect(find.text('נא להזין שם'), findsOneWidget);
      // Did NOT transition to the success view.
      expect(find.text('ההודעה נשלחה בהצלחה!'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });
  });
}
