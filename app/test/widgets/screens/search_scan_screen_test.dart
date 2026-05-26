import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/search_scan_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/services/scanner_service.dart';
import 'package:app/theme/app_colors.dart';
import '../../helpers/test_fixtures.dart';

class _DeniedScannerService extends ScannerService {
  @override
  Future<void> initialize() async => throw Exception('camera permission denied');
}

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
      List<RecentScan>? recentScans,
      ScannerService? scannerService,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SearchScanScreen(
            userProfile: testProfile,
            allergens: testAllergens,
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            recentScans: recentScans,
            scannerService: scannerService,
          ),
        ),
      );
    }

    testWidgets('displays search input with Hebrew hint', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('חפש מוצר או מרכיב...'), findsOneWidget);
    });

    testWidgets('displays barcode scanning section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקת ברקוד'), findsOneWidget);
      expect(find.text('הצמד את הברקוד למצלמה'), findsOneWidget);
    });

    testWidgets('displays recent scans section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נסרק לאחרונה'), findsOneWidget);
      expect(find.text('חלב שולו 5%'), findsOneWidget);
      expect(find.text('שולו'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no recent scans', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(recentScans: const []));

      expect(find.text('אין סריקות אחרונות'), findsOneWidget);
      expect(find.text('חלב שולו 5%'), findsNothing);
    });

    testWidgets('shows camera-denied state when the scanner fails to init',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(scannerService: _DeniedScannerService()),
      );
      await tester.pump(); // let _initScanner reject + rebuild

      expect(find.text('הסורק אינו זמין'), findsOneWidget);
      expect(find.text('הצמד את הברקוד למצלמה'), findsNothing);
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

    testWidgets(
        'scan-frame laser uses AppColors.scanFrame, not Colors.red',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final laserContainers =
          tester.widgetList<Container>(find.byType(Container)).where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.scanFrame;
      });
      expect(laserContainers, isNotEmpty,
          reason:
              'Laser line must use AppColors.scanFrame (#1A8CF8), not Colors.red (spec SS2).');

      final redContainers =
          tester.widgetList<Container>(find.byType(Container)).where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == Colors.red;
      });
      expect(redContainers, isEmpty,
          reason: 'No scanner Container should still render Colors.red.');
    });
  });
}