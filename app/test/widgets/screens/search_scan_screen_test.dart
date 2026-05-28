import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/screens/search_scan_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';

// A no-op [MobileScanner] replacement for tests: renders an empty box and
// never starts camera hardware.  The errorBuilder is still wired up so tests
// can call it directly to drive the _cameraDenied path.
Widget _noOpMobileScannerBuilder(
  MobileScannerController controller,
  Widget Function(BuildContext, MobileScannerException) errorBuilder,
) =>
    const SizedBox.shrink();

void main() {
  group('SearchScanScreen Widget Tests', () {
    late UserProfile testProfile;
    late List<Allergen> testAllergens;

    setUp(() {
      testProfile = TestFixtures.sampleProfile;
      testAllergens = TestFixtures.sampleAllergens;
    });

    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SearchScanScreen(
            userProfile: testProfile,
            allergens: testAllergens,
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            mobileScannerBuilder: _noOpMobileScannerBuilder,
          ),
        ),
      );
    }

    testWidgets('displays search input with Hebrew hint', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('חפש מוצר או מרכיב...'), findsOneWidget);
    });

    testWidgets('displays barcode scanning section with Hebrew text',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקת ברקוד'), findsOneWidget);
      expect(find.text('הצמד את הברקוד למצלמה'), findsOneWidget);
    });

    testWidgets('displays recent scans section with Hebrew text',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נסרק לארכונה'), findsOneWidget);
      expect(find.text('חלב שולו 5%'), findsOneWidget);
      expect(find.text('שולו'), findsOneWidget);
    });

    testWidgets('displays safety tip section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('טיפ בטיחות'), findsOneWidget);
    });

    testWidgets('search input accepts text input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'חלב');
      await tester.pump();

      expect(find.text('חלב'), findsOneWidget);
    });

    // -------------------------------------------------------------------
    // Camera-permission-denied path (issue #52)
    // -------------------------------------------------------------------

    testWidgets(
        'onScannerError with permissionDenied replaces viewfinder with '
        'permission-denied UI', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify normal scanner section is visible before the error.
      expect(find.text('סריקת ברקוד'), findsOneWidget);
      expect(find.text('גישה למצלמה נדחתה'), findsNothing);

      // Simulate the real denial path: obtain the state and call
      // onScannerError exactly as MobileScanner.errorBuilder would in prod.
      final state = tester.state<SearchScanScreenState>(
        find.byType(SearchScanScreen),
      );
      state.onScannerError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      await tester.pump();

      // The scanner section must now show the permission-denied widget.
      expect(find.text('גישה למצלמה נדחתה'), findsOneWidget);
      expect(find.text('כדי לסרוק ברקודים יש לאפשר גישה למצלמה בהגדרות המכשיר.'),
          findsOneWidget);
      // Normal scanner heading is gone.
      expect(find.text('סריקת ברקוד'), findsNothing);
    });

    testWidgets('onScannerError with non-permission error does NOT set cameraDenied',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final state = tester.state<SearchScanScreenState>(
        find.byType(SearchScanScreen),
      );
      state.onScannerError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );
      await tester.pump();

      // Generic errors do not switch to the permission-denied screen.
      expect(state.cameraDenied, isFalse);
      expect(find.text('גישה למצלמה נדחתה'), findsNothing);
      expect(find.text('סריקת ברקוד'), findsOneWidget);
    });

    testWidgets('onScannerError is idempotent — calling twice stays denied',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final state = tester.state<SearchScanScreenState>(
        find.byType(SearchScanScreen),
      );
      const err = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      state.onScannerError(err);
      await tester.pump();
      expect(state.cameraDenied, isTrue);

      // Second call must not throw or double-setState.
      state.onScannerError(err);
      await tester.pump();
      expect(state.cameraDenied, isTrue);
    });
  });
}
