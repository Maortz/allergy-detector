import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../services/image_service.dart';
import '../services/photo_upload_service.dart';
import '../services/product_service.dart';
import '../widgets/allergen_card.dart';
import '../widgets/allergen_categories.dart';
import '../widgets/photo_upload_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'add_product_success_screen.dart';

class AddProductWizard extends StatefulWidget {
  final List<Allergen> allergens;
  final List<String> brands;

  /// Invoked when the user taps retry on the empty-catalog error state (steps
  /// 3/4). The catalog is owned by [AppShell]; if no handler is wired the retry
  /// button is hidden and the error message stands on its own.
  final VoidCallback? onRetryCatalog;

  /// Injected for tests; defaults to a Supabase-backed [ProductService].
  final ProductService? productService;

  /// Uploads step-2 photos. Defaults to a no-op stub (real Supabase Storage
  /// wiring is deferred to step-4 submit per spec §7.3); tests inject a stub
  /// that fails on demand to exercise the error → retry → success path.
  final PhotoUploadService? photoUploadService;

  /// Wired by the host to navigate to the Community tab (spec §1 — index 2
  /// of the main `IndexedStack`). If null, falls back to a single
  /// `Navigator.maybePop()` which lands the user wherever the wizard was
  /// pushed from — fine for the current `SearchScreenContent` FAB caller,
  /// but spec-incorrect for any deep-link/external entry.
  final VoidCallback? onReturnToCommunity;

  const AddProductWizard({
    super.key,
    required this.allergens,
    this.brands = const [],
    this.onRetryCatalog,
    this.productService,
    this.photoUploadService,
    this.onReturnToCommunity,
  });

  @override
  State<AddProductWizard> createState() => AddProductWizardState();
}

class AddProductWizardState extends State<AddProductWizard> {
  static const int _totalSteps = 4;

  final ImageService _imageService = ImageService();
  late final PhotoUploadService _uploadService =
      widget.photoUploadService ?? const PhotoUploadService();

  int _currentStep = 1;
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ingredientsUrlController = TextEditingController();
  String? _selectedBrand;
  final Set<String> _selectedContains = {};
  final Set<String> _selectedMayContain = {};

  /// True once the user has tried to leave step 1 with invalid input. Inline
  /// validation errors (spec §7.6) stay hidden until then, so a pristine form
  /// doesn't open with red error copy on first paint. Once shown, a field's
  /// error clears reactively as soon as that field becomes valid.
  bool _step1Submitted = false;

  /// Step-1 required fields per spec §7.6: product name (non-empty after trim)
  /// and brand (a selection). Barcode stays optional (manual-entry path).
  bool get _nameValid => _nameController.text.trim().isNotEmpty;
  bool get _brandValid => _selectedBrand != null;
  bool get _step1Valid => _nameValid && _brandValid;

  String? _frontImagePath;
  String? _ingredientsImagePath;

  /// Per-slot upload failure flags (spec §5 "Upload error"). When set, the
  /// matching tile renders the error/retry state instead of the thumbnail.
  bool _frontUploadFailed = false;
  bool _ingredientsUploadFailed = false;

  bool _isSubmitting = false;
  String? _submitError;

  /// True while the front-photo slot is showing its upload-error state.
  @visibleForTesting
  bool get frontUploadFailed => _frontUploadFailed;

  /// Jumps the wizard to [step] without walking the form (tests only).
  @visibleForTesting
  void goToStepForTest(int step) => setState(() => _currentStep = step);

  /// Simulates a photo being selected into the front slot and runs the upload,
  /// without driving the real platform image picker (which can't run in a
  /// widget test). Mirrors [_pickFrontImage] minus the picker call.
  @visibleForTesting
  Future<void> selectFrontPhotoForTest(String path) async {
    setState(() {
      _frontImagePath = path;
      _frontUploadFailed = false;
    });
    await _uploadFront();
  }

  @visibleForTesting
  Set<String> get containsAllergenIds => Set.unmodifiable(_selectedContains);

  @visibleForTesting
  Set<String> get mayContainAllergenIds => Set.unmodifiable(_selectedMayContain);

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _ingredientsUrlController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  /// Step-1 Continue handler (spec §7.6). The Continue button is disabled
  /// (`onPressed: null`) until [_step1Valid], so this only ever runs once the
  /// required fields (product name + brand) are valid; it advances to step 2.
  void _continueFromStep1() => _nextStep();

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
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
            onReturnToCommunity: widget.onReturnToCommunity ??
                () => Navigator.of(ctx).maybePop(),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('addProduct failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = _friendlySubmitError(e);
      });
    }
  }

  /// Branches the user-facing copy on common failure modes — the most
  /// frequent once the live `products` table is wired (duplicate barcode,
  /// connectivity drops). Falls back to a generic retry copy otherwise.
  String _friendlySubmitError(Object error) {
    if (error is PostgrestException && error.code == '23505') {
      return 'מוצר עם הברקוד הזה כבר קיים';
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return 'אין חיבור לאינטרנט. בדוק את החיבור ונסה שוב.';
    }
    return 'אירעה שגיאה בשמירת המוצר. נסה שוב.';
  }

  Future<void> _pickFrontImage() async {
    final file = await _imageService.pickFromGallery();
    if (file == null) return;
    setState(() {
      _frontImagePath = file.path;
      _frontUploadFailed = false;
    });
    await _uploadFront();
  }

  Future<void> _pickIngredientsImage() async {
    final file = await _imageService.pickFromGallery();
    if (file == null) return;
    setState(() {
      _ingredientsImagePath = file.path;
      _ingredientsUploadFailed = false;
    });
    await _uploadIngredients();
  }

  /// Uploads the front photo and flips the slot into its error state on
  /// failure (spec §5). On success the failure flag is cleared and the tile
  /// falls back to the thumbnail-filled state.
  Future<void> _uploadFront() async {
    final path = _frontImagePath;
    if (path == null) return;
    try {
      await _uploadService.upload(path);
      if (!mounted) return;
      setState(() => _frontUploadFailed = false);
    } catch (e, st) {
      debugPrint('front photo upload failed: $e\n$st');
      if (!mounted) return;
      setState(() => _frontUploadFailed = true);
    }
  }

  Future<void> _uploadIngredients() async {
    final path = _ingredientsImagePath;
    if (path == null) return;
    try {
      await _uploadService.upload(path);
      if (!mounted) return;
      setState(() => _ingredientsUploadFailed = false);
    } catch (e, st) {
      debugPrint('ingredients photo upload failed: $e\n$st');
      if (!mounted) return;
      setState(() => _ingredientsUploadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('הוספת מוצר חדש'),
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _WizardProgress(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
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
        const _CameraUnavailablePlaceholder(),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'מספר ברקוד (ידני)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _nameController,
          // Rebuild on every keystroke so the inline error clears and the
          // Continue button re-enables as soon as the field becomes valid.
          onChanged: (_) => setState(() => _step1Submitted = true),
          decoration: InputDecoration(
            labelText: 'שם המוצר',
            border: const OutlineInputBorder(),
            // Spec §7.6 — error copy below the empty required field, 12 pt
            // Inter Regular #DC2626 (AppColors.avoid).
            errorText:
                _step1Submitted && !_nameValid ? 'נא למלא שם מוצר' : null,
            errorStyle: AppTypography.labelSmRegular.copyWith(
              color: AppColors.avoid,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedBrand,
          decoration: InputDecoration(
            labelText: 'מותג / יצרן',
            border: const OutlineInputBorder(),
            errorText:
                _step1Submitted && !_brandValid ? 'נא לבחור מותג' : null,
            errorStyle: AppTypography.labelSmRegular.copyWith(
              color: AppColors.avoid,
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('בחר מותג מהרשימה')),
            ...widget.brands.map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand),
            )),
          ],
          onChanged: (val) => setState(() {
            _selectedBrand = val;
            _step1Submitted = true;
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          // Spec §7.6 / issue AC #2 — the Continue button stays disabled
          // (onPressed: null → greyed out, no tap feedback) until both required
          // fields are valid. The name field and brand dropdown each setState on
          // change, so the button re-enables reactively the moment the form
          // becomes valid.
          onPressed: _step1Valid ? _continueFromStep1 : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.chevron_left, size: 20),
          label: const Text('המשך'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // S2-4 — stacked full-width tiles (not side-by-side Row)
        PhotoUploadCard(
          onTap: _pickFrontImage,
          label: 'חזית המוצר',
          imagePath: _frontImagePath,
          isError: _frontUploadFailed,
          onRetry: _uploadFront,
        ),
        const SizedBox(height: AppSpacing.md),
        PhotoUploadCard(
          onTap: _pickIngredientsImage,
          label: 'רשימת רכיבים',
          imagePath: _ingredientsImagePath,
          isError: _ingredientsUploadFailed,
          onRetry: _uploadIngredients,
        ),
        const SizedBox(height: AppSpacing.lg),
        // S2-5 — tip card: #EBF4FF light-blue tint, verbatim text from spec §2
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryTint, // #EBF4FF
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'כדאי לצלם במקום עם תאורה טובה ולהימנע מהשתקפויות של אור ישיר על האריזה. זה יעזור לנו לנתח את המידע בצורה מדויקת יותר.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // S2-8 — footer: "חזרה" outlined (back) + "המשך" primary (continue)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('חזרה'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('המשך'),
              ),
            ),
          ],
        ),
        // S2-9 — skip text link below the footer row
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _nextStep,
          child: Text(
            'דילוג והזנה ידנית',
            style: AppTypography.bodySm.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    if (widget.allergens.isEmpty) {
      return _buildEmptyCatalog();
    }
    final groups = groupAllergensByCategory(widget.allergens);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // S3-3 — section heading + sub-instruction (mirrors step 4 pattern)
        Text(
          'מהם האלרגנים במוצר?',
          textAlign: TextAlign.right,
          style: AppTypography.titleStrong.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'סמן את כל המרכיבים שמופיעים ברשימת הרכיבים',
          textAlign: TextAlign.right,
          style: AppTypography.bodyXs.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // S3-4 — grouped sub-sections (same groupAllergensByCategory as step 4)
        for (final category in kAllergenCategoryOrder)
          if ((groups[category] ?? const []).isNotEmpty) ...[
            Text(
              allergenCategoryTitle(category),
              textAlign: TextAlign.right,
              style: AppTypography.labelBold.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStep3Grid(groups[category]!),
            const SizedBox(height: AppSpacing.lg),
          ],

        // S3-8 — info note: blue #EBF4FF bg + info icon (not red errorContainer)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryTint, // #EBF4FF
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'סמן בדיוק את האלרגנים המצוינים ברשימת הרכיבים של המוצר',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // S3-9 — two-button footer: "חזרה" outlined + "המשך" primary w/ chevron_left
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('חזרה'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('המשך'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Step-3 allergen grid: 2 columns, DD-13 chip style (bordered+badge via AllergenCard).
  /// No locked state (step 3 is the "contains" step; step 4 locks step-3 picks).
  Widget _buildStep3Grid(List<Allergen> allergens) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: allergens.map((allergen) {
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
              _submitError = null;
            });
          },
        );
      }).toList(),
    );
  }

  // Step 4 — "May Contain". Spec: add-product-step-4-may-contain.md §7.9
  // (covers S4-1..S4-6, S4-8, S4-9). S4-7/S4-10/S4-11 (amber note + submit
  // wiring + loading state) are tracked separately in #13; this step's submit
  // is intentionally a no-op until that PR lands.
  Widget _buildStep4() {
    if (widget.allergens.isEmpty) {
      return _buildEmptyCatalog();
    }
    final groups = groupAllergensByCategory(widget.allergens);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // S4-3 — section heading + sub-instruction.
        Text(
          'האם יש חשש לעקבות?',
          textAlign: TextAlign.right,
          style: AppTypography.titleStrong.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "סמן אלרגנים המצוינים תחת 'עלול להכיל' או 'בסביבת עבודה'",
          textAlign: TextAlign.right,
          style: AppTypography.bodyXs.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // S4-4 — grouped sub-sections (full catalog, step-3 picks locked).
        for (final category in kAllergenCategoryOrder)
          if ((groups[category] ?? const []).isNotEmpty) ...[
            Text(
              allergenCategoryTitle(category),
              textAlign: TextAlign.right,
              style: AppTypography.labelBold.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStep4Grid(groups[category]!),
            const SizedBox(height: AppSpacing.lg),
          ],

        if (_submitError != null) ...[
          _buildSubmitError(_submitError!),
          const SizedBox(height: AppSpacing.md),
        ],

        // S4-9 — two-button footer: "חזרה" outlined + "סיום ושליחה" primary.
        // S4-8 — primary CTA "סיום ושליחה" + send icon. S4-11 — loading state.
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('חזרה'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                // S4-10/S4-11 — submit wiring (#13): persists the product and
                // navigates to the success screen; shows a spinner while in
                // flight.
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('סיום ושליחה'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shown on steps 3/4 when the allergen catalog failed to load (e.g. Supabase
  /// 5xx, RLS denial, unseeded env). Renders an error state with optional retry
  /// instead of an empty grid — and crucially omits the advance/save button so
  /// the user can't submit an empty allergen set that looks like a deliberate
  /// choice.
  Widget _buildEmptyCatalog() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'טעינת רשימת האלרגנים נכשלה. נסה שוב.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (widget.onRetryCatalog != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: widget.onRetryCatalog,
              child: const Text('נסה שוב'),
            ),
          ],
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

  /// Step-4 grid: 2 columns, with allergens already chosen as "contains"
  /// (step 3) rendered as locked chips per spec §7.2.
  Widget _buildStep4Grid(List<Allergen> allergens) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: allergens.map((allergen) {
        final isLocked = _selectedContains.contains(allergen.id);
        final isSelected = _selectedMayContain.contains(allergen.id);
        return AllergenCard(
          allergen: allergen,
          isSelected: isSelected,
          locked: isLocked,
          onTap: isLocked
              ? null
              : () {
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
    );
  }

}

/// S4-1 / S4-2 — canonical wizard chrome: linear progress bar with right-aligned
/// "שלב N מתוך 4" + "X% הושלם" copy. Step 4 uses "הושלם" (singular) per spec.
class _WizardProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _WizardProgress({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    final percent = (progress * 100).round();
    // Spec: step 4 uses "הושלם" (singular); earlier steps use "הושלמו" (plural).
    final percentLabel =
        currentStep == totalSteps ? '$percent% הושלם' : '$percent% הושלמו';

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                percentLabel,
                style: AppTypography.labelSmBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                'שלב $currentStep מתוך $totalSteps',
                style: AppTypography.labelSmRegular.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.outlineVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Degraded scanner card for step 1 when the camera is unavailable (web,
/// emulator, or denied permission). Per add-product-step-1-barcode.md §7.8 #8
/// (S1-14): a 16:9 dark-slate viewport with a muted `no_photography` glyph and
/// the "המצלמה לא זמינה" label. The manual barcode field below stays functional,
/// so the user can still submit by typing/pasting the barcode.
class _CameraUnavailablePlaceholder extends StatelessWidget {
  const _CameraUnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cameraSurfaceUnavailable,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.no_photography,
                size: 48,
                color: AppColors.iconMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'המצלמה לא זמינה',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.iconMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
