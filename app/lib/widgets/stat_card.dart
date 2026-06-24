import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A white, centred contribution-stat card (community-hub.md §4.3, CH2–CH4).
///
/// Presentational only — the caller decides the displayed [value] (including
/// loading "--" / error "?" placeholders) and the per-card [accentColor]
/// applied to the number and the bottom icon.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(color: accentColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSm
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Icon(icon, color: accentColor, size: 24),
        ],
      ),
    );
  }
}
