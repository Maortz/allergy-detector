import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/screens/search_screen.dart';
import 'package:app/widgets/skeleton_box.dart';

void main() {
  // #189 — the active-search loading state must render a shimmer skeleton
  // (4 product-card-shaped rows of SkeletonBox blocks) instead of a centered
  // CircularProgressIndicator. SearchScreenContent builds its ProductService
  // inline from Supabase.instance.client (not injectable), so the loading view
  // is extracted into the public SearchLoadingSkeleton widget and exercised
  // here directly — this is the exact widget rendered on the _isLoading path.
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('he'),
        supportedLocales: const [Locale('he')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      );

  testWidgets('loading state renders shimmer skeleton rows, no spinner',
      (tester) async {
    await tester.pumpWidget(wrap(const SearchLoadingSkeleton()));

    // No spinner anywhere in the initial-load path.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Shimmer blocks are present.
    expect(find.byType(SkeletonBox), findsWidgets);
  });

  testWidgets('loading state renders exactly 4 skeleton rows', (tester) async {
    await tester.pumpWidget(wrap(const SearchLoadingSkeleton()));

    expect(find.byType(SearchLoadingSkeletonRow), findsNWidgets(4));
  });
}
