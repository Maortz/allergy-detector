import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';
import '../utils/photo_source_picker.dart';
import 'feedback_success_screen.dart';

// ── Issue-type data ──────────────────────────────────────────────────────────

class _IssueType {
  final String key;
  final String label;
  final IconData icon;

  const _IssueType({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const _kIssueTypes = [
  _IssueType(
    key: 'allergens_wrong',
    label: 'אלרגנים שגויים',
    icon: Icons.warning_amber,
  ),
  _IssueType(
    key: 'ingredients_wrong',
    label: 'רכיבים לא נכונים',
    icon: Icons.list_alt,
  ),
  _IssueType(
    key: 'image_mismatch',
    label: 'תמונה לא תואמת',
    icon: Icons.image_not_supported,
  ),
  _IssueType(key: 'other', label: 'אחר', icon: Icons.more_horiz),
];

// ── Widget ───────────────────────────────────────────────────────────────────

class FeedbackScreen extends StatefulWidget {
  final String productId;
  final String productName;

  /// Barcode string (e.g. "7290001234567"). When null the barcode row in the
  /// product-context card is omitted.
  final String? productBarcode;

  /// Network URL for the product thumbnail. When null a fallback icon is shown.
  final String? productImageUrl;

  final Future<void> Function(String type, String message, XFile? image)
  onSubmit;

  const FeedbackScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productBarcode,
    required this.productImageUrl,
    required this.onSubmit,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();

  /// Radio-group state — always one chip selected. Spec §6.2 default.
  String _selectedType = 'allergens_wrong';

  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        _selectedType,
        _messageController.text.trim(), // may be empty — field is optional
        _selectedImage,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FeedbackSuccessScreen(
              onHome: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('FeedbackScreen submit failed: $e\n$st');
      if (mounted) {
        AppToast.error(context, 'שגיאה בשליחת המשוב. נסה שנית.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Image pick ─────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await showPhotoSourcePicker(context);
    if (source == null) return;
    final file = await _picker.pickImage(source: source);
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
    }
  }

  void _clearImage() => setState(() => _selectedImage = null);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surfaceContainerLowest,
          elevation: 0,
          title: const Text('דיווח על שגיאה'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: colorScheme.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // SafeArea guards the bottom system inset (Android nav bar / gesture
        // pill) so the trailing "ביטול" button can never come to rest behind
        // it. Without this the last child sat under the nav bar with only the
        // gutter as padding, appearing off-screen on short viewports (#334).
        // top:false — the AppBar already consumes the top inset.
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductContextCard(
                  productName: widget.productName,
                  productBarcode: widget.productBarcode,
                  productImageUrl: widget.productImageUrl,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeading('מה הסיבה לדיווח?'),
                const SizedBox(height: AppSpacing.sm),
                _IssueChipGrid(
                  selected: _selectedType,
                  onSelect: (key) => setState(() => _selectedType = key),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeading('פרטים נוספים (אופציונלי)'),
                const SizedBox(height: AppSpacing.sm),
                _DetailsTextField(controller: _messageController),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeading('העלאת תמונה'),
                const SizedBox(height: AppSpacing.sm),
                _PhotoUploadZone(
                  selectedImage: _selectedImage,
                  onTap: _pickImage,
                  onClear: _clearImage,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SubmitButton(isSubmitting: _isSubmitting, onPressed: _submit),
                const SizedBox(height: AppSpacing.sm),
                // Secondary "ביטול" action — pops without submitting (§5.6, #219).
                _CancelButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Section heading — Inter SemiBold 13 pt, #1F2937. Spec §4.3.
class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyXs.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Product context card — thumbnail + name + optional barcode. Spec §4.2.
class _ProductContextCard extends StatelessWidget {
  final String productName;
  final String? productBarcode;
  final String? productImageUrl;

  const _ProductContextCard({
    required this.productName,
    required this.productBarcode,
    required this.productImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Row(
        children: [
          // Thumbnail (RTL: right side)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: productImageUrl != null
                  ? Image.network(
                      productImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, err, st) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (productBarcode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    productBarcode!,
                    style: AppTypography.labelSm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Icon(Icons.fastfood, color: context.colors.iconMuted, size: 24),
    );
  }
}

/// 2×2 radio-group chip grid. Spec §4.4.
class _IssueChipGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _IssueChipGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final chipWidth = (screenWidth - 48) / 2; // 16 margin + 8 gap + 16 margin

    // Spec RTL grid order: row1 = allergens_wrong | ingredients_wrong
    //                      row2 = other           | image_mismatch
    final row1 = [_kIssueTypes[0], _kIssueTypes[1]];
    final row2 = [_kIssueTypes[3], _kIssueTypes[2]];

    Widget buildRow(List<_IssueType> types) => Row(
      children: [
        for (int i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          _IssueChip(
            type: types[i],
            isSelected: selected == types[i].key,
            width: chipWidth,
            onTap: () => onSelect(types[i].key),
          ),
        ],
      ],
    );

    return Column(
      children: [
        buildRow(row1),
        const SizedBox(height: AppSpacing.sm),
        buildRow(row2),
      ],
    );
  }
}

/// Single issue-type chip. Spec §4.4.
class _IssueChip extends StatelessWidget {
  final _IssueType type;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _IssueChip({
    required this.type,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.primaryTint
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : appColors.borderSubtle,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              size: 22,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: AppTypography.bodyXs.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-line optional details field. Spec §4.5.
class _DetailsTextField extends StatelessWidget {
  final TextEditingController controller;
  const _DetailsTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      minLines: 4,
      maxLines: null,
      decoration: InputDecoration(
        hintText: 'תאר את הבעיה שמצאת...',
        hintStyle: AppTypography.bodyXs.copyWith(color: appColors.iconMuted),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// Photo upload zone — dashed border empty / thumbnail filled. Spec §4.6, §5.3.
class _PhotoUploadZone extends StatelessWidget {
  final XFile? selectedImage;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _PhotoUploadZone({
    required this.selectedImage,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null) {
      return _ThumbnailZone(image: selectedImage!, onClear: onClear);
    }
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appColors.borderSubtle,
            // Dashed border via a custom painter is heavy; use a solid border
            // at reduced opacity — spec allows this as a visual approximation
            // since Flutter's Border class does not support dashed strokes
            // natively. The picker icon + copy make the affordance clear.
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              'צלם תמונה של תווית המוצר',
              style: AppTypography.bodyXs.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'העלאת תמונה של רכיבים ואלרגנים תאמת את הדיווח',
              style: AppTypography.labelSm.copyWith(
                color: appColors.iconMuted,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail state of the photo upload zone. Spec §5.3 "Image selected".
class _ThumbnailZone extends StatelessWidget {
  final XFile image;
  final VoidCallback onClear;

  const _ThumbnailZone({required this.image, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 88,
            width: double.infinity,
            child: kIsWeb
                ? ColoredBox(color: appColors.primaryTintBorder)
                : Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, err, st) =>
                        ColoredBox(color: appColors.primaryTintBorder),
                  ),
          ),
        ),
        // Clear (X) button at top-trailing corner — direction-aware (§4.6, §5.3).
        PositionedDirectional(
          top: AppSpacing.xs,
          end: AppSpacing.xs,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: appColors.closeButtonOverlay,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: colorScheme.onPrimary, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width primary submit button. Spec §4.7.
class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Icon(Icons.send, size: 18, color: colorScheme.onPrimary),
        label: const Text('שלח דיווח לבדיקה'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Full-width secondary cancel button — pops the route. Issue #219, spec §5.6.
class _CancelButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: context.colors.borderSubtle, width: 1.5),
          textStyle: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('ביטול'),
      ),
    );
  }
}
