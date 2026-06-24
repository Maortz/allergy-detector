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
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surfaceContainer,
          elevation: 0,
          centerTitle: true,
          title: Text(
            // Spec §3 row 1 / §7.2 resolves the divergence: this screen's
            // brand-bar is 'בטיחות מזון', not the canonical 'בטוח לאכול'.
            'בטיחות מזון',
            style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildCard(context),
                const SizedBox(height: AppSpacing.lg),
                _buildCommunityButton(context),
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

  Widget _buildCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSuccessIcon(context),
          const SizedBox(height: AppSpacing.md),
          Text(
            'המוצר נוסף בהצלחה!',
            style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'המוצר עובר כעת לבדיקת הקהילה. אנו דואגים שכל פריט במאגר שלנו עומד בתקני הבטיחות המחמירים ביותר.',
            style:
                AppTypography.bodySm.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStatusBadgePair(context),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    final appColors = context.colors;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: appColors.success, width: 3),
      ),
      child: Icon(
        // Outline variant per spec §4.1: the surrounding 88pt ring already
        // owns the disc shape; the inner glyph is just the check.
        Icons.check_circle_outline,
        color: appColors.success,
        size: 44,
      ),
    );
  }

  Widget _buildStatusBadgePair(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(
          icon: Icons.pending,
          label: 'ממתין לאישור',
          background: colorScheme.surfaceContainerLow,
          border: colorScheme.outlineVariant,
          foreground: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildBadge(
          icon: Icons.verified_user,
          label: 'סטטוס בדיקה',
          background: colorScheme.primaryContainer,
          border: colorScheme.primaryContainer,
          foreground: colorScheme.primary,
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

  Widget _buildCommunityButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _returnToCommunity,
        icon: const Icon(Icons.groups),
        label: const Text('חזרה לקהילה'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
