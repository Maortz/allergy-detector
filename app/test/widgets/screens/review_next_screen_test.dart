import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/review_next_screen.dart';
import 'package:app/widgets/skeleton_box.dart';

void main() {
  group('ReviewNextScreen Widget Tests', () {
    Widget buildSubject({bool isLoading = false}) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ReviewNextScreen(isLoading: isLoading),
          ),
        );

    testWidgets('isLoading renders the product-card skeleton + disabled CTAs',
        (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: true));

      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));

      final checkNow = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'בדוק עכשיו'),
      );
      expect(checkNow.onPressed, isNull);
    });

    testWidgets('renders the product card (not the skeleton) when not loading',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(SkeletonBox), findsNothing);
      expect(find.text('בדוק עכשיו'), findsOneWidget);
      expect(find.text('דלג'), findsOneWidget);
    });
  });
}
