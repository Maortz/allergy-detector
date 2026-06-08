import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Centered empty/error/permission state: icon + title + optional body and a
/// single optional action button. Shared by the search/scan Tier-2 states.
///
/// Action button contract: pass [actionLabel] to render the button. [onAction]
/// must not be set without an [actionLabel] (a callback with no label would be
/// silently dropped — guarded by an assert). Passing [actionLabel] with a null
/// [onAction] is allowed and intentionally renders a disabled button (e.g. a
/// "retrying…" in-flight state).
class StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const StateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  }) : assert(onAction == null || actionLabel != null,
            'actionLabel must be provided when onAction is set');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor ?? AppColors.iconMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMdBold.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
