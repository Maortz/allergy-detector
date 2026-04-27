import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/screens/add_product_screen.dart';

void main() {
  testWidgets('Add product form renders all fields', (tester) async {
    final allergens = [
      const Allergen(id: 'a1', nameHe: 'בוטנים'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: AddProductScreen(allergens: allergens),
      ),
    );
    
    expect(find.text('שם המוצר *'), findsOneWidget);
    expect(find.text('מותג (אופציונלי)'), findsOneWidget);
    expect(find.text('ברקוד (אופציונלי)'), findsOneWidget);
    expect(find.text('רכיבים (אופציונלי)'), findsOneWidget);
    expect(find.text('כשר'), findsOneWidget);
    expect(find.text('מכיל:'), findsOneWidget);
    expect(find.text('עשוי להכיל:'), findsOneWidget);
    expect(find.text('שמור מוצר'), findsOneWidget);
  });

  testWidgets('Add product shows allergen chips', (tester) async {
    final allergens = [
      const Allergen(id: 'a1', nameHe: 'בוטנים'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AddProductScreen(allergens: allergens),
      ),
    );
    
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    
    expect(find.byType(FilterChip), findsNWidgets(2));
  });

  testWidgets('Kosher switch is present', (tester) async {
    final allergens = <Allergen>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AddProductScreen(allergens: allergens),
      ),
    );
    
    final switchTile = find.byType(SwitchListTile);
    expect(switchTile, findsOneWidget);
    
    final switchWidget = tester.widget<SwitchListTile>(switchTile);
    expect(switchWidget.title, isNotNull);
  });

  testWidgets('Submit button is present', (tester) async {
    final allergens = <Allergen>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AddProductScreen(allergens: allergens),
      ),
    );
    
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    
    expect(find.text('שמור מוצר'), findsOneWidget);
  });
}