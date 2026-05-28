import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_nav_bar.dart';

class FeedbackSuccessScreen extends StatelessWidget {
  final VoidCallback onHome;

  /// Called when the user taps a tab in the bottom nav. Receives the tapped
  /// index so the host can route to that tab. If null, all nav taps fall
  /// back to [onHome] (the spec-incorrect "collapse to Home" behaviour).
  final ValueChanged<int>? onNavTap;

  const FeedbackSuccessScreen({
    super.key,
    required this.onHome,
    this.onNavTap,
  });

  void _goHome() => onHome();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'דיווח נשלח',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.onSurface),
            onPressed: _goHome,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildSuccessIcon(),
                const SizedBox(height: AppSpacing.lg),
                _buildHeadline(),
                const SizedBox(height: AppSpacing.md),
                _buildBody(),
                const SizedBox(height: AppSpacing.xl),
                _buildBadgePair(),
                const SizedBox(height: AppSpacing.xl),
                _buildHomeButton(),
                const SizedBox(height: AppSpacing.xl),
                _buildFooter(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: onNavTap ?? (_) => _goHome(),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 72,
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      'הדיווח נשלח בהצלחה!',
      style: AppTypography.h1.copyWith(color: AppColors.primary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'המידע נשלח לבדיקה ויעודכן בקרוב. יחד אנחנו שומרים על הקהילה בטוחה.',
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBadgePair() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(
          icon: Icons.verified,
          label: 'נבדק ע״י מערכת',
          background: AppColors.safeBackground,
          // Spec §4.4: border is a lighter mint (#86EFAC) than the label
          // (#15803D). Approximate without adding new tokens by mirroring
          // the ring on `_buildSuccessIcon` — softer than the dark label.
          border: AppColors.success.withValues(alpha: 0.3),
          iconColor: AppColors.success,
          labelColor: AppColors.safeText,
          radius: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildBadge(
          icon: Icons.groups,
          label: 'קהילה בטוחה',
          background: AppColors.primaryFixed.withValues(alpha: 0.2),
          border: AppColors.primaryFixedDim,
          iconColor: AppColors.primary,
          labelColor: AppColors.onPrimaryFixedVariant,
          radius: 12,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color background,
    required Color border,
    required Color iconColor,
    required Color labelColor,
    required double radius,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: labelColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _goHome,
        icon: const Icon(Icons.home),
        label: const Text('חזרה לדף הבית'),
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

  Widget _buildFooter() {
    return Opacity(
      opacity: 0.6,
      child: Column(
        children: [
          Text(
            'תודה על תרומתך לבטיחות המזון בישראל',
            style: AppTypography.labelSm.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                // Spec §4.6: this footer line is 'בדיקת אלרגנים', not the
                // canonical 'בטוח לאכול' brand. No §7.3 delta reconciles them
                // — align code to spec.
                'בדיקת אלרגנים',
                style: AppTypography.h3.copyWith(color: AppColors.primaryContainer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
