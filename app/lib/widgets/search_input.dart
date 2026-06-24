import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onTap;
  final bool readOnly;

  const SearchInput({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'חפש מוצר או מרכיב...',
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMd
              .copyWith(color: colorScheme.onSurfaceVariant),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
            child: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}