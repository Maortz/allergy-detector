import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/community_screen.dart';
import 'package:app/screens/search_screen.dart';
import 'package:app/widgets/skeleton_box.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  // #262 — the active-search overlay "+" FAB used to push a bare CommunityScreen
  // (broken/dark duplicate of the Community tab). It must instead invoke the
  // host-supplied onAddProductTap callback (→ AddProductWizard) and never push
  // CommunityScreen.
  group('overlay "+" FAB (#262)', () {
    setUpAll(() async {
      // SearchScreenContent builds ProductService(Supabase.instance.client) in a
      // field initializer, so the client must exist before the widget is built.
      // Supabase.initialize does not hit the network; a fake URL/key is fine,
      // but its gotrue local storage reads SharedPreferences — mock it.
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(
        url: 'http://localhost:54321',
        publishableKey: 'test-anon-key',
      );
    });

    testWidgets('"+" calls onAddProductTap and does not push CommunityScreen',
        (tester) async {
      var addTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreenContent(
            userProfile: const UserProfile(),
            allergens: const [],
            onProfileUpdated: (_) {},
            onAddProductTap: () => addTaps++,
          ),
        ),
      );
      // Let the post-frame product load fire (and fail against the fake URL)
      // without pumpAndSettle, which would hang on the load retry/timers.
      await tester.pump();

      final fab = find.byIcon(Icons.add);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pump();

      expect(addTaps, 1);
      expect(find.byType(CommunityScreen), findsNothing);
    });
  });
}
