import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../services/image_service.dart';
import '../services/product_service.dart';
import '../widgets/progress_stepper.dart';
import '../widgets/photo_upload_card.dart';
import '../widgets/allergen_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'add_product_success_screen.dart';

class AppTypography {
  static TextStyle get h1 => GoogleFonts.publicSans(
    fontSize: 30, fontWeight: FontWeight.w700, height: 38 / 30,
  );
  static TextStyle get h2 => GoogleFonts.publicSans(
    fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24,
  );
  static TextStyle get titleMd => GoogleFonts.publicSans(
    fontSize: 18, fontWeight: FontWeight.w600, height: 28 / 20,
  );
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18,
  );
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16,
  );
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14,
  );
  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14,
  );
  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12,
  );
}

class AddProductWizard extends StatefulWidget {
  final List<Allergen> allergens;
  final List<String> brands;

  /// Injected for tests; defaults to a Supabase-backed [ProductService].
  final ProductService? productService;

  const AddProductWizard({
    super.key,
    required this.allergens,
    this.brands = const [],
    this.productService,
  });

  @override
  State<AddProductWizard> createState() => _AddProductWizardState();
}

class _AddProductWizardState extends State<AddProductWizard> {
  final ImageService _imageService = ImageService();
  
  int _currentStep = 1;
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ingredientsUrlController = TextEditingController();
  String? _selectedBrand;
  final Set<String> _selectedContains = {};
  final Set<String> _selectedMayContain = {};
  
  String? _frontImagePath;
  String? _ingredientsImagePath;

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _ingredientsUrlController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _submitError = 'יש להזין שם מוצר (שלב 1)');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final service =
          widget.productService ?? ProductService(Supabase.instance.client);
      final barcode = _barcodeController.text.trim();
      await service.addProduct(
        nameHe: name,
        brandName: _selectedBrand,
        barcode: barcode.isEmpty ? null : barcode,
        containAllergenIds: _selectedContains.toList(),
        mayContainAllergenIds: _selectedMayContain.toList(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => AddProductSuccessScreen(
            onReturnToCommunity: () => Navigator.of(ctx).maybePop(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = 'אירעה שגיאה בשמירת המוצר. נסה שוב.';
      });
    }
  }

  Future<void> _pickFrontImage() async {
    final file = await _imageService.pickFromGallery();
    if (file != null) {
      setState(() => _frontImagePath = file.path);
    }
  }

  Future<void> _pickIngredientsImage() async {
    final file = await _imageService.pickFromGallery();
    if (file != null) {
      setState(() => _ingredientsImagePath = file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הוסף מוצר'),
          backgroundColor: AppColors.surfaceContainerLow,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: ProgressStepper(
                  currentStep: _currentStep,
                  labels: const ['ברקוד', 'תמונות', 'מכיל', 'עשוי להכיל'],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 48, color: AppColors.onSurfaceVariant),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'סריקת ברקוד',
                  style: AppTypography.bodyMd,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'ברקוד ידני',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'שם המוצר *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shopping_bag),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedBrand,
          decoration: const InputDecoration(
            labelText: 'מותג',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('בחר מותג (אופציונלי)')),
            ...widget.brands.map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand),
            )),
          ],
          onChanged: (val) => setState(() => _selectedBrand = val),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('המשך'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PhotoUploadCard(
                onTap: _pickFrontImage,
                label: 'חזית המוצר',
                imagePath: _frontImagePath,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PhotoUploadCard(
                onTap: _pickIngredientsImage,
                label: 'רשימת רכיבים',
                imagePath: _ingredientsImagePath,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: AppColors.onPrimaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'צרף תמונות של המוצר ורשימת הרכיבים לזיהוי מהיר יותר',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _nextStep,
                child: const Text('דלג'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                child: const Text('המשך'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'בחר אלרגנים שהמוצר מכיל:',
          style: AppTypography.titleMd,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.9,
          children: widget.allergens.map((allergen) {
            final isSelected = _selectedContains.contains(allergen.id);
            return AllergenCard(
              allergen: allergen,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedContains.remove(allergen.id);
                  } else {
                    _selectedContains.add(allergen.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'אגוזים וזרעים',
          style: AppTypography.titleMd,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.onErrorContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ודא דיוק: אם אתה לא בטוח, עדיף לסמן כ״עשוי להכיל״',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('המשך'),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'בחר אלרגנים שהמוצר עשוי להכיל:',
          style: AppTypography.titleMd,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.9,
          children: widget.allergens.map((allergen) {
            final isSelected = _selectedMayContain.contains(allergen.id);
            return AllergenCard(
              allergen: allergen,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedMayContain.remove(allergen.id);
                  } else {
                    _selectedMayContain.add(allergen.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildMayContainNote(),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildSubmitError(_submitError!),
        ],
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text('שמור מוצר'),
        ),
      ],
    );
  }

  Widget _buildMayContainNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cautionBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppColors.cautionText, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'שים לב',
                  style: AppTypography.labelBold
                      .copyWith(color: AppColors.cautionText),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'סמן "עלול להכיל" רק כשמצוין במפורש על האריזה — '
                  'ודא שהמידע תואם את האריזה האמיתית.',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitError(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.onErrorContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
