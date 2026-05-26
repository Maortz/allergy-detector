import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_nav_bar.dart';

class AddProductSuccessScreen extends StatelessWidget {
  final VoidCallback onReturnToCommunity;

  /// Optional per-tab routing for the bottom nav. Receives the tapped index.
  /// If null, all nav taps fall back to [onReturnToCommunity].
  final ValueChanged<int>? onNavTap;

  const AddProductSuccessScreen({
    super.key,
    required this.onReturnToCommunity,
    this.onNavTap,
  });

  void _returnToCommunity() => onReturnToCommunity();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.surfaceContainer,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'בטוח לאכול',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildCommunityButton(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
          onTap: onNavTap ?? (_) => _returnToCommunity(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSuccessIcon(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'המוצר נוסף בהצלחה!',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'המוצר עובר כעת לבדיקת הקהילה. אנו דואגים שכל פריט במאגר שלנו עומד בתקני הבטיחות המחמירים ביותר.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStatusBadgePair(),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 3),
      ),
      child: const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 44,
      ),
    );
  }

  Widget _buildStatusBadgePair() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(
          icon: Icons.pending,
          label: 'ממתין לאישור',
          background: AppColors.surfaceContainerLow,
          border: AppColors.outlineVariant,
          foreground: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildBadge(
          icon: Icons.verified_user,
          label: 'סטטוס בדיקה',
          background: AppColors.primaryFixed,
          border: AppColors.primaryFixedDim,
          foreground: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color background,
    required Color border,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _returnToCommunity,
        icon: const Icon(Icons.groups),
        label: const Text('חזרה לקהילה'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
