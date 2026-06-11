import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/widgets/top_app_bar.dart';

/// Accessibility regressions guarded here (#80): the two icon-only controls in
/// [TopAppBar] must expose screen-reader-discoverable affordances — the menu
/// button via a tooltip, the avatar via an explicit `Semantics(button: true)`
/// wrapper (a bare `GestureDetector` is invisible to assistive tech).
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      );

  testWidgets('menu button exposes a screen-reader tooltip', (tester) async {
    await tester.pumpWidget(wrap(TopAppBar(onMenuPressed: () {})));
    expect(find.byTooltip('תפריט'), findsOneWidget);
  });

  testWidgets('profile avatar is announced as a labelled button',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(TopAppBar(onProfilePressed: () => tapped = true)),
    );

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byIcon(Icons.person)),
      matchesSemantics(label: 'פרופיל', isButton: true, hasTapAction: true),
    );
    handle.dispose();

    await tester.tap(find.byIcon(Icons.person));
    expect(tapped, isTrue);
  });

  testWidgets('no profile button rendered when onProfilePressed is null',
      (tester) async {
    await tester.pumpWidget(wrap(const TopAppBar()));
    expect(find.byIcon(Icons.person), findsNothing);
  });
}
