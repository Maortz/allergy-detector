import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/screens/feedback_screen.dart';
import 'package:app/theme/app_theme.dart';

/// Minimal app wrapper — supplies MaterialApp + RTL locale.
Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

/// Default [FeedbackScreen] for tests — all optional fields null/no-op.
FeedbackScreen _defaultScreen({
  Future<void> Function(String type, String message, dynamic image)?
      onSubmit,
}) =>
    FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף בוטנים',
      productBarcode: '7290001234567',
      productImageUrl: null,
      onSubmit: onSubmit ??
          (type, message, image) async {},
    );

void main() {
  // ── Layout / rendering ───────────────────────────────────────────────────

  testWidgets('renders new AppBar title "דיווח על שגיאה"', (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    expect(find.text('דיווח על שגיאה'), findsOneWidget);
    // Old title must be gone
    expect(find.text('דווח בעיה'), findsNothing);
  });

  testWidgets('renders product context card with name and barcode',
      (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    expect(find.text('חטיף בוטנים'), findsOneWidget);
    expect(find.text('7290001234567'), findsOneWidget);
  });

  testWidgets('renders all four category chips', (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    expect(find.text('אלרגנים שגויים'), findsOneWidget);
    expect(find.text('רכיבים לא נכונים'), findsOneWidget);
    expect(find.text('תמונה לא תואמת'), findsOneWidget);
    expect(find.text('אחר'), findsOneWidget);
  });

  testWidgets('renders three section headings', (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    expect(find.text('מה הסיבה לדיווח?'), findsOneWidget);
    expect(find.text('פרטים נוספים (אופציונלי)'), findsOneWidget);
    expect(find.text('העלאת תמונה'), findsOneWidget);
  });

  testWidgets('renders photo upload zone with expected copy', (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    expect(find.text('צלם תמונה של תווית המוצר'), findsOneWidget);
  });

  testWidgets('renders submit button with updated label', (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    expect(find.text('שלח דיווח לבדיקה'), findsOneWidget);
    expect(find.text('שלח דיווח'), findsNothing);
  });

  testWidgets('renders secondary "ביטול" cancel button (#219 AC)',
      (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    final cancel = find.widgetWithText(OutlinedButton, 'ביטול');
    expect(cancel, findsOneWidget);
  });

  testWidgets('tapping "ביטול" pops the route without submitting',
      (tester) async {
    bool submitted = false;
    final screen = FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף',
      productBarcode: null,
      productImageUrl: null,
      onSubmit: (type, message, image) async => submitted = true,
    );

    // Push the screen so there is a route to pop.
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => screen),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('דיווח על שגיאה'), findsOneWidget);

    final cancel = find.widgetWithText(OutlinedButton, 'ביטול');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    // Route popped → back to the launcher, screen gone, nothing submitted.
    expect(find.text('דיווח על שגיאה'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(submitted, isFalse);
  });

  // ── Chip selection (radio-group) ─────────────────────────────────────────

  testWidgets('first chip "אלרגנים שגויים" is selected by default',
      (tester) async {
    await tester.pumpWidget(_wrap(_defaultScreen()));
    // The default chip key is allergens_wrong — verify by submitting without
    // tapping any chip and checking the type delivered to onSubmit.
    String? capturedType;
    await tester.pumpWidget(_wrap(FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף',
      productBarcode: null,
      productImageUrl: null,
      onSubmit: (type, message, image) async {
        capturedType = type;
      },
    )));
    await tester.ensureVisible(find.text('שלח דיווח לבדיקה'));
    await tester.tap(find.text('שלח דיווח לבדיקה'));
    await tester.pump();
    expect(capturedType, equals('allergens_wrong'));
  });

  testWidgets('tapping a chip changes the selected type', (tester) async {
    String? capturedType;
    await tester.pumpWidget(_wrap(FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף',
      productBarcode: null,
      productImageUrl: null,
      onSubmit: (type, message, image) async {
        capturedType = type;
      },
    )));
    await tester.tap(find.text('רכיבים לא נכונים'));
    await tester.pump();
    await tester.ensureVisible(find.text('שלח דיווח לבדיקה'));
    await tester.tap(find.text('שלח דיווח לבדיקה'));
    await tester.pump();
    expect(capturedType, equals('ingredients_wrong'));
  });

  // ── Details field is optional ─────────────────────────────────────────────

  testWidgets('submit succeeds with empty details field (field is optional)',
      (tester) async {
    bool submitted = false;
    await tester.pumpWidget(_wrap(FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף',
      productBarcode: null,
      productImageUrl: null,
      onSubmit: (type, message, image) async {
        submitted = true;
      },
    )));
    // Do NOT enter anything in the text field
    await tester.ensureVisible(find.text('שלח דיווח לבדיקה'));
    await tester.tap(find.text('שלח דיווח לבדיקה'));
    await tester.pump();
    expect(submitted, isTrue);
  });

  testWidgets('submit passes trimmed details when text is entered',
      (tester) async {
    String? capturedMessage;
    await tester.pumpWidget(_wrap(FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף',
      productBarcode: null,
      productImageUrl: null,
      onSubmit: (type, message, image) async {
        capturedMessage = message;
      },
    )));
    await tester.enterText(find.byType(TextField), '  האלרגן חסר ברשימה  ');
    await tester.ensureVisible(find.text('שלח דיווח לבדיקה'));
    await tester.tap(find.text('שלח דיווח לבדיקה'));
    await tester.pump();
    expect(capturedMessage, equals('האלרגן חסר ברשימה'));
  });

  // ── Error path ────────────────────────────────────────────────────────────

  testWidgets('submit failure shows static error snackbar, not raw exception',
      (tester) async {
    const leakedDetail = 'PostgrestException(code: 23505, internal-secret)';
    await tester.pumpWidget(_wrap(FeedbackScreen(
      productId: 'p1',
      productName: 'חטיף',
      productBarcode: null,
      productImageUrl: null,
      onSubmit: (type, msg, img) async => throw Exception(leakedDetail),
    )));
    await tester.ensureVisible(find.text('שלח דיווח לבדיקה'));
    await tester.tap(find.text('שלח דיווח לבדיקה'));
    await tester.pump(); // start async
    await tester.pump(const Duration(milliseconds: 100)); // settle snackbar
    expect(find.text('שגיאה בשליחת המשוב. נסה שנית.'), findsOneWidget);
    expect(find.textContaining(leakedDetail), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });

  // ── Dark mode (#290) ─────────────────────────────────────────────────────

  testWidgets('renders under the dark theme without exception (#290)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(_defaultScreen(), theme: buildDarkAppTheme()),
    );
    // No paint/layout exception under dark mode after the theme-aware migration.
    expect(tester.takeException(), isNull);
    // Core content still renders.
    expect(find.text('דיווח על שגיאה'), findsOneWidget);
    expect(find.text('שלח דיווח לבדיקה'), findsOneWidget);
  });
}
