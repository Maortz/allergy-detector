import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_nav_bar.dart';
import 'main_container.dart';

class FeedbackSuccessScreen extends StatelessWidget {
  final VoidCallback onHome;

  /// Called when the user taps a tab in the bottom nav. Receives the tapped
  /// index so the host can route to that tab. If null, taps pop back to
  /// [MainContainer] and select the tapped tab via [MainContainer.switchToTab].
  final ValueChanged<int>? onNavTap;

  const FeedbackSuccessScreen({
    super.key,
    required this.onHome,
    this.onNavTap,
  });

  void _goHome() => onHome();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: Text(
            'דיווח נשלח',
            style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
            onPressed: _goHome,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildSuccessIcon(context),
                const SizedBox(height: AppSpacing.lg),
                _buildHeadline(context),
                const SizedBox(height: AppSpacing.md),
                _buildBody(context),
                const SizedBox(height: AppSpacing.xl),
                _buildBadgePair(context),
                const SizedBox(height: AppSpacing.xl),
                _buildHomeButton(context),
                const SizedBox(height: AppSpacing.xl),
                _buildFooter(context),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: onNavTap ?? (i) => MainContainer.switchToTab(context, i),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(
          color: appColors.success.withValues(alpha: 0.3),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.check_circle,
        color: appColors.success,
        size: 72,
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return Text(
      'הדיווח נשלח בהצלחה!',
      style: AppTypography.h1.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'המידע נשלח לבדיקה ויעודכן בקרוב. יחד אנחנו שומרים על הקהילה בטוחה.',
        style: AppTypography.bodyMd.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBadgePair(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(
          icon: Icons.verified,
          label: 'נבדק ע״י מערכת',
          background: appColors.safeBackground,
          // Spec §4.4: border is a lighter mint (#86EFAC) than the label
          // (#15803D). Approximate without adding new tokens by mirroring
          // the ring on `_buildSuccessIcon` — softer than the dark label.
          border: appColors.success.withValues(alpha: 0.3),
          iconColor: appColors.success,
          labelColor: appColors.safeText,
          radius: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildBadge(
          icon: Icons.groups,
          label: 'קהילה בטוחה',
          background: colorScheme.primaryContainer.withValues(alpha: 0.2),
          border: colorScheme.primary,
          iconColor: colorScheme.primary,
          labelColor: colorScheme.onPrimaryContainer,
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

  Widget _buildHomeButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _goHome,
        icon: const Icon(Icons.home),
        label: const Text('חזרה לדף הבית'),
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

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.6,
      child: Column(
        children: [
          Text(
            'תודה על תרומתך לבטיחות המזון בישראל',
            style: AppTypography.labelSm.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety,
                  color: colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                // Spec §4.6: this footer line is 'בדיקת אלרגנים', not the
                // canonical 'בטוח לאכול' brand. No §7.3 delta reconciles them
                // — align code to spec.
                'בדיקת אלרגנים',
                style: AppTypography.h3
                    .copyWith(color: colorScheme.primaryContainer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
