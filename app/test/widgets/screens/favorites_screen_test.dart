import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/favorites_screen.dart';
import 'package:app/models/user_profile.dart';

void main() {
  Widget buildSubject({ValueChanged<int>? onNavChanged}) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: FavoritesScreen(
          userProfile: const UserProfile(),
          onNavIndexChanged: onNavChanged ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('shows empty state heading', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('לא שמרת מוצרים עדיין'), findsOneWidget);
  });

  testWidgets('shows scan CTA button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('סרוק מוצר'), findsOneWidget);
  });

  testWidgets('scan CTA navigates to index 1', (tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
        buildSubject(onNavChanged: (i) => tappedIndex = i));
    await tester.tap(find.text('סרוק מוצר'));
    await tester.pump();
    expect(tappedIndex, 1);
  });

  testWidgets('shows favorite_border icon', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}
