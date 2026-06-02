import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AdminDrawerDestination {
  dashboard,
  brandManagement,
  reports,
  systemSettings,
  productScans,
  communityManagement,
}

class _AdminRow {
  final AdminDrawerDestination destination;
  final IconData icon;
  final String label;

  const _AdminRow(this.destination, this.icon, this.label);
}

/// Right-anchored admin drawer (RTL). Caller mounts this widget on the
/// `Scaffold.endDrawer` slot when `UserProfile.isAdmin == true`, so the
/// physical slide-in direction matches the RTL "trailing" edge (right).
/// Mounting on `Scaffold.drawer` would slide from the left and contradict
/// the spec (nav-drawer-admin.md §5.1) regardless of inner Directionality.
class AdminNavigationDrawer extends StatelessWidget {
  final String? adminName;
  final ValueChanged<AdminDrawerDestination> onDestinationSelected;
  final VoidCallback onLogout;
  final AdminDrawerDestination? activeDestination;

  /// App version string (e.g. "v1.0.0"), resolved by the caller via
  /// `PackageInfo.fromPlatform()` (nav-drawer-admin.md §7.2). Nullable so a
  /// caller that has not yet resolved it can pass `null` and the footer row
  /// is simply omitted until the value is available.
  final String? appVersion;

  const AdminNavigationDrawer({
    super.key,
    this.adminName,
    required this.onDestinationSelected,
    required this.onLogout,
    this.activeDestination,
    this.appVersion,
  });

  static const _systemRows = [
    _AdminRow(AdminDrawerDestination.dashboard, Icons.dashboard, 'לוח בקרה'),
    _AdminRow(AdminDrawerDestination.brandManagement, Icons.factory, 'ניהול מותגים'),
    _AdminRow(AdminDrawerDestination.reports, Icons.report, 'דיווחים'),
    _AdminRow(AdminDrawerDestination.systemSettings, Icons.settings, 'הגדרות מערכת'),
  ];

  static const _contentRows = [
    // Spec §3 row 5 names `barcode_scanner`, but that constant is not defined
    // in the bundled Material icon set (Flutter 3.41); `barcode_reader` is the
    // only available barcode glyph and renders the equivalent scanning device.
    _AdminRow(AdminDrawerDestination.productScans, Icons.barcode_reader, 'סריקות מוצרים'),
    _AdminRow(AdminDrawerDestination.communityManagement, Icons.group, 'ניהול קהילה'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: AppColors.surfaceContainerLowest,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    _buildSectionLabel('ניהול מערכת'),
                    ..._systemRows.map(_buildRow),
                    _buildSectionLabel('ניהול תוכן'),
                    ..._contentRows.map(_buildRow),
                  ],
                ),
              ),
              _buildLogout(),
              if (appVersion != null) _buildVersion(appVersion!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.onPrimaryFixed,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'שלום, ${adminName ?? 'מנהל'}',
                  style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildRoleChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryFixedDim),
      ),
      child: Text(
        'מנהל מערכת',
        style: AppTypography.labelSm.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(_AdminRow row) {
    final isActive = row.destination == activeDestination;
    return ListTile(
      leading: Icon(
        row.icon,
        color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
      title: Text(
        row.label,
        style: AppTypography.bodyMd.copyWith(
          color: isActive ? AppColors.primary : AppColors.onSurface,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
      selected: isActive,
      selectedTileColor: AppColors.primaryFixed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onTap: () => onDestinationSelected(row.destination),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('התנתקות'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.destructiveSubtle,
            foregroundColor: AppColors.onDestructiveSubtle,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersion(String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        version,
        textAlign: TextAlign.center,
        style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
