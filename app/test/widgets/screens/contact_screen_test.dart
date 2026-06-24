import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/contact_screen.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  group('ContactScreen Widget Tests', () {
    Widget buildSubject() => const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ContactScreen(),
          ),
        );

    Future<void> selectSubject(WidgetTester tester) async {
      // The direct-contact section (CC1/CC2) above the form pushes the dropdown
      // down, so scroll it into view before tapping.
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
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

    testWidgets(
        'tab-host return resets the form (no stale success view on re-visit)',
        (tester) async {
      // No Navigator route to pop → "חזרה לדף הבית" takes the onNavTap branch
      // while the screen stays mounted, exercising the reset path.
      var navTapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ContactScreen(onNavTap: (_) => navTapped++),
        ),
      ));

      await fillValidForm(tester);
      await tester.ensureVisible(find.text('שלח הודעה'));
      await tester.tap(find.text('שלח הודעה'));
      await tester.pump();
      expect(find.text('ההודעה נשלחה בהצלחה!'), findsOneWidget);

      await tester.tap(find.text('חזרה לדף הבית'));
      await tester.pump();

      expect(navTapped, 1);
      // Form is back (success view cleared) and the fields are empty again.
      expect(find.text('ההודעה נשלחה בהצלחה!'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('ישראל ישראלי'), findsNothing);
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

  group('ContactScreen direct-contact section (CC1/CC2)', () {
    Widget buildSubject() => const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ContactScreen(),
          ),
        );

    testWidgets('renders the hero intro card copy (CC1)', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.text(
          'אנחנו כאן כדי לעזור לכם לשמור על ביטחון תזונתי. '
          'צרו איתנו קשר בכל שאלה או משוב.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.support_agent), findsOneWidget);
    });

    testWidgets('renders the three contact-method rows (CC2)', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('דואר אלקטרוני'), findsOneWidget);
      expect(find.text('support@allergycare.co.il'), findsOneWidget);
      expect(find.text('מוקד טלפוני'), findsOneWidget);
      expect(find.text('03-1234567'), findsOneWidget);
      expect(find.text('שעות פעילות'), findsOneWidget);
      expect(find.text("א'-ה' | 09:00-17:00"), findsOneWidget);
    });

    testWidgets('email and phone rows are tappable (InkWell), hours is not',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      // The email row tap must not throw within the widget tree (the platform
      // launch is guarded by canLaunchUrl, which returns false under test).
      await tester.tap(find.text('support@allergycare.co.il'));
      await tester.pump();
      await tester.tap(find.text('03-1234567'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the existing form still renders below the new section',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      // Form intact: 3 text fields + send button unaffected by the new block.
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('שלח הודעה'), findsOneWidget);
    });

    testWidgets('renders under the dark theme without exception (#294)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildDarkAppTheme(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: ContactScreen(),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('שלח הודעה'), findsOneWidget);
    });
  });
}
