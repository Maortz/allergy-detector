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

    Future<void> selectSubject(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('תמיכה טכנית').last);
      await tester.pumpAndSettle();
    }

    Future<void> fillValidForm(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ישראל ישראלי');
      await tester.enterText(fields.at(1), 'israel@example.com');
      // Message is the last TextFormField (the subject is a Dropdown).
      await tester.enterText(fields.last, 'שלום, יש לי שאלה');
      await tester.pump();
      await selectSubject(tester);
    }

    testWidgets('does not claim success on submit (no backend yet)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await fillValidForm(tester);

      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();

      expect(find.text('ההודעה נשלחה בהצלחה!'), findsNothing);
      expect(find.text('בקרוב — שליחת הודעות תתאפשר בעדכון הבא'), findsOneWidget);
    });

    testWidgets('shows validation errors and no toast when form is empty', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();

      expect(find.text('נא להזין שם'), findsOneWidget);
      expect(find.text('בקרוב — שליחת הודעות תתאפשר בעדכון הבא'), findsNothing);
    });

    testWidgets('requires a subject before submitting', (tester) async {
      await tester.pumpWidget(buildSubject());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ישראל ישראלי');
      await tester.enterText(fields.at(1), 'israel@example.com');
      await tester.enterText(fields.last, 'שלום, יש לי שאלה');
      await tester.pump();

      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();

      expect(find.text('נא לבחור נושא'), findsOneWidget);
      expect(find.text('בקרוב — שליחת הודעות תתאפשר בעדכון הבא'), findsNothing);
    });
  });
}
