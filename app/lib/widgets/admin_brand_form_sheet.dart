import 'dart:async';
import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/brand_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_dialogs.dart';

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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המותג נשמר')),
        );
      }
    } catch (_) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('שגיאה בשמירת המותג'),
            action: SnackBarAction(label: 'נסה שנית', onPressed: _save),
          ),
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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המותג נמחק בהצלחה')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה במחיקת המותג')),
        );
      }
    }
  }

  Widget _initialLetter() {
    final letter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0]
        : '?';
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFEBF4FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF00478D),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.brand == null
                          ? 'הוספת מותג חדש'
                          : 'עריכת מותג',
                      style: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Name field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'שם המותג',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'קישור ללוגו',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_previewUrl != null)
                      ClipOval(
                        child: Image.network(
                          _previewUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialLetter(),
                        ),
                      )
                    else
                      _initialLetter(),
                    const SizedBox(width: 12),
                    const Text(
                      'תצוגה מקדימה של הלוגו',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Verified toggle row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'סטטוס אימות',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Row(
                      children: [
                        Switch(
                          value: _isVerified,
                          onChanged: (v) => setState(() => _isVerified = v),
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isVerified ? 'מותג מאומת' : 'לא מאומת',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isVerified
                                ? AppColors.primary
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _isVerified
                          ? 'המותג עבר תהליך אימות ומידע שלו מהימן'
                          : 'המותג טרם עבר תהליך אימות',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'הערות (אופציונלי)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
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

              const SizedBox(height: 8),

              // Action row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving || !_isValid ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('שמור שינויים'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ביטול',
                        style: TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button (edit mode only)
              if (widget.brand?.id != null) ...[
                const Divider(thickness: 1, height: 24),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                    ),
                    child: const Text('מחק מותג'),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
