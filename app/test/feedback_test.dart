import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/screens/feedback_screen.dart';

void main() {
  testWidgets('User can submit feedback from product card', (tester) async {
    String? submittedType;
    String? submittedMessage;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FeedbackScreen(
        productId: 'p1',
        productName: 'חטיף בוטנים',
        onSubmit: (type, message) async {
          submittedType = type;
          submittedMessage = message;
        },
      ),
    ));

    expect(find.text('דווח בעיה'), findsOneWidget);
    expect(find.text('חטיף בוטנים'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'האלרגן חסר ברשימה');
    await tester.pumpAndSettle();

    await tester.tap(find.text('שלח דיווח'));
    await tester.pumpAndSettle();

    expect(submittedType, equals('other'));
    expect(submittedMessage, equals('האלרגן חסר ברשימה'));
  });

  testWidgets('Submit failure shows static error message, not raw exception',
      (tester) async {
    const leakedDetail = 'PostgrestException(code: 23505, internal-secret)';

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FeedbackScreen(
        productId: 'p1',
        productName: 'חטיף בוטנים',
        onSubmit: (_, _) async {
          throw Exception(leakedDetail);
        },
      ),
    ));

    await tester.enterText(find.byType(TextField), 'בדיקת כשל');
    await tester.pumpAndSettle();

    await tester.tap(find.text('שלח דיווח'));
    await tester.pumpAndSettle();

    expect(find.text('שגיאה בשליחת המשוב. נסה שנית.'), findsOneWidget);
    expect(find.textContaining(leakedDetail), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });
}
