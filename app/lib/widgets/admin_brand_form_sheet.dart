import 'dart:async';
import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/brand_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_dialogs.dart';
import '../utils/app_toast.dart';

Future<bool> showBrandFormSheet(
  BuildContext context, {
  Brand? brand,
  required BrandService brandService,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _BrandFormSheetContent(
      brand: brand,
      brandService: brandService,
    ),
  );
  return result ?? false;
}

class _BrandFormSheetContent extends StatefulWidget {
  final Brand? brand;
  final BrandService brandService;

  const _BrandFormSheetContent({
    this.brand,
    required this.brandService,
  });

  @override
  State<_BrandFormSheetContent> createState() => _BrandFormSheetContentState();
}

class _BrandFormSheetContentState extends State<_BrandFormSheetContent> {
  late TextEditingController _nameController;
  late TextEditingController _logoUrlController;
  late TextEditingController _notesController;
  bool _isVerified = false;
  String? _previewUrl;
  Timer? _debounce;
  bool _isSaving = false;

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand?.name ?? '');
    _logoUrlController =
        TextEditingController(text: widget.brand?.logoUrl ?? '');
    _notesController = TextEditingController(text: widget.brand?.notes ?? '');
    _isVerified = widget.brand?.isVerified ?? false;
    _previewUrl = widget.brand?.logoUrl;
    _nameController.addListener(() => setState(() {}));
    _logoUrlController.addListener(_onLogoUrlChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _logoUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onLogoUrlChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _previewUrl = _logoUrlController.text.trim().isEmpty
          ? null
          : _logoUrlController.text.trim());
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final b = Brand(
        id: widget.brand?.id,
        name: _nameController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        isVerified: _isVerified,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await widget.brandService.saveBrand(b);
      if (mounted) {
        // Capture the messenger before popping so the toast attaches to the
        // parent scaffold after this sheet is dismissed.
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.pop(context, true);
        if (messenger != null) {
          AppToast.success(context, 'המותג נשמר', messenger: messenger);
        }
      }
    } catch (_) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppToast.error(
          context,
          'שגיאה בשמירת המותג',
          action: SnackBarAction(label: 'נסה שנית', onPressed: _save),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showBrandDeleteDialog(context);
    if (!confirmed || widget.brand?.id == null) return;
    try {
      await widget.brandService.deleteBrand(widget.brand!.id!);
      if (mounted) {
        // Capture the messenger before popping so the toast attaches to the
        // parent scaffold after this sheet is dismissed.
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.pop(context, true);
        if (messenger != null) {
          AppToast.success(context, 'המותג נמחק בהצלחה', messenger: messenger);
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'שגיאה במחיקת המותג');
      }
    }
  }

  Widget _initialLetter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0]
        : '?';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: cs.primaryFixed,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.h3.copyWith(color: cs.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.brand == null
                          ? 'הוספת מותג חדש'
                          : 'עריכת מותג',
                      style: AppTypography.h3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Name field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שם המותג',
                      style: AppTypography.labelBold
                          .copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      maxLength: 60,
                      decoration: InputDecoration(
                        hintText: 'הזן שם מותג',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Logo URL field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'קישור ללוגו',
                      style: AppTypography.labelBold
                          .copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _logoUrlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Logo preview
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    if (_previewUrl != null)
                      ClipOval(
                        child: Image.network(
                          _previewUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                            _initialLetter(context),
                        ),
                      )
                    else
                      _initialLetter(context),
                    const SizedBox(width: 12),
                    Text(
                      'תצוגה מקדימה של הלוגו',
                      style: AppTypography.labelBold
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Verified toggle row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'סטטוס אימות',
                      style: AppTypography.labelBold
                          .copyWith(color: cs.onSurface),
                    ),
                    Row(
                      children: [
                        Switch(
                          value: _isVerified,
                          onChanged: (v) => setState(() => _isVerified = v),
                          activeThumbColor: cs.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _isVerified ? 'מותג מאומת' : 'לא מאומת',
                          style: AppTypography.labelBold.copyWith(
                            color: _isVerified
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _isVerified
                          ? 'המותג עבר תהליך אימות ומידע שלו מהימן'
                          : 'המותג טרם עבר תהליך אימות',
                      style: AppTypography.labelSm
                          .copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ),

              // Notes field
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'הערות (אופציונלי)',
                      style: AppTypography.labelBold
                          .copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'הוסף הערות...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Action row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving || !_isValid ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          disabledBackgroundColor:
                              cs.primary.withValues(alpha: 0.4),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: cs.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('שמור שינויים'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'ביטול',
                        style: AppTypography.labelBold
                            .copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button (edit mode only)
              if (widget.brand?.id != null) ...[
                const Divider(thickness: 1, height: 24),
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.sm),
                  child: TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.avoidText,
                    ),
                    child: const Text('מחק מותג'),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
