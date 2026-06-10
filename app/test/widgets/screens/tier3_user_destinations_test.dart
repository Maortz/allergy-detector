import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/screens/scan_history_screen.dart';
import 'package:app/screens/saved_products_screen.dart';
import 'package:app/screens/my_reviews_screen.dart';
import 'package:app/screens/help_center_screen.dart';
import 'package:app/screens/about_screen.dart';
import 'package:app/screens/app_preferences_screen.dart';
import 'package:app/screens/contribution_history_screen.dart';
import 'package:app/screens/help_tips_screen.dart';
import 'package:app/screens/scan_instructions_screen.dart';
import 'package:app/screens/active_discussion_screen.dart';
import 'package:app/screens/weekly_tip_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('ScanHistoryScreen', () {
    testWidgets('renders title and empty-state copy', (tester) async {
      // History is loaded async from ScanHistoryService (SharedPreferences);
      // an empty store resolves to the no-scans empty state.
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_wrap(const ScanHistoryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('היסטוריית סריקה'), findsOneWidget);
      expect(find.text('אין סריקות עדיין'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('SavedProductsScreen', () {
    testWidgets('renders title and empty-state copy', (tester) async {
      await tester.pumpWidget(_wrap(const SavedProductsScreen()));
      expect(find.text('מוצרים שמורים'), findsOneWidget);
      expect(find.text('אין מוצרים שמורים'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });
  });

  group('MyReviewsScreen', () {
    testWidgets('renders title and empty-state copy', (tester) async {
      await tester.pumpWidget(_wrap(const MyReviewsScreen()));
      expect(find.text('ביקורות שלי'), findsOneWidget);
      expect(find.text('עדיין לא כתבת ביקורות'), findsOneWidget);
    });
  });

  group('HelpCenterScreen', () {
    testWidgets('renders FAQ section and questions', (tester) async {
      await tester.pumpWidget(_wrap(const HelpCenterScreen()));
      expect(find.text('מרכז עזרה'), findsOneWidget);
      expect(find.text('שאלות נפוצות'), findsOneWidget);
      expect(find.text('איך סורקים מוצר?'), findsOneWidget);
    });

    testWidgets('expanding a question reveals its answer', (tester) async {
      await tester.pumpWidget(_wrap(const HelpCenterScreen()));
      expect(
        find.textContaining('פתח את לשונית הסריקה'),
        findsNothing,
      );
      await tester.tap(find.text('איך סורקים מוצר?'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('פתח את לשונית הסריקה'),
        findsOneWidget,
      );
    });

    testWidgets('contact button calls onContactTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(HelpCenterScreen(onContactTap: () => tapped = true)),
      );
      await tester.tap(find.text('פנה אלינו'));
      expect(tapped, isTrue);
    });
  });

  group('AboutScreen', () {
    testWidgets('renders app name, version and sections', (tester) async {
      await tester.pumpWidget(_wrap(const AboutScreen()));
      expect(find.text('אודות'), findsOneWidget);
      expect(find.text(AboutScreen.appName), findsOneWidget);
      expect(
        find.text('גרסה ${AboutScreen.appVersion}'),
        findsOneWidget,
      );
      expect(find.text('אודות האפליקציה'), findsOneWidget);
      expect(find.text('הצהרת אחריות'), findsOneWidget);
    });
  });

  group('AppPreferencesScreen', () {
    testWidgets('renders section headings', (tester) async {
      await tester.pumpWidget(_wrap(const AppPreferencesScreen()));
      expect(find.text('העדפות אפליקציה'), findsOneWidget);
      expect(find.text('הצגה'), findsOneWidget);
      expect(find.text('התראות'), findsOneWidget);
      expect(find.text('נתונים'), findsOneWidget);
    });
  });

  group('ContributionHistoryScreen', () {
    testWidgets('renders title and empty-state copy', (tester) async {
      await tester.pumpWidget(_wrap(const ContributionHistoryScreen()));
      expect(find.text('היסטוריית תרומות'), findsOneWidget);
      expect(find.text('עדיין לא תרמת לקהילה'), findsOneWidget);
      expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
    });
  });

  group('HelpTipsScreen', () {
    testWidgets('renders title and tip headings', (tester) async {
      await tester.pumpWidget(_wrap(const HelpTipsScreen()));
      expect(find.text('טיפים לבטיחות'), findsOneWidget);
      expect(
        find.text('בדוק תמיד את רשימת הרכיבים המלאה'),
        findsOneWidget,
      );
    });
  });

  group('ScanInstructionsScreen', () {
    testWidgets('renders title and numbered steps', (tester) async {
      await tester.pumpWidget(_wrap(const ScanInstructionsScreen()));
      expect(find.text('הוראות סריקה'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('פתח את לשונית הסריקה'), findsOneWidget);
    });
  });

  group('ActiveDiscussionScreen', () {
    testWidgets('renders title and badge', (tester) async {
      await tester.pumpWidget(_wrap(const ActiveDiscussionScreen()));
      expect(find.text('דיון פעיל'), findsNWidgets(2));
      expect(
        find.textContaining('תחליפי חלב חדשים'),
        findsOneWidget,
      );
    });
  });

  group('WeeklyTipScreen', () {
    testWidgets('renders title and bullets', (tester) async {
      await tester.pumpWidget(_wrap(const WeeklyTipScreen()));
      expect(find.text('טיפ השבוע'), findsNWidgets(2));
      expect(
        find.textContaining('איך לקרוא תוויות'),
        findsOneWidget,
      );
    });
  });
}
