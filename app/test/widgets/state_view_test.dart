import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/state_view.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders icon, title and message', (tester) async {
    await tester.pumpWidget(host(const StateView(
      icon: Icons.search_off,
      title: 'לא נמצאו תוצאות',
      message: 'נסה מילת חיפוש אחרת',
    )));

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('לא נמצאו תוצאות'), findsOneWidget);
    expect(find.text('נסה מילת חיפוש אחרת'), findsOneWidget);
  });

  testWidgets('omits the action button when no actionLabel is given',
      (tester) async {
    await tester.pumpWidget(host(const StateView(
      icon: Icons.inbox,
      title: 'ריק',
    )));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders the action button and invokes onAction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(StateView(
      icon: Icons.wifi_off,
      title: 'שגיאה',
      actionLabel: 'נסה שוב',
      onAction: () => taps++,
    )));

    await tester.tap(find.text('נסה שוב'));
    await tester.pump();

    expect(taps, 1);
  });
}
