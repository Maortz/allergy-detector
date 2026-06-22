import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../models/scan_history_entry.dart';
import '../models/user_profile.dart';
import '../services/scan_history_service.dart';
import 'home_screen.dart';
import 'search_scan_screen.dart';
import '../services/community_review_controller.dart';
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

  /// Current appearance preference + change callback, forwarded to the
  /// settings appearance picker (issue #168). Optional so widget tests that
  /// mount [MainContainer] directly don't have to wire theming.
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

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
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
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

  /// Runtime app version (e.g. "v1.0.0"), shown in the drawer footer
  /// (nav-drawer-admin.md §7.2 / nav-drawer-user.md §4.4). Null until
  /// [PackageInfo.fromPlatform] resolves; the drawer omits the version row
  /// while null.
  String? _appVersion;

  /// The admin drawer row to render with the active style (nav-drawer-admin.md
  /// §5.4 — "the row matching the admin's current screen"). Drives the root
  /// scaffold's [AdminNavigationDrawer.activeDestination]. Defaults to
  /// [AdminDrawerDestination.dashboard] ("pre-selected when the drawer is first
  /// opened from the admin home"); updated as Tier-3 admin screens are pushed
  /// and reset back to dashboard once the admin pops back to the home scaffold.
  AdminDrawerDestination _activeAdminDestination =
      AdminDrawerDestination.dashboard;

  /// The user drawer row to render with the active style (nav-drawer-user.md
  /// §5.3 / DU6 — "the row matching the user's current screen"). Null while the
  /// user is on a bottom-nav tab (no drawer destination is active); set when a
  /// Tier-3 user destination is pushed and reset to null once it is popped, so
  /// reopening the drawer over a pushed destination highlights its row.
  DrawerDestination? _activeUserDestination;

  /// The user drawer's currently-active destination. Exposed publicly so tests
  /// can assert the live destination tracking without reaching into the drawer's
  /// render tree (mirrors [activeAdminDestination]).
  DrawerDestination? get activeUserDestination => _activeUserDestination;

  /// The admin drawer's currently-active destination. Exposed publicly so tests
  /// can assert the live destination tracking without reaching into the drawer's
  /// render tree (mirrors [currentIndex]).
  AdminDrawerDestination get activeAdminDestination => _activeAdminDestination;

  /// Persisted recent scans, loaded from [ScanHistoryService]. `null` until the
  /// first load resolves — while null the home feed shows its loading state;
  /// once loaded, an empty list renders the no-scans empty state. Spec ref:
  /// `home-dashboard.md §5`.
  List<ScanHistoryEntry>? _scanHistory;

  /// Live peer-review data source for the Community tab (issue #54). Null when
  /// Supabase hasn't been initialised (e.g. widget tests that pump
  /// [MainContainer] without bootstrapping Supabase) — the Community screen
  /// then falls back to its own debug-stub / empty queue.
  CommunityReviewController? _reviewController;

  /// Live community stat-card counts (issue #263). Null while the first load is
  /// in flight (drives the Community tab's loading `--`); [_communityStatsError]
  /// flips to true on a failed load (drives the `?` error glyph).
  int? _verifiedCount;
  int? _addedCount;
  bool _communityStatsLoading = true;
  bool _communityStatsError = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion(); // needed for both admin drawer footer and user drawer footer (DU10)
    _loadScanHistory();
    // `Supabase.instance` asserts when uninitialised (debug/test builds), so
    // guard the access — widget tests pump [MainContainer] without
    // bootstrapping Supabase and must not crash.
    try {
      _reviewController =
          CommunityReviewController(Supabase.instance.client);
    } catch (_) {
      _reviewController = null;
    }
    // Load live community stats when a controller is available; without one
    // (no Supabase, e.g. widget tests) leave the cards in a settled empty
    // state rather than a perpetual loading dash.
    if (_reviewController != null) {
      _loadCommunityStats();
    } else {
      _communityStatsLoading = false;
    }
  }

  Future<void> _loadCommunityStats() async {
    final controller = _reviewController;
    if (controller == null) return;
    try {
      final stats = await controller.fetchStats();
      if (!mounted) return;
      setState(() {
        _verifiedCount = stats.verified;
        _addedCount = stats.added;
        _communityStatsLoading = false;
        _communityStatsError = false;
      });
    } catch (e) {
      debugPrint('community stats load failed: $e');
      if (!mounted) return;
      setState(() {
        _communityStatsLoading = false;
        _communityStatsError = true;
      });
    }
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
    // DU6 — record the pushed destination as active so reopening the drawer over
    // it highlights its row; reset to null once the route is popped.
    setState(() => _activeUserDestination = destination);
    final Widget screen;
    switch (destination) {
      case DrawerDestination.profile:
        screen = SettingsScreen(
          userProfile: widget.userProfile,
          allergens: widget.allergens,
          onProfileUpdated: widget.onProfileUpdated,
          currentNavIndex: _currentIndex,
          onNavIndexChanged: _onNavIndexChanged,
          onContactTap: _showContactSheet,
          onAdminBrandsTap: _navigateToAdminBrands,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      case DrawerDestination.scanHistory:
        screen = const ScanHistoryScreen();
      case DrawerDestination.savedProducts:
        screen = SavedProductsScreen(userProfile: widget.userProfile);
      case DrawerDestination.myReviews:
        screen = const MyReviewsScreen();
      case DrawerDestination.helpCenter:
        screen = HelpCenterScreen(
          onContactTap: () {
            Navigator.pop(context);
            _showContactSheet();
          },
        );
      case DrawerDestination.about:
        screen = const AboutScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _resetActiveUserDestination());
  }

  /// Clears the user drawer's active row once a pushed Tier-3 destination is
  /// popped back to the bottom-nav scaffold (nav-drawer-user.md §5.3 — no row is
  /// pre-selected from a bottom-nav tab).
  void _resetActiveUserDestination() {
    if (!mounted || _activeUserDestination == null) return;
    setState(() => _activeUserDestination = null);
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
  /// The pushed screen has already closed its own drawer (its drawer belongs to
  /// that screen's `Scaffold`, not to MainContainer's), so we only pop the
  /// screen route itself before pushing the next destination. This keeps the
  /// back stack flat (one admin screen at a time) instead of growing it on
  /// every cross-navigation.
  void _onPushedAdminDestinationSelected(AdminDrawerDestination destination) {
    Navigator.pop(context); // pop the current admin destination screen
    _navigateToAdminDestination(destination);
  }

  /// Central admin-drawer router (nav-drawer-admin.md §5.2). Every row pushes
  /// its destination onto the navigator stack and records it as the live
  /// [_activeAdminDestination] so the root drawer highlights the current screen
  /// (§5.4).
  void _navigateToAdminDestination(AdminDrawerDestination destination) {
    setState(() => _activeAdminDestination = destination);
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _resetActiveAdminDestination());
  }

  /// Restores the root drawer's active row to the admin home default once a
  /// pushed Tier-3 screen is popped (nav-drawer-admin.md §5.4 — dashboard is
  /// pre-selected at the admin home). A pushed screen owns its own drawer with
  /// its own active row; the root scaffold reflects "home" again on return.
  void _resetActiveAdminDestination() {
    if (!mounted ||
        _activeAdminDestination == AdminDrawerDestination.dashboard) {
      return;
    }
    setState(() => _activeAdminDestination = AdminDrawerDestination.dashboard);
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
    ).then((_) => _resetActiveAdminDestination());
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
                  appVersion: _appVersion,       // DU10 — version footer
                  // DU6 — highlight the row matching the pushed destination the
                  // drawer is reopened over; null while on a bottom-nav tab
                  // (no row pre-selected per §5.3).
                  activeDestination: _activeUserDestination,
                ),
              ),
        endDrawer: widget.userProfile.isAdmin
            ? AdminNavigationDrawer(
                adminName: widget.userProfile.displayName,
                onDestinationSelected: _onAdminDestinationSelected,
                onLogout: _handleLogout,
                // Reflects the admin's current screen (nav-drawer-admin.md
                // §5.4). Defaults to dashboard ("pre-selected when first opened
                // from the admin home") and tracks the live destination as
                // Tier-3 admin screens are pushed/popped.
                activeDestination: _activeAdminDestination,
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
              onAddProductTap: _navigateToAddProduct,
            ),
            CommunityScreen(
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              allergens: widget.allergens,
              onAddProductTap: _navigateToAddProduct,
              reviewController: _reviewController,
              verifiedCount: _verifiedCount,
              addedCount: _addedCount,
              isLoading: _communityStatsLoading,
              hasError: _communityStatsError,
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