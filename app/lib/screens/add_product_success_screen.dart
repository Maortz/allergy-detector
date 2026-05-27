import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_nav_bar.dart';

/// Terminal confirmation screen for the Add-Product wizard. Per
/// `add-product-success.md` §1, this replaces the wizard after a successful
/// save — the back stack is the caller's responsibility (typically
/// `pushAndRemoveUntil` so hardware-back cannot re-enter the wizard).
class AddProductSuccessScreen extends StatelessWidget {
  /// Tap handler for "חזרה לקהילה". Caller routes back to the Community tab
  /// (index 2 of `MainContainer`'s nav).
  final VoidCallback onReturnToCommunity;

  /// Tap handler for the bottom nav. Receives the tapped index. When null,
  /// nav taps fall back to [onReturnToCommunity].
  final ValueChanged<int>? onNavTap;

  const AddProductSuccessScreen({
    super.key,
    required this.onReturnToCommunity,
    this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'בטוח לאכול',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                _SuccessCard(),
                const SizedBox(height: AppSpacing.lg),
                _ReturnButton(onPressed: onReturnToCommunity),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
          onTap: onNavTap ?? (_) => onReturnToCommunity(),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _SuccessIllustration(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'המוצר נוסף בהצלחה!',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'המוצר עובר כעת לבדיקת הקהילה. אנו דואגים שכל פריט במאגר '
            'שלנו עומד בתקני הבטיחות המחמירים ביותר.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusBadgePair(),
        ],
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 2.5),
      ),
      child: const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 44,
      ),
    );
  }
}

class _StatusBadgePair extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusBadge(
          icon: Icons.pending,
          label: 'ממתין לאישור',
          background: AppColors.surfaceContainerLow,
          foreground: AppColors.onSurfaceVariant,
          borderColor: AppColors.surfaceContainerLow,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatusBadge(
          icon: Icons.verified_user,
          label: 'סטטוס בדיקה',
          background: AppColors.primaryFixed,
          foreground: AppColors.primary,
          borderColor: AppColors.primaryFixedDim,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
}

class _ReturnButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReturnButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
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
