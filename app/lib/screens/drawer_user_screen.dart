import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class DrawerUserScreen extends StatelessWidget {
  final String? userName;
  final String? userSubtitle;
  final VoidCallback? onLogout;
  final ValueChanged<int>? onItemSelected;
  final Set<int> disabledIndices;

  const DrawerUserScreen({
    super.key,
    this.userName,
    this.userSubtitle,
    this.onLogout,
    this.onItemSelected,
    this.disabledIndices = const {},
  });

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
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
      ),
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
    final items = [
      {'icon': Icons.person_outline, 'label': 'פרופיל'},
      {'icon': Icons.history, 'label': 'היסטוריה'},
      {'icon': Icons.bookmark_outline, 'label': 'מוצרים שמורים'},
      {'icon': Icons.rate_review_outlined, 'label': 'ביקורת קהילה'},
      {'icon': Icons.help_outline, 'label': 'מרכז עזרה'},
      {'icon': Icons.info_outline, 'label': 'אודות'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isDisabled = disabledIndices.contains(index);

          return ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: isDisabled
                  ? AppColors.onSurfaceVariant.withValues(alpha: 0.4)
                  : AppColors.onSurfaceVariant,
            ),
            title: Text(
              item['label'] as String,
              style: AppTypography.bodyMd.copyWith(
                color: isDisabled
                    ? AppColors.onSurface.withValues(alpha: 0.4)
                    : AppColors.onSurface,
              ),
            ),
            trailing: Icon(
              Icons.chevron_left,
              color: isDisabled
                  ? AppColors.onSurfaceVariant.withValues(alpha: 0.4)
                  : AppColors.onSurfaceVariant,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            onTap: isDisabled ? null : () => onItemSelected?.call(index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogout() {
    return Container(
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