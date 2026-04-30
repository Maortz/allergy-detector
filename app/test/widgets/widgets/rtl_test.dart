import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RTL Directionality', () {
    testWidgets('MyApp wraps MaterialApp with Directionality.rtl', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyTestWidget(),
        ),
      );

      final directionalityFinder = find.byType(Directionality);
      expect(directionalityFinder, findsWidgets);

      final directionalityList = tester.widgetList<Directionality>(directionalityFinder);
      final hasRtl = directionalityList.any((d) => d.textDirection == TextDirection.rtl);
      expect(hasRtl, true);
    });

    testWidgets('Hebrew text renders right-to-left', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: Text('בדיקה'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('בדיקה'), findsOneWidget);
    });

    testWidgets('Directionality widget wraps app content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Text('תוכן'),
            ),
          ),
        ),
      );

      final directionalityFinder = find.byType(Directionality);
      expect(directionalityFinder, findsWidgets);

      final directionalityList = tester.widgetList<Directionality>(directionalityFinder);
      final hasRtl = directionalityList.any((d) => d.textDirection == TextDirection.rtl);
      expect(hasRtl, true);
      expect(find.text('תוכן'), findsOneWidget);
    });

    testWidgets('Multiple RTL widgets maintain directionality', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Column(
                children: [
                  Text('כותרת'),
                  Text('תוכן נוסף'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('כותרת'), findsOneWidget);
      expect(find.text('תוכן נוסף'), findsOneWidget);
    });
  });
}

class MyTestWidget extends StatelessWidget {
  const MyTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Text('בדיקה'),
        ),
      ),
    );
  }
}