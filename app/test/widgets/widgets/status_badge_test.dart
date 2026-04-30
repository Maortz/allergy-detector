import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/status_badge.dart';
import 'package:app/models/allergen.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('displays "בטוח" with check icon for safe status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AllergenStatus.safe),
          ),
        ),
      );

      expect(find.text('בטוח'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays "זהירות" with warning icon for caution status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AllergenStatus.caution),
          ),
        ),
      );

      expect(find.text('זהירות'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays "הימנע" with dangerous icon for avoid status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AllergenStatus.avoid),
          ),
        ),
      );

      expect(find.text('הימנע'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AllergenStatus.safe, showIcon: false),
          ),
        ),
      );

      expect(find.text('בטוח'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });
}