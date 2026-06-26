import 'package:flutter/material.dart';

import '../models/user_contribution.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Small status pill for a user's review / contribution row: approved (green),
/// pending (caution), rejected (avoid). Reuses the app's semantic status
/// palette so it reads consistently with [StatusBadge].
class ContributionStatusPill extends StatelessWidget {
  final ContributionStatus status;

  const ContributionStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      ContributionStatus.approved => (
          context.colors.safeBackground,
          context.colors.safeText,
          Icons.check_circle,
        ),
      ContributionStatus.pending => (
          context.colors.cautionBackground,
          context.colors.cautionText,
          Icons.schedule,
        ),
      ContributionStatus.rejected => (
          context.colors.avoidBackground,
          context.colors.avoidText,
          Icons.cancel,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 14),
          const SizedBox(width: 4),
          Text(
            status.labelHe,
            style: AppTypography.labelSmBold.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
