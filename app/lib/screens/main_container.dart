import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import 'home_screen.dart';
import 'search_scan_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'admin_brands_screen.dart';
import 'contact_screen.dart';
import 'drawer_user_screen.dart';
import 'scan_history_screen.dart';
import 'saved_products_screen.dart';
import 'my_reviews_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';
import '../theme/app_colors.dart';
import '../utils/app_dialogs.dart';
import '../widgets/bottom_nav_bar.dart';

class MainContainer extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;

  /// Registered on the live [MainContainer] so terminal screens pushed above
  /// it can return to a specific bottom-nav tab via [switchToTab].
  ///
  /// Tracking: this is a process-global singleton; mounting two
  /// [MainContainer]s in the same widget tree (e.g. a future split-view, or
  /// running widget tests in parallel) would assert "GlobalKey already in
  /// tree". The canonical Flutter idiom is an `InheritedNotifier` that
  /// exposes `switchToTab(int)` to descendants; pushed routes can't reach an
  /// ancestor `InheritedWidget` of [MainContainer] (they hang off the root
  /// Navigator, not below [MainContainer] in the element tree) so any
  /// migration would need to lift the notifier above the root `Navigator` —
  /// non-trivial, and worth doing once a third or fourth caller depends on
  /// this helper.
  static final GlobalKey<MainContainerState> rootKey =
      GlobalKey<MainContainerState>();

  const MainContainer({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
  });

  @override
  State<MainContainer> createState() => MainContainerState();

  /// Pops every route pushed above the [MainContainer] root, then selects
  /// [tabIndex] on the bottom nav. Safe no-op when no live [MainContainer]
  /// is mounted (e.g. widget tests that render a terminal screen in
  /// isolation).
  static void switchToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    rootKey.currentState?.setActiveTab(tabIndex);
  }
}

class MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  /// Currently-selected bottom-nav tab index. Exposed publicly so terminal
  /// screens (and their tests) can assert which tab the helper landed on
  /// after a pop.
  int get currentIndex => _currentIndex;

  void _onNavIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Public entry point used by [MainContainer.switchToTab] to land terminal
  /// screens on a specific tab once their route is popped.
  void setActiveTab(int index) => _onNavIndexChanged(index);

  void _onDrawerDestinationSelected(DrawerDestination destination) {
    Navigator.pop(context); // close drawer first
    switch (destination) {
      case DrawerDestination.profile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              userProfile: widget.userProfile,
              allergens: widget.allergens,
              onProfileUpdated: widget.onProfileUpdated,
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              onContactTap: _showContactSheet,
              onAdminBrandsTap: _navigateToAdminBrands,
            ),
          ),
        );
      case DrawerDestination.scanHistory:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanHistoryScreen()),
        );
      case DrawerDestination.savedProducts:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SavedProductsScreen(),
          ),
        );
      case DrawerDestination.myReviews:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyReviewsScreen()),
        );
      case DrawerDestination.helpCenter:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HelpCenterScreen(
              onContactTap: () {
                Navigator.pop(context);
                _showContactSheet();
              },
            ),
          ),
        );
      case DrawerDestination.about:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
    }
  }

  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ContactScreen(
            onNavTap: (index) {
              Navigator.pop(context);
              _onNavIndexChanged(index);
            },
          ),
        ),
      ),
    );
  }

  void _navigateToAdminBrands() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBrandsScreen(
          client: Supabase.instance.client,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        drawer: Drawer(
          child: DrawerUserScreen(
            onDestinationSelected: _onDrawerDestinationSelected,
            userName: widget.userProfile.displayName,
            onLogout: () {
              Navigator.pop(context); // close drawer first
              showLogoutDialog(
                context,
                onConfirmed: () => widget.onProfileUpdated(const UserProfile()),
              );
            },
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              userProfile: widget.userProfile,
              allergens: widget.allergens,
              onProfileUpdated: widget.onProfileUpdated,
              onScanTap: () => _onNavIndexChanged(1),
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
            ),
            SearchScanScreen(
              userProfile: widget.userProfile,
              allergens: widget.allergens,
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
            ),
            CommunityScreen(
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
            ),
            FavoritesScreen(
              userProfile: widget.userProfile,
              onNavIndexChanged: _onNavIndexChanged,
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => _onNavIndexChanged(1),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('סריקה'),
              )
            : null,
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavIndexChanged,
        ),
      ),
    );
  }
}