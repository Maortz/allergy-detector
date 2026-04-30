import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import 'home_screen.dart';
import 'search_scan_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'admin_brands_screen.dart';
import 'contact_screen.dart';
import 'drawer_user_screen.dart';
import '../theme/app_colors.dart';

class MainContainer extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;

  const MainContainer({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  void _onNavIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onDrawerItemSelected(int index) {
    final mapping = {
      0: 3,  // Profile -> Settings
      3: 2,  // Community Review -> Community
    };
    if (!mapping.containsKey(index)) {
      Navigator.pop(context);
      return;
    }
    final tabIndex = mapping[index]!;
    _onNavIndexChanged(tabIndex);
    Navigator.pop(context);
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
      MaterialPageRoute(builder: (context) => const AdminBrandsScreen()),
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
            onItemSelected: _onDrawerItemSelected,
            disabledIndices: const {1, 2, 4, 5},
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
            SettingsScreen(
              userProfile: widget.userProfile,
              allergens: widget.allergens,
              onProfileUpdated: widget.onProfileUpdated,
              currentNavIndex: _currentIndex,
              onNavIndexChanged: _onNavIndexChanged,
              onContactTap: _showContactSheet,
              onAdminBrandsTap: _navigateToAdminBrands,
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavIndexChanged,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceVariant,
          backgroundColor: AppColors.surfaceContainer,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'בית',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'סריקה',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'קהילה',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'הגדרות',
            ),
          ],
        ),
      ),
    );
  }
}