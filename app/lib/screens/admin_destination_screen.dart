import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'admin_navigation_drawer.dart';

/// Shared scaffold for the Tier-3 admin-drawer destination screens
/// (nav-drawer-admin.md §3 / §5.2). Each concrete screen below supplies its
/// title, icon and a short Hebrew description; the scaffold wires the shared
/// app bar (menu → endDrawer), the right-anchored [AdminNavigationDrawer] with
/// the correct active row highlighted, and a centred placeholder body.
///
/// The detailed per-screen designs are still pending (index.md marks these
/// rows "needs design"); until then each destination presents a consistent
/// "coming soon" surface so the drawer rows navigate to a real, role-gated
/// screen rather than a dead snackbar.
class AdminDestinationScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final AdminDrawerDestination destination;

  /// Forwarded to [AdminNavigationDrawer]; the host (e.g. `MainContainer`)
  /// drives navigation between admin destinations.
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;

  /// Forwarded to [AdminNavigationDrawer]'s logout button.
  final VoidCallback onLogout;

  final String? adminName;

  const AdminDestinationScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.destination,
    required this.onDestinationSelected,
    required this.onLogout,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'תפריט',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          title: Text(
            title,
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        endDrawer: AdminNavigationDrawer(
          adminName: adminName,
          onDestinationSelected: onDestinationSelected,
          onLogout: onLogout,
          activeDestination: destination,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 72, color: AppColors.onSurfaceVariant),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryTintBorder),
                  ),
                  child: Text(
                    'בקרוב',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// לוח בקרה — admin overview/dashboard (nav-drawer-admin.md §3 row 1).
class AdminDashboardScreen extends StatelessWidget {
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;
  final VoidCallback onLogout;
  final String? adminName;

  const AdminDashboardScreen({
    super.key,
    required this.onDestinationSelected,
    required this.onLogout,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDestinationScaffold(
      title: 'לוח בקרה',
      icon: Icons.dashboard,
      description: 'סקירת מדדי המערכת והפעילות האחרונה תוצג כאן',
      destination: AdminDrawerDestination.dashboard,
      onDestinationSelected: onDestinationSelected,
      onLogout: onLogout,
      adminName: adminName,
    );
  }
}

/// דיווחים — moderation reports queue (nav-drawer-admin.md §3 row 3).
class ReportsScreen extends StatelessWidget {
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;
  final VoidCallback onLogout;
  final String? adminName;

  const ReportsScreen({
    super.key,
    required this.onDestinationSelected,
    required this.onLogout,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDestinationScaffold(
      title: 'דיווחים',
      icon: Icons.report,
      description: 'דיווחי משתמשים על מוצרים ותכנים ינוהלו כאן',
      destination: AdminDrawerDestination.reports,
      onDestinationSelected: onDestinationSelected,
      onLogout: onLogout,
      adminName: adminName,
    );
  }
}

/// הגדרות מערכת — platform-level settings (nav-drawer-admin.md §3 row 4).
class SystemSettingsScreen extends StatelessWidget {
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;
  final VoidCallback onLogout;
  final String? adminName;

  const SystemSettingsScreen({
    super.key,
    required this.onDestinationSelected,
    required this.onLogout,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDestinationScaffold(
      title: 'הגדרות מערכת',
      icon: Icons.settings,
      description: 'הגדרות התצורה של הפלטפורמה ינוהלו כאן',
      destination: AdminDrawerDestination.systemSettings,
      onDestinationSelected: onDestinationSelected,
      onLogout: onLogout,
      adminName: adminName,
    );
  }
}

/// סריקות מוצרים — product-scan moderation (nav-drawer-admin.md §3 row 5).
class ProductScansScreen extends StatelessWidget {
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;
  final VoidCallback onLogout;
  final String? adminName;

  const ProductScansScreen({
    super.key,
    required this.onDestinationSelected,
    required this.onLogout,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDestinationScaffold(
      title: 'סריקות מוצרים',
      icon: Icons.barcode_reader,
      description: 'סקירת מוצרים שנסרקו על ידי המשתמשים תוצג כאן',
      destination: AdminDrawerDestination.productScans,
      onDestinationSelected: onDestinationSelected,
      onLogout: onLogout,
      adminName: adminName,
    );
  }
}

/// ניהול קהילה — community management (nav-drawer-admin.md §3 row 6).
class CommunityManagementScreen extends StatelessWidget {
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;
  final VoidCallback onLogout;
  final String? adminName;

  const CommunityManagementScreen({
    super.key,
    required this.onDestinationSelected,
    required this.onLogout,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDestinationScaffold(
      title: 'ניהול קהילה',
      icon: Icons.group,
      description: 'ניהול תרומות הקהילה והמשתמשים יוצג כאן',
      destination: AdminDrawerDestination.communityManagement,
      onDestinationSelected: onDestinationSelected,
      onLogout: onLogout,
      adminName: adminName,
    );
  }
}
