import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_typography.dart';
import 'package:app/widgets/stat_card.dart';

void main() {
  group('StatCard', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('renders value, label and icon', (tester) async {
      await tester.pumpWidget(host(const StatCard(
        value: '5',
        label: 'אומתו בהצלחה',
        icon: Icons.verified,
        accentColor: AppColors.success,
      )));

      expect(find.text('5'), findsOneWidget);
      expect(find.text('אומתו בהצלחה'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('applies the accent colour to the number and icon',
        (tester) async {
      await tester.pumpWidget(host(const StatCard(
        value: '2',
        label: 'מוצרים נוספו',
        icon: Icons.add_circle,
        accentColor: AppColors.primary,
      )));

      final number = tester.widget<Text>(find.text('2'));
      expect(number.style?.color, AppColors.primary);
      expect(number.style?.fontSize, AppTypography.h1.fontSize);

      final icon = tester.widget<Icon>(find.byIcon(Icons.add_circle));
      expect(icon.color, AppColors.primary);
    });

    testWidgets('centres its content (CH2)', (tester) async {
      await tester.pumpWidget(host(const StatCard(
        value: '0',
        label: 'מוצרים נוספו',
        icon: Icons.add_circle,
        accentColor: AppColors.primary,
      )));

      final column = tester.widget<Column>(
        find.descendant(of: find.byType(StatCard), matching: find.byType(Column)),
      );
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}
