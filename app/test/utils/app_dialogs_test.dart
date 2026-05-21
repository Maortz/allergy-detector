import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/app_dialogs.dart';

void main() {
  Widget buildHost(Widget Function(BuildContext) builder) {
    return MaterialApp(
      home: Builder(builder: builder),
    );
  }

  group('showWizardExitDialog', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () => showWizardExitDialog(ctx),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('לצאת מהוספת מוצר?'), findsOneWidget);
    });

    testWidgets('"המשך עריכה" returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () async => result = await showWizardExitDialog(ctx),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('המשך עריכה'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('"צא" returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () async => result = await showWizardExitDialog(ctx),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('צא'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('showLogoutDialog', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () => showLogoutDialog(ctx, onConfirmed: () {}),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('התנתק מהחשבון?'), findsOneWidget);
    });

    testWidgets('"ביטול" does not call onConfirmed', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () => showLogoutDialog(ctx, onConfirmed: () => called = true),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ביטול'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });

    testWidgets('"התנתק" calls onConfirmed', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () => showLogoutDialog(ctx, onConfirmed: () => called = true),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('התנתק'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });
  });

  group('showBrandDeleteDialog', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () => showBrandDeleteDialog(ctx),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('האם למחוק את המותג?'), findsOneWidget);
    });

    testWidgets('"מחק" returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () async => result = await showBrandDeleteDialog(ctx),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('מחק'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('"ביטול" returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(buildHost((ctx) => TextButton(
        onPressed: () async => result = await showBrandDeleteDialog(ctx),
        child: const Text('open'),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ביטול'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
