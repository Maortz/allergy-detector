import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  testWidgets('buildAppTheme returns non-null ThemeData', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme()),
    );
    final theme = Theme.of(tester.element(find.byType(MaterialApp)));
    expect(theme, isNotNull);
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, isNotNull);
  });
}