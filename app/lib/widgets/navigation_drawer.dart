import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final VoidCallback? onLogout;

  const NavigationDrawer({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: Column(
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.onPrimaryFixed,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'אורח',
                  style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'הגדר את האלרגיות שלך',
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
    final items = [
      {'icon': Icons.home, 'label': 'בית'},
      {'icon': Icons.qr_code_scanner, 'label': 'סריקה'},
      {'icon': Icons.groups, 'label': 'קהילה'},
      {'icon': Icons.favorite, 'label': 'מועדפים'},
      {'icon': Icons.settings, 'label': 'הגדרות'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == selectedIndex;

          return ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            title: Text(
              item['label'] as String,
              style: AppTypography.bodyMd.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isSelected,
            selectedTileColor: AppColors.primaryFixed.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            onTap: () => onItemSelected?.call(index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: AppColors.error,
        ),
        title: Text(
          'יציאה',
          style: AppTypography.bodyMd.copyWith(color: AppColors.error),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onLogout,
      ),
    );
  }
}