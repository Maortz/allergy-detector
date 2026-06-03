import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/screens/search_scan_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';

// A no-op [MobileScanner] replacement for tests: renders an empty box and
// never starts camera hardware.  The builder ignores both parameters; tests
// drive the denial path by calling `state.onScannerError()` directly.
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
      // The instruction overlay only shows over the black placeholder
      // (controller == null). With a live controller it is hidden so it
      // isn't stamped over the viewfinder.
      expect(find.text('הצמד את הברקוד למצלמה'), findsNothing);
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
      // Two pumps: the setState is deferred to a post-frame callback (mirrors
      // production, where errorBuilder runs during MobileScanner's build).
      await tester.pump();
      await tester.pump();

      // The scanner section must now show the permission-denied widget.
      expect(find.text('גישה למצלמה נדחתה'), findsOneWidget);
      expect(find.text('כדי לסרוק ברקודים יש לאפשר גישה למצלמה בהגדרות המכשיר.'),
          findsOneWidget);
      // Normal scanner heading is gone.
      expect(find.text('סריקת ברקוד'), findsNothing);
    });

    testWidgets('onScannerError with non-permission error keeps the viewfinder',
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
      await tester.pump();

      // Generic errors do not switch to the permission-denied screen.
      // The rendered UI is the ground truth (no internal-state read needed).
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
      await tester.pump();
      expect(find.text('גישה למצלמה נדחתה'), findsOneWidget);

      // Second call must not throw or double-setState.
      state.onScannerError(err);
      await tester.pump();
      await tester.pump();
      expect(find.text('גישה למצלמה נדחתה'), findsOneWidget);
    });

    testWidgets('retry button clears the denied state and restores viewfinder',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final state = tester.state<SearchScanScreenState>(
        find.byType(SearchScanScreen),
      );
      state.onScannerError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('גישה למצלמה נדחתה'), findsOneWidget);

      // Tapping "נסה שוב" re-initialises the scanner and clears the denied UI.
      await tester.tap(find.text('נסה שוב'));
      await tester.pump();

      expect(find.text('גישה למצלמה נדחתה'), findsNothing);
      expect(find.text('סריקת ברקוד'), findsOneWidget);
    });
  });
}
