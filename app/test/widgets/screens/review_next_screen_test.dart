import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/review_next_screen.dart';
import 'package:app/widgets/skeleton_box.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ReviewQueueItem fakeItem({bool isFavourited = false}) => ReviewQueueItem(
        id: 'item-1',
        name: 'חלב שקדים אורגני',
        categoryLabel: 'משקאות צמחיים',
        description: 'מוצר זה ממתין לאימות קהילה.',
        imageUrl: '',
        alertLabel: 'חשד לאלרגנים',
        isFavourited: isFavourited,
      );

  Widget buildSubject({
    ReviewQueueItem? nextItem,
    int pointsEarned = 15,
    int newWeeklyRank = 42,
    bool isLoading = false,
    VoidCallback? onCheckNow,
    VoidCallback? onSkip,
    VoidCallback? onGoHome,
  }) =>
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ReviewNextScreen(
            pointsEarned: pointsEarned,
            newWeeklyRank: newWeeklyRank,
            nextItem: nextItem ?? fakeItem(),
            isLoading: isLoading,
            onCheckNow: onCheckNow,
            onSkip: onSkip,
            onGoHome: onGoHome,
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // RN1 — success hero
  // ---------------------------------------------------------------------------

  group('RN1 — success hero', () {
    testWidgets('shows "תודה על תרומתך!" heading', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('תודה על תרומתך!'), findsOneWidget);
    });

    testWidgets('hero section contains a filled check_circle icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('body paragraph present', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.textContaining('הביקורת שלך עוזרת'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RN2 / RN3 — gamification bento
  // ---------------------------------------------------------------------------

  group('RN2/RN3 — gamification bento', () {
    testWidgets('shows points value "+15"', (tester) async {
      await tester.pumpWidget(buildSubject(pointsEarned: 15));
      expect(find.text('+15'), findsOneWidget);
    });

    testWidgets('shows rank value "#42"', (tester) async {
      await tester.pumpWidget(buildSubject(newWeeklyRank: 42));
      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('shows "נקודות קהילה" label', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('נקודות קהילה'), findsOneWidget);
    });

    testWidgets('shows "דירוג שבועי" label', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('דירוג שבועי'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // RN4 — section header + inline "דלג" text button
  // ---------------------------------------------------------------------------

  group('RN4 — section header and inline skip', () {
    testWidgets('shows "המוצר הבא לבדיקה" section heading', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('המוצר הבא לבדיקה'), findsOneWidget);
    });

    testWidgets('"דלג" is a TextButton (not OutlinedButton)', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Should find a TextButton containing "דלג"
      expect(find.widgetWithText(TextButton, 'דלג'), findsOneWidget);
      // Must NOT render as OutlinedButton
      expect(find.widgetWithText(OutlinedButton, 'דלג'), findsNothing);
    });

    testWidgets('"דלג" tap fires onSkip callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onSkip: () => tapped = true));
      await tester.ensureVisible(find.widgetWithText(TextButton, 'דלג'));
      await tester.tap(find.widgetWithText(TextButton, 'דלג'));
      expect(tapped, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // RN5 / RN6 / RN7 — product card hero + overlay badge + meta
  // ---------------------------------------------------------------------------

  group('RN5–RN7 — product card', () {
    testWidgets('product name is displayed', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('חלב שקדים אורגני'), findsOneWidget);
    });

    testWidgets('category label is displayed', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('משקאות צמחיים'), findsOneWidget);
    });

    testWidgets('"חשד לאלרגנים" overlay badge text is shown', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('חשד לאלרגנים'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // RN8 — "בדוק עכשיו" has chevron_left icon; favourite icon button present
  // ---------------------------------------------------------------------------

  group('RN8 — action row', () {
    testWidgets('"בדוק עכשיו" button includes chevron_left icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      final btnFinder = find.widgetWithText(FilledButton, 'בדוק עכשיו');
      expect(btnFinder, findsOneWidget);
      // Icon must be inside the button's subtree
      final iconFinder = find.descendant(
        of: btnFinder,
        matching: find.byIcon(Icons.chevron_left),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('favourite icon button is present (outlined at rest)',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('favourite icon button toggles to filled on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.ensureVisible(find.byIcon(Icons.favorite_border));
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('"בדוק עכשיו" tap fires onCheckNow', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
          buildSubject(onCheckNow: () => tapped = true));
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'בדוק עכשיו'));
      await tester.tap(find.widgetWithText(FilledButton, 'בדוק עכשיו'));
      expect(tapped, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // RN9 — "חזרה לדף הבית" ghost button
  // ---------------------------------------------------------------------------

  group('RN9 — home ghost button', () {
    testWidgets('"חזרה לדף הבית" ghost button is present', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('חזרה לדף הבית'), findsOneWidget);
    });

    testWidgets('"חזרה לדף הבית" tap fires onGoHome', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onGoHome: () => tapped = true));
      await tester.ensureVisible(find.text('חזרה לדף הבית'));
      await tester.tap(find.text('חזרה לדף הבית'));
      expect(tapped, isTrue);
    });

    testWidgets('"חזרה לדף הבית" has leading home icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // RN10 — bottom nav suppressed
  // ---------------------------------------------------------------------------

  group('RN10 — bottom nav suppressed', () {
    testWidgets('BottomNavigationBar is NOT rendered', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // RN12 — loading / skeleton state
  // ---------------------------------------------------------------------------

  group('RN12 — loading skeleton', () {
    testWidgets('isLoading renders SkeletonBox widgets', (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: true));
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });

    testWidgets('isLoading disables "בדוק עכשיו"', (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: true));
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'בדוק עכשיו'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('success hero always shows even when loading', (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: true));
      expect(find.text('תודה על תרומתך!'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // RN11 — dynamic data (no hardcoded mock text)
  // ---------------------------------------------------------------------------

  group('RN11 — dynamic data', () {
    testWidgets('renders the nextItem name passed in', (tester) async {
      final item = ReviewQueueItem(
        id: 'x',
        name: 'ביסלי גריל',
        categoryLabel: 'חטיפים',
        description: 'חטיף פריך.',
        imageUrl: '',
        alertLabel: 'חשד לאלרגנים',
        isFavourited: false,
      );
      await tester.pumpWidget(buildSubject(nextItem: item));
      expect(find.text('ביסלי גריל'), findsOneWidget);
    });

    testWidgets('hardcoded "חטיף שוקולד חלבי" mock is gone', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('חטיף שוקולד חלבי'), findsNothing);
    });
  });
}
