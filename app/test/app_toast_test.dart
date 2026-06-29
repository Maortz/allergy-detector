import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/utils/app_toast.dart';

void main() {
  // Pumps a button that, when tapped, invokes [onPressed] with a context that
  // sits *below* a ScaffoldMessenger so AppToast can resolve a messenger.
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(BuildContext context) onPressed, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onPressed(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
  }

  SnackBar findSnackBar(WidgetTester tester) =>
      tester.widget<SnackBar>(find.byType(SnackBar));

  group('AppToast', () {
    testWidgets('success shows a floating SnackBar with success colors + icon',
        (tester) async {
      await pumpHost(tester, (c) => AppToast.success(c, 'נשמר בהצלחה'));
      await tester.tap(find.text('go'));
      await tester.pump(); // let the SnackBar enter

      expect(find.text('נשמר בהצלחה'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final snack = findSnackBar(tester);
      expect(snack.backgroundColor, AppColorsExt.light().success);
      expect(snack.behavior, SnackBarBehavior.floating);
    });

    testWidgets(
        'error shows a theme error-colored SnackBar with error icon (light)',
        (tester) async {
      await pumpHost(tester, (c) => AppToast.error(c, 'שגיאה'),
          theme: buildAppTheme());
      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.text('שגיאה'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      // Light theme maps colorScheme.error to AppColors.error.
      expect(findSnackBar(tester).backgroundColor, AppColors.error);
    });

    testWidgets('error uses the dark theme error color under dark mode',
        (tester) async {
      await pumpHost(tester, (c) => AppToast.error(c, 'שגיאה'),
          theme: buildDarkAppTheme());
      await tester.tap(find.text('go'));
      await tester.pump();

      // Dark theme adapts: error toast no longer renders light-theme red.
      expect(findSnackBar(tester).backgroundColor, AppDarkColors.error);
      expect(findSnackBar(tester).backgroundColor, isNot(AppColors.error));
    });

    testWidgets('info shows a primary-colored SnackBar with info icon',
        (tester) async {
      await pumpHost(tester, (c) => AppToast.info(c, 'לידיעתך'));
      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.text('לידיעתך'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(findSnackBar(tester).backgroundColor, AppColors.primary);
    });

    testWidgets('a second toast clears the first (clearSnackBars semantics)',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      AppToast.success(ctx, 'ראשון');
      await tester.pump();
      expect(find.text('ראשון'), findsOneWidget);

      AppToast.error(ctx, 'שני');
      // clearSnackBars removes the first immediately; pump settles the swap.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ראשון'), findsNothing);
      expect(find.text('שני'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('null messenger (no ScaffoldMessenger) is handled silently',
        (tester) async {
      late BuildContext bareContext;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) {
              bareContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // No ScaffoldMessenger above bareContext → maybeOf returns null.
      expect(ScaffoldMessenger.maybeOf(bareContext), isNull);
      // Must not throw.
      AppToast.error(bareContext, 'לא יוצג');
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('SnackBarAction, when provided, is rendered', (tester) async {
      await pumpHost(
        tester,
        (c) => AppToast.info(
          c,
          'בוצע',
          action: SnackBarAction(label: 'בטל', onPressed: () {}),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(find.text('בטל'), findsOneWidget);
    });
  });
}
