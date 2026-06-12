import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../models/scan_history_entry.dart';
import '../models/user_profile.dart';
import '../services/scan_history_service.dart';
import 'home_screen.dart';
import 'search_scan_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'admin_brands_screen.dart';
import 'admin_destination_screen.dart';
import 'contact_screen.dart';
import 'drawer_user_screen.dart';
import 'admin_navigation_drawer.dart';
import 'scan_history_screen.dart';
import 'saved_products_screen.dart';
import 'my_reviews_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';
import '../theme/app_colors.dart';
import '../utils/app_dialogs.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_product_screen.dart';

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

  /// Runtime app version (e.g. "v1.0.0"), shown in the admin drawer footer
  /// (nav-drawer-admin.md §7.2). Null until [PackageInfo.fromPlatform]
  /// resolves; the drawer omits the version row while null.
  String? _appVersion;

  /// Persisted recent scans, loaded from [ScanHistoryService]. `null` until the
  /// first load resolves — while null the home feed shows its loading state;
  /// once loaded, an empty list renders the no-scans empty state. Spec ref:
  /// `home-dashboard.md §5`.
  List<ScanHistoryEntry>? _scanHistory;

  @override
  void initState() {
    super.initState();
    // The version string is only ever shown inside the admin drawer, so skip
    // the PackageInfo platform-channel round-trip for non-admin users.
    if (widget.userProfile.isAdmin) _loadAppVersion();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    final history = await ScanHistoryService.recentScans();
    if (!mounted) return;
    setState(() => _scanHistory = history);
  }

  /// The home "פעילות אחרונה" feed: the most recent few scans mapped to the
  /// screen's [RecentActivity] view model. `null` while history is still
  /// loading (drives the home loading state).
  List<RecentActivity>? get _recentActivity {
    final history = _scanHistory;
    if (history == null) return null;
    return history
        .take(_homeFeedLimit)
        .map((e) => RecentActivity(
              name: e.nameHe,
              brand: e.brandNameHe ?? '',
              imageUrl: e.imageUrl,
              time: e.relativeTime(),
              status: e.status,
            ))
        .toList();
  }

  /// How many recent scans the home dashboard feed shows (the full list lives
  /// in ScanHistoryScreen).
  static const _homeFeedLimit = 5;

  @override
  void didUpdateWidget(MainContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fetch lazily only on the non-admin → admin transition edge (e.g. a
    // future privilege-elevation flow). Gating on the edge — not the steady
    // state — avoids a duplicate concurrent PackageInfo round-trip if another
    // rebuild lands while the first fetch is still inflight.
    if (!oldWidget.userProfile.isAdmin &&
        widget.userProfile.isAdmin &&
        _appVersion == null) {
      _loadAppVersion();
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}');
  }

  void _onNavIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Returning to the home tab may surface scans recorded while another tab
    // was active (e.g. opening a product from search); refresh the feed.
    if (index == 0) _loadScanHistory();
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

  /// Drawer selection handler used by the root admin scaffold (MainContainer's
  /// own endDrawer). Closes the drawer, then routes to the chosen destination.
  void _onAdminDestinationSelected(AdminDrawerDestination destination) {
    Navigator.pop(context); // close drawer
    _navigateToAdminDestination(destination);
  }

  /// Drawer selection handler shared by the *pushed* admin destination screens.
  /// Those screens are already routes on the stack, so we first pop back to
  /// MainContainer before pushing the next destination — this keeps the back
  /// stack flat (one admin screen at a time) instead of growing it on every
  /// cross-navigation, and avoids the drawer's own pop popping the screen.
  void _onPushedAdminDestinationSelected(AdminDrawerDestination destination) {
    Navigator.pop(context); // close drawer
    Navigator.pop(context); // pop the current admin destination screen
    _navigateToAdminDestination(destination);
  }

  /// Central admin-drawer router (nav-drawer-admin.md §5.2). Every row pushes
  /// its destination onto the navigator stack.
  void _navigateToAdminDestination(AdminDrawerDestination destination) {
    final Widget screen;
    final adminName = widget.userProfile.displayName;
    switch (destination) {
      case AdminDrawerDestination.brandManagement:
        _navigateToAdminBrands();
        return;
      case AdminDrawerDestination.dashboard:
        screen = AdminDashboardScreen(
          adminName: adminName,
          onDestinationSelected: _onPushedAdminDestinationSelected,
          onLogout: _onAdminScreenLogout,
        );
      case AdminDrawerDestination.reports:
        screen = ReportsScreen(
          adminName: adminName,
          onDestinationSelected: _onPushedAdminDestinationSelected,
          onLogout: _onAdminScreenLogout,
        );
      case AdminDrawerDestination.systemSettings:
        screen = SystemSettingsScreen(
          adminName: adminName,
          onDestinationSelected: _onPushedAdminDestinationSelected,
          onLogout: _onAdminScreenLogout,
        );
      case AdminDrawerDestination.productScans:
        screen = ProductScansScreen(
          adminName: adminName,
          onDestinationSelected: _onPushedAdminDestinationSelected,
          onLogout: _onAdminScreenLogout,
        );
      case AdminDrawerDestination.communityManagement:
        screen = CommunityManagementScreen(
          adminName: adminName,
          onDestinationSelected: _onPushedAdminDestinationSelected,
          onLogout: _onAdminScreenLogout,
        );
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// Logout from a pushed Tier-3 admin screen: the screen has already closed
  /// its own drawer; pop it back to MainContainer, then surface the standard
  /// logout confirmation. Mirrors [_onAdminBrandsLogout].
  void _onAdminScreenLogout() {
    Navigator.pop(context);
    showLogoutDialog(
      context,
      onConfirmed: () => widget.onProfileUpdated(const UserProfile()),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductWizard(
          allergens: widget.allergens,
          onReturnToCommunity: () {
            Navigator.pop(context);
            _onNavIndexChanged(2);
          },
        ),
      ),
    );
  }

  void _navigateToAdminBrands() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBrandsScreen(
          client: Supabase.instance.client,
          onLogout: _onAdminBrandsLogout,
          onDestinationSelected: _onPushedAdminDestinationSelected,
        ),
      ),
    );
  }

  void _onAdminBrandsLogout() {
    // AdminBrandsScreen already closed its drawer; pop it back to
    // MainContainer and then surface the standard logout confirmation.
    Navigator.pop(context);
    showLogoutDialog(
      context,
      onConfirmed: () => widget.onProfileUpdated(const UserProfile()),
    );
  }

  void _handleLogout() {
    Navigator.pop(context); // close drawer first
    showLogoutDialog(
      context,
      onConfirmed: () => widget.onProfileUpdated(const UserProfile()),
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
              // Screen-reader label for this icon-only control (a11y, #80).
              tooltip: 'תפריט',
              onPressed: () => widget.userProfile.isAdmin
                  ? Scaffold.of(context).openEndDrawer()
                  : Scaffold.of(context).openDrawer(),
            ),
          ),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        drawer: widget.userProfile.isAdmin
            ? null
            : Drawer(
                child: DrawerUserScreen(
                  onDestinationSelected: _onDrawerDestinationSelected,
                  userName: widget.userProfile.displayName,
                  onLogout: _handleLogout,
                ),
              ),
        endDrawer: widget.userProfile.isAdmin
            ? AdminNavigationDrawer(
                adminName: widget.userProfile.displayName,
                onDestinationSelected: _onAdminDestinationSelected,
                onLogout: _handleLogout,
                // Pinned to dashboard ("first opened from home", §5.4). Only
                // one Tier-2 destination is wired today, so there is no
                // in-app admin navigation state to reflect yet. When Tier-3
                // admin screens are routed, track the live destination in
                // MainContainerState and pass it here instead.
                // TODO(#21): reflect live admin destination once Tier-3 admin
                // screens are routed.
                activeDestination: AdminDrawerDestination.dashboard,
                appVersion: _appVersion,
              )
            : null,
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
              recentActivity: _recentActivity,
              isLoading: _scanHistory == null,
            ),
            SearchScanScreen(
              userProfile: widget.userProfile,
              allergens: widget.allergens,
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              onProfileUpdated: widget.onProfileUpdated,
            ),
            CommunityScreen(
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              allergens: widget.allergens,
              onAddProductTap: _navigateToAddProduct,
            ),
            FavoritesScreen(
              userProfile: widget.userProfile,
              currentNavIndex: _currentIndex,
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