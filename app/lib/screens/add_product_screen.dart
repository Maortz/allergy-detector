import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../services/image_service.dart';
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
    this.onReturnToCommunity,
  });

  @override
  State<AddProductWizard> createState() => AddProductWizardState();
}

class AddProductWizardState extends State<AddProductWizard> {
  static const int _totalSteps = 4;

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
    if (widget.allergens.isEmpty) {
      return _buildEmptyCatalog();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'בחר אלרגנים שהמוצר מכיל:',
          style: AppTypography.titleMd,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildAllergenGrid(_selectedContains),
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

  Widget _buildAllergenGrid(Set<String> selection) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.9,
      children: widget.allergens.map((allergen) {
        final isSelected = selection.contains(allergen.id);
        return AllergenCard(
          allergen: allergen,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                selection.remove(allergen.id);
              } else {
                selection.add(allergen.id);
              }
              // Any selection change invalidates the prior submit attempt.
              _submitError = null;
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
