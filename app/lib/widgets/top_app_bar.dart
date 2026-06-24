import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surfaceContainerLow,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: colorScheme.onSurface),
        // Screen-reader label for this icon-only control (a11y, #80).
        tooltip: 'תפריט',
        onPressed: onMenuPressed,
      ),
      title: title != null
          ? Text(
              title!,
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
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
                decoration: BoxDecoration(
                  color: colorScheme.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryFixed,
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