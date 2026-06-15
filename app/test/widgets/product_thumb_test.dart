import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/product_thumb.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the fallback icon when imageUrl is null',
      (tester) async {
    await tester.pumpWidget(host(const ProductThumb(
      imageUrl: null,
      fallbackIcon: Icons.rate_review_outlined,
    )));

    expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders an Image (no fallback icon) when imageUrl is non-null',
      (tester) async {
    await tester.pumpWidget(host(const ProductThumb(
      imageUrl: 'https://example.com/p.png',
      fallbackIcon: Icons.rate_review_outlined,
    )));

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.rate_review_outlined), findsNothing);
  });

  testWidgets('honors a custom fallback icon', (tester) async {
    await tester.pumpWidget(host(const ProductThumb(
      imageUrl: null,
      fallbackIcon: Icons.shopping_basket,
    )));

    expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
    expect(find.byIcon(Icons.rate_review_outlined), findsNothing);
  });
}
