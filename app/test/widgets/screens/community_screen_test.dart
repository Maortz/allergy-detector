import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/screens/community_review_screen.dart';
import 'package:app/screens/community_screen.dart';
import 'package:app/screens/review_all_clear_screen.dart';
import 'package:app/services/community_review_controller.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/widgets/skeleton_box.dart';
import 'package:app/widgets/stat_card.dart';

/// A [CommunityReviewController] whose queue fetch always throws, simulating a
/// Supabase network failure during `ReviewQueueService.loadQueue()` (issue
/// #354). The injected [SupabaseClient] is never hit because [fetchPending] is
/// overridden to throw before any REST call.
class _ThrowingReviewController extends CommunityReviewController {
  _ThrowingReviewController()
      : super(SupabaseClient(
          'https://example.com',
          'anon-key',
          // Disable GoTrue's periodic token auto-refresh — otherwise the real
          // client leaves a 10s pending Timer that fails the binding's
          // no-pending-timers teardown invariant.
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ));

  @override
  Future<List<PendingReview>> fetchPending(List<Allergen> allergens) async {
    throw Exception('network down');
  }
}

void main() {
  group('CommunityScreen Widget Tests', () {
    Widget createWidgetUnderTest({
      int navIndex = 0,
      ValueChanged<int>? onNavIndexChanged,
      VoidCallback? onStartReview,
      List<PendingReview>? pendingReviews,
      bool isLoading = false,
      bool hasError = false,
      VoidCallback? onRetry,
      int? verifiedCount,
      int? addedCount,
      VoidCallback? onReviewCompleted,
      ThemeData? theme,
    }) {
      return MaterialApp(
        // The stat-card accents now resolve from the theme (context.colors /
        // colorScheme), so tests assert against the canonical light theme.
        theme: theme ?? buildAppTheme(),
        home: Scaffold(
          body: CommunityScreen(
            currentNavIndex: navIndex,
            onNavIndexChanged: onNavIndexChanged ?? (_) {},
            onStartReview: onStartReview,
            pendingReviews: pendingReviews,
            isLoading: isLoading,
            hasError: hasError,
            onRetry: onRetry,
            verifiedCount: verifiedCount,
            addedCount: addedCount,
            onReviewCompleted: onReviewCompleted,
          ),
        ),
      );
    }

    testWidgets('displays intro section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('הכוח שלנו הוא בידע'), findsOneWidget);
      expect(
        find.text('עזרו לאחרים לגלוש בביטחה ולגלות מוצרים חדשים.'),
        findsOneWidget,
      );
    });

    testWidgets('displays stat cards with labels, icons and accent colours '
        '(CH2-CH4)', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(StatCard), findsNWidgets(2));
      expect(find.text('אומתו בהצלחה'), findsOneWidget);
      expect(find.text('מוצרים נוספו'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);

      // #263: no counts injected and not loading/error → cards render the
      // "unknown" dash rather than the old hardcoded 5 / 2 fallback. Both stat
      // cards show '--', each in its card's accent colour.
      final dashes = tester.widgetList<Text>(find.text('--')).toList();
      expect(dashes, hasLength(2));
      final dashColors = dashes.map((t) => t.style?.color).toSet();
      expect(dashColors, {AppColorsExt.light().success, AppColors.primary});
    });

    testWidgets('renders injected verified/added counts (CH5)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CommunityScreen(
            currentNavIndex: 0,
            onNavIndexChanged: (_) {},
            verifiedCount: 8,
            addedCount: 3,
          ),
        ),
      ));

      expect(find.text('8'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays hero card with heading, body and CTA (CH6)',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CommunityScreen(
            currentNavIndex: 0,
            onNavIndexChanged: (_) {},
            onAddProductTap: () => tapped++,
          ),
        ),
      ));

      expect(find.text('עזרו לקהילה'), findsOneWidget);
      expect(
        find.text(
            'מצאתם מוצר חדש? הוסיפו אותו כדי שכולם יוכלו לדעת אם הוא בטוח.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'הוספת מוצר חדש'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('displays peer review bento with icon tile + count (CH7/CH8)',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('בקרת עמיתים'), findsOneWidget);
      expect(find.byIcon(Icons.rate_review), findsOneWidget);
      // kDebugMode stub queue has one item → "מוצר אחד" appears inside the
      // RichText body (matched via textContaining with findRichText since it is
      // a TextSpan run).
      expect(
        find.textContaining('הממתינים לבדיקה שלך', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('התחל בבדיקה'), findsOneWidget);
    });

    testWidgets('"התחל בבדיקה" CTA invokes onStartReview override (#55)', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        createWidgetUnderTest(onStartReview: () => tapped++),
      );

      await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'));
      await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets(
      '"התחל בבדיקה" CTA pushes CommunityReviewScreen by default (#55)',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CommunityReviewScreen), findsNothing);

        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        // Tap → process frame → advance past MaterialPageRoute's ~300ms
        // transition with a *bounded* pump. Avoid pumpAndSettle here: per
        // CLAUDE.md it would trap any future repeating AnimationController
        // added to the pushed screen as a CI timeout.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(CommunityReviewScreen), findsOneWidget);
      },
    );

    testWidgets('empty queue + no override disables "התחל בבדיקה" CTA (#55)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(pendingReviews: const []));

      expect(find.textContaining('אין כעת מוצרים לבדיקה'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'התחל בבדיקה'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'empty queue + override keeps "התחל בבדיקה" CTA enabled (#55)',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(
          createWidgetUnderTest(
            pendingReviews: const [],
            onStartReview: () => tapped++,
          ),
        );

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'),
        );
        expect(button.onPressed, isNotNull);

        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.pump();
        expect(tapped, 1);
      },
    );

    testWidgets(
      'rebuild with pendingReviews: null clears a previously non-null queue '
      '(#137)',
      (tester) async {
        const reviews = [
          PendingReview(
            id: 'r1',
            productId: 'p1',
            productName: 'מוצר א',
            brandName: 'מותג א',
            categoryLabel: 'חטיפים',
          ),
          PendingReview(
            id: 'r2',
            productId: 'p2',
            productName: 'מוצר ב',
            brandName: 'מותג ב',
            categoryLabel: 'משקאות',
          ),
        ];

        // A tiny host that lets the test flip the incoming list to null,
        // exercising CommunityScreen.didUpdateWidget (not a fresh mount).
        late StateSetter setOuter;
        List<PendingReview>? incoming = reviews;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return CommunityScreen(
                    currentNavIndex: 0,
                    onNavIndexChanged: (_) {},
                    pendingReviews: incoming,
                  );
                },
              ),
            ),
          ),
        );

        // Two pending items → the plural body.
        expect(find.textContaining('הממתינים לבדיקה שלך', findRichText: true), findsOneWidget);

        // Parent resets to null (e.g. logout / data clear).
        setOuter(() => incoming = null);
        await tester.pump();

        // Stale entries must be gone — the empty-state heading shows, the
        // phantom-count heading does not.
        expect(find.textContaining('אין כעת מוצרים לבדיקה'), findsOneWidget);
        expect(find.textContaining('הממתינים לבדיקה שלך', findRichText: true), findsNothing);
      },
    );

    testWidgets(
      'fires onReviewCompleted after a successful approve (#278)',
      (tester) async {
        var completed = 0;
        await tester.pumpWidget(
          createWidgetUnderTest(
            pendingReviews: const [
              PendingReview(
                id: 'r1',
                productId: 'p1',
                productName: 'מוצר א',
                brandName: 'מותג א',
                categoryLabel: 'חטיפים',
              ),
            ],
            onReviewCompleted: () => completed++,
          ),
        );

        // Open the review screen via the default CTA.
        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(CommunityReviewScreen), findsOneWidget);

        // Approve the single pending item.
        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'אישור מוצר'));
        await tester.tap(find.widgetWithText(FilledButton, 'אישור מוצר'));
        await tester.pump();

        expect(completed, 1);
      },
    );

    testWidgets(
      'fires onReviewCompleted after a successful reject (#278)',
      (tester) async {
        var completed = 0;
        await tester.pumpWidget(
          createWidgetUnderTest(
            pendingReviews: const [
              PendingReview(
                id: 'r1',
                productId: 'p1',
                productName: 'מוצר א',
                brandName: 'מותג א',
                categoryLabel: 'חטיפים',
              ),
            ],
            onReviewCompleted: () => completed++,
          ),
        );

        // Open the review screen via the default CTA.
        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(CommunityReviewScreen), findsOneWidget);

        // Reject requires a non-empty reason before the callback fires.
        await tester.enterText(find.byType(TextField), 'מידע שגוי');
        await tester.pump();

        await tester.ensureVisible(
            find.widgetWithText(OutlinedButton, 'פסילת מוצר'));
        await tester.tap(find.widgetWithText(OutlinedButton, 'פסילת מוצר'));
        await tester.pump();

        expect(completed, 1);
      },
    );

    testWidgets(
      '"חזרה לבית" on the all-clear screen returns to the Home tab (#326)',
      (tester) async {
        int? selectedTab;
        await tester.pumpWidget(
          createWidgetUnderTest(
            onNavIndexChanged: (i) => selectedTab = i,
            pendingReviews: const [
              PendingReview(
                id: 'r1',
                productId: 'p1',
                productName: 'מוצר א',
                brandName: 'מותג א',
                categoryLabel: 'חטיפים',
              ),
            ],
          ),
        );

        // Open the review screen, then approve the single item → all-clear.
        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'אישור מוצר'));
        await tester.tap(find.widgetWithText(FilledButton, 'אישור מוצר'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Now on the celebration screen.
        expect(find.text('כל הכבוד!'), findsOneWidget);

        // Tap the previously-dead "חזרה לבית" CTA → Home tab is selected.
        await tester
            .ensureVisible(find.widgetWithText(FilledButton, 'חזרה לבית'));
        await tester.tap(find.widgetWithText(FilledButton, 'חזרה לבית'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(selectedTab, 0);
      },
    );

    testWidgets(
      'queue load failure shows an error toast, not the all-clear screen '
      '(#354)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: CommunityScreen(
                currentNavIndex: 0,
                onNavIndexChanged: (_) {},
                // Live controller + no injected queue → the service-backed
                // start path (`_startReviewWithService`) drives the session.
                reviewController: _ThrowingReviewController(),
              ),
            ),
          ),
        );
        // initState fires a fetch that throws and is swallowed; let it settle.
        await tester.pump();

        // The CTA stays eligible during/after the failed async load.
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'),
        );
        expect(button.onPressed, isNotNull);

        await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        await tester.tap(find.widgetWithText(FilledButton, 'התחל בבדיקה'));
        // loadQueue throws → error toast, no navigation. Bounded pumps only
        // (no pumpAndSettle, per CLAUDE.md).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // The celebration screen must NOT appear on a load failure.
        expect(find.byType(ReviewAllClearScreen), findsNothing);
        expect(find.byType(CommunityReviewScreen), findsNothing);
        // A user-facing Hebrew error toast surfaces instead.
        expect(
          find.text('אירעה שגיאה בטעינת רשימת הבדיקות. נסה שוב.'),
          findsOneWidget,
        );

        // The CTA must stay enabled after the failure so the user can retry
        // (#354 AC: "the CTA is re-enabled on failure … retry via the CTA").
        final buttonAfter = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'),
        );
        expect(buttonAfter.onPressed, isNotNull);

        // Flush the SnackBar's auto-dismiss timer so it isn't left pending at
        // teardown (the binding asserts no timers survive the widget tree).
        await tester.pump(const Duration(seconds: 4));
      },
    );

    group('Tier 2 state variants', () {
      testWidgets('isLoading renders placeholder stats + skeleton + disabled CTA',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(isLoading: true));

        // Stats fall back to the "--" placeholder.
        expect(find.text('--'), findsNWidgets(2));
        expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'התחל בבדיקה'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('hasError shows the retry banner and "?" stats',
          (tester) async {
        var retried = 0;
        await tester.pumpWidget(createWidgetUnderTest(
          hasError: true,
          onRetry: () => retried++,
        ));

        expect(
          find.text('לא ניתן לטעון נתונים — בדוק חיבור לאינטרנט.'),
          findsOneWidget,
        );
        expect(find.text('?'), findsNWidgets(2));

        await tester.tap(find.text('נסה שוב'));
        await tester.pump();
        expect(retried, 1);
      });

      testWidgets(
        'hasError with last-known counts keeps stale stats visible, not "?" '
        '(#281)',
        (tester) async {
          // A re-fetch failed (hasError) but the previous good counts are still
          // in memory — they must remain visible rather than being wiped to "?".
          await tester.pumpWidget(createWidgetUnderTest(
            hasError: true,
            verifiedCount: 8,
            addedCount: 3,
          ));

          expect(find.text('8'), findsOneWidget);
          expect(find.text('3'), findsOneWidget);
          expect(find.text('?'), findsNothing);

          // The error banner still surfaces the failure to the user.
          expect(
            find.text('לא ניתן לטעון נתונים — בדוק חיבור לאינטרנט.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'hasError with one populated and one null count shows value + "?" '
        '(#281)',
        (tester) async {
          await tester.pumpWidget(createWidgetUnderTest(
            hasError: true,
            verifiedCount: 8,
            // addedCount stays null → never fetched → "?".
          ));

          expect(find.text('8'), findsOneWidget);
          expect(find.text('?'), findsOneWidget);
        },
      );
    });

    group('responsive layout (#324)', () {
      testWidgets('wide viewport renders the two sections side-by-side',
          (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());

        final helpCenter = tester.getCenter(find.text('עזרו לקהילה'));
        final peerCenter = tester.getCenter(find.text('בקרת עמיתים'));

        // Side-by-side, not stacked: the "check" (peer-review) card is on the
        // left and the help card on the right in RTL, so their horizontal
        // centres are well separated.
        expect(peerCenter.dx, lessThan(helpCenter.dx - 100));
      });

      testWidgets('narrow viewport keeps the sections stacked',
          (tester) async {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());

        final helpCenter = tester.getCenter(find.text('עזרו לקהילה'));
        final peerCenter = tester.getCenter(find.text('בקרת עמיתים'));

        // Stacked: the peer-review card renders below the help card (whereas in
        // the two-column layout they share the same vertical band).
        expect(peerCenter.dy, greaterThan(helpCenter.dy + 100));
      });
    });

    testWidgets('renders under the dark theme without exception (#291)',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(theme: buildDarkAppTheme()),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('הכוח שלנו הוא בידע'), findsOneWidget);
    });
  });
}
