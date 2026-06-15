import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum DrawerDestination {
  profile,
  scanHistory,
  savedProducts,
  myReviews,
  helpCenter,
  about,
}

class _DrawerRow {
  final DrawerDestination destination;
  final IconData icon;
  final String label;

  const _DrawerRow({
    required this.destination,
    required this.icon,
    required this.label,
  });
}

class DrawerUserScreen extends StatelessWidget {
  final String? userName;
  /// Subtitle shown under the greeting. Defaults to "בטוח לאכול" per spec §4.1 / DU4.
  final String? subtitle;
  final VoidCallback? onLogout;
  final ValueChanged<DrawerDestination>? onDestinationSelected;
  /// The currently active destination — drives the row highlight (DU6).
  final DrawerDestination? activeDestination;
  /// App version string (e.g. "v1.0.0") from PackageInfo, shown in the
  /// footer (DU10 / DD-14). Null → footer version row omitted.
  final String? appVersion;

  const DrawerUserScreen({
    super.key,
    this.userName,
    this.subtitle,
    this.onLogout,
    this.onDestinationSelected,
    this.activeDestination,
    this.appVersion,
  });

  // Group 1: main navigation rows (פרופיל → ביקורות שלי)
  static const List<_DrawerRow> _mainRows = [
    _DrawerRow(
      destination: DrawerDestination.profile,
      icon: Icons.person_outline,
      label: 'פרופיל',
    ),
    _DrawerRow(
      destination: DrawerDestination.scanHistory,
      icon: Icons.history,
      label: 'היסטוריית סריקה',       // DU12
    ),
    _DrawerRow(
      destination: DrawerDestination.savedProducts,
      icon: Icons.bookmark_outline,
      label: 'מוצרים שמורים',
    ),
    _DrawerRow(
      destination: DrawerDestination.myReviews,
      icon: Icons.rate_review_outlined,
      label: 'ביקורות שלי',            // DU8
    ),
  ];

  // Group 2: utility rows (מרכז עזרה, אודות) — separated by a Divider (DU7)
  static const List<_DrawerRow> _utilityRows = [
    _DrawerRow(
      destination: DrawerDestination.helpCenter,
      icon: Icons.help_outline,
      label: 'מרכז עזרה',
    ),
    _DrawerRow(
      destination: DrawerDestination.about,
      icon: Icons.info_outline,
      label: 'אודות',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLowest, // DU11 — white
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    ..._mainRows.map(_buildRow),
                    // DU7 — divider between the two row groups
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E7EB),
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                    ),
                    ..._utilityRows.map(_buildRow),
                  ],
                ),
              ),
              _buildLogout(),
              if (appVersion != null) _buildVersion(appVersion!), // DU10
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
          // Avatar: fallback to person silhouette on E5E7EB bg per §4.1 / DU5
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE5E7EB),
            child: const Icon(
              Icons.person,
              color: Color(0xFF9CA3AF),
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DU3 — "שלום, [name]" with fixed greeting prefix
                Text(
                  'שלום, ${userName ?? 'משתמש'}',
                  style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                // DU4 — default subtitle is "בטוח לאכול" per spec §4.1
                Text(
                  subtitle ?? 'בטוח לאכול',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_DrawerRow row) {
    final isActive = row.destination == activeDestination; // DU6
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
      selectedTileColor: AppColors.primaryTint, // DU6 — #EBF4FF
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onTap: () => onDestinationSelected?.call(row.destination),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: onLogout,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.destructiveSubtle,
            foregroundColor: AppColors.onDestructiveSubtle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.logout, size: 20),
          label: Text(
            'התנתקות',
            style: AppTypography.labelBold,
          ),
        ),
      ),
    );
  }

  // DU10 — footer version row (DD-14: centred version string)
  Widget _buildVersion(String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        version,
        textAlign: TextAlign.center,
        style: AppTypography.labelSm.copyWith(color: AppColors.iconMuted),
      ),
    );
  }
}
