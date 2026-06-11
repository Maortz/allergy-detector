import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TopAppBar extends StatelessWidget {
  final String? title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final List<Widget>? actions;

  const TopAppBar({
    super.key,
    this.title,
    this.onMenuPressed,
    this.onProfilePressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLow,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.onSurface),
        // Screen-reader label for this icon-only control (a11y, #80).
        tooltip: 'תפריט',
        onPressed: onMenuPressed,
      ),
      title: title != null
          ? Text(
              title!,
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            )
          : null,
      centerTitle: true,
      actions: [
        if (onProfilePressed != null)
          // Announce the icon-only avatar as a labelled button — a bare
          // GestureDetector is invisible to screen readers (a11y, #80).
          Semantics(
            button: true,
            label: 'פרופיל',
            child: GestureDetector(
              onTap: onProfilePressed,
              child: Container(
                margin: const EdgeInsets.only(left: 16),
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.onPrimaryFixed,
                  size: 20,
                ),
              ),
            ),
          ),
        ...?actions,
      ],
    );
  }
}