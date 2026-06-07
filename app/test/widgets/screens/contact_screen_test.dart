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

    testWidgets('shows format error for invalid email and no toast', (tester) async {
      await tester.pumpWidget(buildSubject());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ישראל ישראלי');
      await tester.enterText(fields.at(1), 'foo@'); // passes old contains('@') guard, fails regex
      await tester.enterText(fields.at(2), 'הודעה');
      await tester.pump();

      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();

      expect(find.text('נא להזין כתובת דוא"ל תקינה'), findsOneWidget);
      expect(find.text('בקרוב — שליחת הודעות תתאפשר בעדכון הבא'), findsNothing);
    });
  });
}
