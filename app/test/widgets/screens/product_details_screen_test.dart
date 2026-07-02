import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/screens/product_details.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/services/favorites_service.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ProductDetailsScreen Widget Tests', () {
    late Product testProduct;
    late UserProfile testProfile;

    setUp(() {
      // The favorite toggle reads/writes SharedPreferences on mount.
      SharedPreferences.setMockInitialValues({});
      testProduct = TestFixtures.sampleProduct;
      testProfile = TestFixtures.sampleProfile;
    });

    Widget createWidgetUnderTest({
      Product? product,
      UserProfile? profile,
      List<Allergen> allergenCatalog = const [],
      VoidCallback? onReport,
      VoidCallback? onDeleted,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        home: ProductDetailsScreen(
          product: product ?? testProduct,
          userProfile: profile ?? testProfile,
          allergenCatalog: allergenCatalog,
          onReport: onReport,
          onDeleted: onDeleted,
        ),
      );
    }

    testWidgets('displays brand name in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('טרה'), findsOneWidget);
    });

    testWidgets('displays kosher label when product is kosher', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('כשר'), findsOneWidget);
    });

    testWidgets('renders the no-image placeholder when imageUrl is null',
        (tester) async {
      // createProduct() leaves imageUrl null → hero slot falls back to the
      // neutral placeholder (product-details-safe.md §7).
      await tester.pumpWidget(
        createWidgetUnderTest(product: TestFixtures.createProduct()),
      );

      expect(find.text('אין תמונה זמינה'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    group('status indicator', () {
      testWidgets('avoid: full-width solid-red banner with white label + cancel icon',
          (tester) async {
        // sampleProduct (גלוטן=contains) + sampleProfile {1,2} → avoid.
        await tester.pumpWidget(createWidgetUnderTest());

        // Banner copy (em-dash, no extra "שלך").
        expect(find.text('הימנע – מכיל אלרגנים'), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);

        final banner = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('הימנע – מכיל אלרגנים'),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(banner.color, AppColorsExt.light().avoid); // solid #DC2626
        expect(banner.color,
            isNot(AppColorsExt.light().avoidBackground)); // not pink tint
      });

      testWidgets('caution: compact pill "זהירות" + separate adjacent text',
          (tester) async {
        final cautionProduct = Product(
          id: 'test-1',
          nameHe: 'מוצר בדיקה',
          allergens: [
            ProductAllergen(
              allergenId: '1',
              allergenNameHe: 'גלוטן',
              severity: 'may_contain',
            ),
          ],
        );
        await tester.pumpWidget(createWidgetUnderTest(product: cautionProduct));

        // Pill label is the FIXED verdict only (DD-3).
        expect(find.text('זהירות'), findsOneWidget);
        // Adjacent text is a separate element.
        expect(find.text('עלול להכיל אלרגנים'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
        // NOT a full-width avoid banner.
        expect(find.text('הימנע – מכיל אלרגנים'), findsNothing);
      });

      testWidgets('safe: compact pill "בטוח" + separate adjacent text',
          (tester) async {
        final safeProduct = Product(
          id: 'test-1',
          nameHe: 'מוצר בטוח',
          allergens: [
            ProductAllergen(
              allergenId: '99',
              allergenNameHe: 'אלרגן אחר',
              severity: 'contains',
            ),
          ],
        );
        await tester.pumpWidget(createWidgetUnderTest(
          product: safeProduct,
          profile: const UserProfile(
            selectedAllergenIds: {},
            hasCompletedOnboarding: true,
          ),
        ));

        expect(find.text('בטוח'), findsOneWidget);
        expect(find.text('ללא אלרגנים עבורך'), findsOneWidget);
        // Old merged label must be gone.
        expect(find.text('✓ בטוח - ללא אלרגנים עבורך'), findsNothing);
      });
    });

    testWidgets('displays detected allergens section in Hebrew', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('אלרגנים שזוהו'), findsOneWidget);
    });

    group('allergen chips', () {
      testWidgets('renders a chip per product allergen, by Hebrew name',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('אלרגנים שזוהו'), findsOneWidget);
        expect(find.text('גלוטן'), findsOneWidget); // contains
        expect(find.text('חלב'), findsOneWidget); // may_contain
      });

      testWidgets('detected (contains ∩ user) chip uses the avoid chip colours',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // The "גלוטן" chip is a detected chip — red tint background.
        final chip = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('גלוטן'),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = chip.decoration as BoxDecoration;
        // #292: chips now resolve via context.colors → AppColorsExt.light()
        // (the theme-aware palette), whose detected-chip bg (0xFFFCE8E6) is
        // distinct from the old AppColors.chipDetectedBg (0xFFFEE2E2). Assert
        // against the token only — it is the single source of truth.
        expect(decoration.color, AppColorsExt.light().chipDetectedBg);
      });

      testWidgets('chips use rounded-pill shape (radius 20), not row-cards',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final chip = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('גלוטן'),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = chip.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(20));
      });

      testWidgets('soy allergen uses the glossary icon, not Icons.eco',
          (tester) async {
        final product = Product(
          id: 'p-soy',
          nameHe: 'מוצר סויה',
          allergens: [
            ProductAllergen(
              allergenId: 'soy',
              allergenNameHe: 'סויה',
              severity: 'contains',
            ),
          ],
        );
        await tester.pumpWidget(createWidgetUnderTest(
          product: product,
          profile: const UserProfile(
            selectedAllergenIds: {'soy'},
            hasCompletedOnboarding: true,
          ),
        ));

        expect(find.byIcon(Icons.local_dining), findsOneWidget);
        expect(find.byIcon(Icons.eco), findsNothing);
      });
    });

    group('monitored allergens (SF5)', () {
      testWidgets(
          'safe product with a catalog shows the user\'s monitored allergens '
          'under "אלרגנים שנבדקו"', (tester) async {
        // Product contains only a non-monitored allergen → safe state.
        final safeProduct = Product(
          id: 'p-safe',
          nameHe: 'מוצר בטוח',
          allergens: [
            ProductAllergen(
              allergenId: '99',
              allergenNameHe: 'אלרגן אחר',
              severity: 'contains',
            ),
          ],
        );
        await tester.pumpWidget(createWidgetUnderTest(
          product: safeProduct,
          profile: const UserProfile(
            selectedAllergenIds: {'3', '4'}, // ביצים, אגוזים
            hasCompletedOnboarding: true,
          ),
          allergenCatalog: TestFixtures.sampleAllergens,
        ));

        expect(find.text('אלרגנים שנבדקו'), findsOneWidget);
        expect(find.text('ביצים'), findsOneWidget);
        expect(find.text('אגוזים'), findsOneWidget);
      });

      testWidgets('caution product renders the monitored allergen chip',
          (tester) async {
        final cautionProduct = Product(
          id: 'p-caution',
          nameHe: 'מוצר',
          allergens: [
            ProductAllergen(
              allergenId: '3',
              allergenNameHe: 'ביצים',
              severity: 'may_contain',
            ),
          ],
        );
        await tester.pumpWidget(createWidgetUnderTest(
          product: cautionProduct,
          profile: const UserProfile(
            selectedAllergenIds: {'3'},
            hasCompletedOnboarding: true,
          ),
          allergenCatalog: TestFixtures.sampleAllergens,
        ));

        expect(find.text('אלרגנים שנבדקו'), findsOneWidget);
        // ביצים appears in both the detected and monitored sections.
        expect(find.text('ביצים'), findsWidgets);
      });

      testWidgets('section is hidden when no catalog is provided',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('אלרגנים שנבדקו'), findsNothing);
      });

      testWidgets('section is hidden in the avoid state', (tester) async {
        // sampleProduct (גלוטן=contains) ∩ sampleProfile {1,2} → avoid.
        await tester.pumpWidget(createWidgetUnderTest(
          allergenCatalog: TestFixtures.sampleAllergens,
        ));

        expect(find.text('אלרגנים שנבדקו'), findsNothing);
      });
    });

    group('ingredients', () {
      testWidgets('header is "רשימת רכיבים" with list_alt icon', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('רשימת רכיבים'), findsWidgets);
        expect(find.byIcon(Icons.list_alt), findsOneWidget);
        // Old copy gone.
        expect(find.text('רכיבים'), findsNothing);
        expect(find.text('לחץ להצגת רכיבים'), findsNothing);
      });

      testWidgets('highlights a matched allergen keyword in the ingredient text',
          (tester) async {
        // Product whose ingredient text literally contains the user's
        // "contains" allergen Hebrew name → avoid-state highlight.
        final product = Product(
          id: 'p-1',
          nameHe: 'מוצר',
          ingredients: 'מים, גלוטן, מלח',
          allergens: [
            ProductAllergen(
              allergenId: '1',
              allergenNameHe: 'גלוטן',
              severity: 'contains',
            ),
          ],
        );
        await tester.pumpWidget(createWidgetUnderTest(product: product));

        // Scroll until the ExpansionTile is visible, then expand it.
        await tester.scrollUntilVisible(
          find.byType(ExpansionTile),
          200,
        );
        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();

        // The body is a RichText whose spans include a red-coloured "גלוטן".
        final richText = tester.widget<RichText>(
          find
              .descendant(
                of: find.byType(ExpansionTile),
                matching: find.byType(RichText),
              )
              .last,
        );
        var foundHighlighted = false;
        richText.text.visitChildren((span) {
          if (span is TextSpan &&
              span.text == 'גלוטן' &&
              span.style?.color == const Color(0xFFDC2626)) {
            foundHighlighted = true;
          }
          return true;
        });
        expect(foundHighlighted, isTrue);
      });
    });

    group('feedback + report', () {
      testWidgets('shows the helpfulness feedback row with thumb buttons',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('האם המידע היה מועיל?'), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
        expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
      });

      testWidgets('tapping thumb up fills it and clears thumb down',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.scrollUntilVisible(
          find.byIcon(Icons.thumb_up_outlined),
          200,
        );
        await tester.tap(find.byIcon(Icons.thumb_up_outlined));
        await tester.pump();

        expect(find.byIcon(Icons.thumb_up), findsOneWidget);
        expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
      });

      testWidgets('report control: report_problem icon + "דווח על טעות"',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('דווח על טעות'), findsOneWidget);
        expect(find.byIcon(Icons.report_problem), findsOneWidget);
        // Old control gone.
        expect(find.text('דיווח על טעות'), findsNothing);
        expect(find.byIcon(Icons.flag), findsNothing);
      });
    });

    group('app bar, share, nav', () {
      testWidgets('app bar title is the fixed "פרטי מוצר"', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect((appBar.title as Text).data, 'פרטי מוצר');
        // Product name still rendered in the identity block (not the app bar).
        expect(find.text('פסטו בולו'), findsWidgets);
      });

      testWidgets('share icon is NOT in the app-bar actions', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // The share icon now lives on the image — assert it is not an
        // AppBar action by checking it is a descendant of the image Stack,
        // not the AppBar.
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.share),
          ),
          findsNothing,
        );
        // Still present somewhere on screen (overlaid on the image).
        expect(find.byIcon(Icons.share), findsOneWidget);
      });

      testWidgets('share opens the native share sheet with a product summary',
          (tester) async {
        // Capture the share_plus platform-channel invocation.
        const channel = MethodChannel('dev.fluttercommunity.plus/share');
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            calls.add(call);
            // A non-null string keeps share_plus from throwing on the result.
            return 'dev.fluttercommunity.plus/share/unavailable';
          },
        );
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null));

        await tester.pumpWidget(createWidgetUnderTest());

        // The share icon lives in a PositionedDirectional overlay on the product
        // image Stack. Ensure it is scrolled into view before tapping.
        await tester.ensureVisible(find.byIcon(Icons.share));
        await tester.tap(find.byIcon(Icons.share));
        await tester.pump();

        // The native share sheet was invoked with the product name in the body.
        // Filter by method name so an incidental channel message (init or a
        // capability query) can't make us inspect the wrong MethodCall.
        final shareCall = calls.firstWhere(
          (c) => c.method == 'share',
          orElse: () => fail('no share method call recorded'),
        );
        expect(shareCall.arguments as Map, containsPair('text', contains('פסטו בולו')));
      });

      // Issue #333 (Option A): Product Details is a pushed full route, so its
      // own bottom NavigationBar was dead (onTap was a no-op and it sat in front
      // of MainContainer's real nav). It is removed — the user navigates back
      // via the AppBar arrow.
      testWidgets('does not render a (dead) bottom navigation bar',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(NavigationBar), findsNothing);
      });
    });

    testWidgets('displays product image when available', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Image), findsOneWidget);
    });

    // Scope the favorites toggle lookups to the app-bar IconButton via its
    // tooltip.
    Finder favoriteToggle() => find.byTooltip('הוסף למועדפים');
    Finder unfavoriteToggle() => find.byTooltip('הסר ממועדפים');

    testWidgets('shows the add-to-favorites toggle when not favorited',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(favoriteToggle(), findsOneWidget);
      expect(unfavoriteToggle(), findsNothing);
    });

    testWidgets('tapping the favorite toggle persists and updates the icon',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(favoriteToggle());
      await tester.pumpAndSettle();

      // Toggle flips to the "remove" affordance, snackbar confirms, persisted.
      expect(unfavoriteToggle(), findsOneWidget);
      expect(find.text('נוסף למועדפים'), findsOneWidget);
      expect(await FavoritesService.isFavorite(testProduct.id), isTrue);
    });

    testWidgets('reflects an already-favorited product on mount',
        (tester) async {
      await FavoritesService.add(testProduct);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(unfavoriteToggle(), findsOneWidget);

      // Tapping again removes it.
      await tester.tap(unfavoriteToggle());
      await tester.pumpAndSettle();

      expect(favoriteToggle(), findsOneWidget);
      expect(find.text('הוסר מהמועדפים'), findsOneWidget);
      expect(await FavoritesService.isFavorite(testProduct.id), isFalse);
    });

    testWidgets('renders under the dark theme without exception (#292)',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(theme: buildDarkAppTheme()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('פרטי מוצר'), findsOneWidget);
    });
  });
}
