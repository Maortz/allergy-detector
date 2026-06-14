import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/scan_instructions_screen.dart';

void main() {
  group('ScanInstructionsScreen', () {
    testWidgets('renders the app-bar title, intro and numbered steps',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScanInstructionsScreen()));

      expect(find.text('הוראות סריקה'), findsOneWidget);
      expect(find.text('איך לסרוק מוצר'), findsOneWidget);
      // Step headings (static content from spec §7.3).
      expect(find.text('פתח את לשונית הסריקה'), findsOneWidget);
      expect(find.text('מקם את הברקוד במסגרת'), findsOneWidget);
      expect(find.text('המתן לקריאה אוטומטית'), findsOneWidget);
      expect(find.text('תאורה לא טובה?'), findsOneWidget);
      // Step ordinals render.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('lays out under RTL directionality', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScanInstructionsScreen()));

      // The screen wraps its Scaffold in an RTL Directionality.
      final dir = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.byType(Scaffold),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(dir.textDirection, TextDirection.rtl);
    });
  });
}
