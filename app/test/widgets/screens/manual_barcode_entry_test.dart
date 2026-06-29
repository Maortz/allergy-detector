import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/search_scan_screen.dart';

void main() {
  group('ManualBarcodeEntry (#323)', () {
    // Mirror production: the screen renders this inside a scroll view, so the
    // full-width AspectRatio square has unbounded vertical space.
    Widget host(ValueChanged<String> onSubmitted) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManualBarcodeEntry(onSubmitted: onSubmitted),
            ),
          ),
        );

    testWidgets('restricts input to digits only', (tester) async {
      await tester.pumpWidget(host((_) {}));

      await tester.enterText(find.byType(TextField), 'a1b2-3c');
      await tester.pump();

      // Letters and symbols are stripped by FilteringTextInputFormatter.
      expect(find.text('123'), findsOneWidget);
    });

    testWidgets('constrains the field width to the design-system max',
        (tester) async {
      await tester.pumpWidget(host((_) {}));

      final box = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(box.constraints.maxWidth, ManualBarcodeEntry.maxFieldWidth);
    });

    testWidgets('submits the trimmed entered barcode', (tester) async {
      String? submitted;
      await tester.pumpWidget(host((v) => submitted = v));

      await tester.enterText(find.byType(TextField), '7290000000001');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(submitted, '7290000000001');
    });
  });
}
