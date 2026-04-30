import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final AllergenStatus status;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, icon, label) = switch (status) {
      AllergenStatus.safe => (
          AppColors.safeBackground,
          AppColors.safeText,
          Icons.check_circle,
          'בטוח',
        ),
      AllergenStatus.caution => (
          AppColors.cautionBackground,
          AppColors.cautionText,
          Icons.warning,
          'זהירות',
        ),
      AllergenStatus.avoid => (
          AppColors.avoidBackground,
          AppColors.avoidText,
          Icons.dangerous,
          'הימנע',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelBold.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}