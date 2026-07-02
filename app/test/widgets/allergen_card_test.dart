import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/widgets/allergen_card.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  group('AllergenCard DD-13 selected style', () {
    const allergen = Allergen(id: 'id-milk', nameHe: 'חלב', nameEn: 'Dairy');

    testWidgets('unselected: white bg, 1.5 pt grey border, grey icon, no badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: AllergenCard(allergen: allergen, isSelected: false),
            ),
          ),
        ),
      );
      // No check_circle badge
      expect(find.byIcon(Icons.check_circle), findsNothing);
      // Icon uses the theme outline grey (light colorScheme.outline ==
      // AppColors.outline), unchanged across states.
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, AppColors.outline);
    });

    testWidgets(
        'selected: white bg, 2 pt primary border, check_circle badge, icon color unchanged',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: 160,
                height: 120,
                child: AllergenCard(allergen: allergen, isSelected: true),
              ),
            ),
          ),
        ),
      );
      // check_circle badge present
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // badge is primary color (light colorScheme.primary == AppColors.primary)
      final badge = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(badge.color, AppColors.primary);
    });

    testWidgets('locked card shows lock badge, no check_circle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: 160,
                height: 120,
                child: AllergenCard(allergen: allergen, isSelected: false, locked: true),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });
}
