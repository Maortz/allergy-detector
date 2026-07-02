import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Branded SnackBar / toast helpers.
///
/// Standardizes success / error / info toasts into a small set of themed
/// SnackBars using [AppColors] and [AppTypography]. RTL-correct (leading icon
/// sits at the visual start in an RTL layout) — prefer these over ad-hoc inline
/// `ScaffoldMessenger.showSnackBar` calls.
class AppToast {
  AppToast._();

  /// Green/teal success toast.
  ///
  /// Pass [messenger] when the [context] may be unmounted by the time the toast
  /// fires (e.g. after a `Navigator.pop`): capture it before popping, then call
  /// this with the still-live parent messenger.
  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    ScaffoldMessengerState? messenger,
  }) {
    _show(
      context,
      messenger: messenger,
      message: message,
      background: context.colors.success,
      foreground: context.colors.onSuccess,
      icon: Icons.check_circle_outline,
      action: action,
    );
  }

  /// Red error toast.
  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    ScaffoldMessengerState? messenger,
  }) {
    // Use the theme's ColorScheme so the error toast adapts to dark mode
    // (mirrors the theme-aware success/info toasts). The light scheme maps
    // error/onError to the same values as the former AppColors constants.
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      messenger: messenger,
      message: message,
      background: scheme.error,
      foreground: scheme.onError,
      icon: Icons.error_outline,
      action: action,
    );
  }

  /// Neutral informational toast.
  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    ScaffoldMessengerState? messenger,
  }) {
    // Theme-aware primary so the info toast adapts to dark mode (mirrors the
    // error/success toasts). The light scheme maps primary/onPrimary to the
    // same values as the former AppColors constants.
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      messenger: messenger,
      message: message,
      background: scheme.primary,
      foreground: scheme.onPrimary,
      icon: Icons.info_outline,
      action: action,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required Color foreground,
    required IconData icon,
    SnackBarAction? action,
    ScaffoldMessengerState? messenger,
  }) {
    final m = messenger ?? ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          // SnackBarAction's label color is unset, so M3 falls back to
          // snackBarTheme.actionTextColor (the app's primary blue) — invisible
          // on the info toast, low-contrast on success. Force the toast's own
          // foreground for guaranteed contrast.
          action: action == null
              ? null
              : SnackBarAction(
                  label: action.label,
                  onPressed: action.onPressed,
                  textColor: foreground,
                  disabledTextColor: action.disabledTextColor,
                ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.bodyMd.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
