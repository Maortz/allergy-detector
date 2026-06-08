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
  final String? userSubtitle;
  final VoidCallback? onLogout;
  final ValueChanged<DrawerDestination>? onDestinationSelected;

  const DrawerUserScreen({
    super.key,
    this.userName,
    this.userSubtitle,
    this.onLogout,
    this.onDestinationSelected,
  });

  static const List<_DrawerRow> _rows = [
    _DrawerRow(
      destination: DrawerDestination.profile,
      icon: Icons.person_outline,
      label: 'פרופיל',
    ),
    _DrawerRow(
      destination: DrawerDestination.scanHistory,
      icon: Icons.history,
      label: 'היסטוריית סריקה',
    ),
    _DrawerRow(
      destination: DrawerDestination.savedProducts,
      icon: Icons.bookmark_outline,
      label: 'מוצרים שמורים',
    ),
    _DrawerRow(
      destination: DrawerDestination.myReviews,
      icon: Icons.rate_review_outlined,
      label: 'ביקורות שלי',
    ),
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
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildNavItems(),
          const Spacer(),
          _buildLogout(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(color: AppColors.surfaceContainer),
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
              Icons.person,
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
                  userName ?? 'משתמש',
                  style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  userSubtitle ?? 'חבר קהילה',
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

  Widget _buildNavItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: _rows.map((row) {
          return ListTile(
            leading: Icon(row.icon, color: AppColors.onSurfaceVariant),
            title: Text(
              row.label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            ),
            trailing: const Icon(
              Icons.chevron_left,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            onTap: () => onDestinationSelected?.call(row.destination),
          );
        }).toList(),
      ),
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
}
