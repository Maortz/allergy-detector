import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../services/image_service.dart';
import '../services/photo_upload_service.dart';
import '../services/product_service.dart';
import '../services/scanner_service.dart';
import '../widgets/allergen_card.dart';
import '../widgets/allergen_categories.dart';
import '../widgets/photo_upload_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'add_product_success_screen.dart';

/// Upper bound on the step-1 scanner card height. Without it the 16:9 viewport
/// stretches to the full container width on wide (web/tablet) layouts and
/// balloons to ~675px tall (issue #332). Phone widths fall well under this cap,
/// so the clamp is a no-op there.
const double _kScannerCardMaxHeight = 200;

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

  /// Optional scanner-service override. Tests inject a pre-configured service so
  /// the camera path is exercised without real hardware; production passes null
  /// and a fresh [ScannerService] is created in [State.initState].
  final ScannerService? scannerService;

  /// Optional factory wrapping the [MobileScanner] widget. In production this is
  /// null and the real [MobileScanner] is mounted; tests inject a no-op builder
  /// to avoid platform-channel camera init in the test VM.
  @visibleForTesting
  final Widget Function(
    MobileScannerController controller,
    Widget Function(BuildContext, MobileScannerException) errorBuilder,
  )? mobileScannerBuilder;

  const AddProductWizard({
    super.key,
    required this.allergens,
    this.brands = const [],
    this.onRetryCatalog,
    this.productService,
    this.photoUploadService,
    this.onReturnToCommunity,
    this.scannerService,
    this.mobileScannerBuilder,
  });

  @override
  State<AddProductWizard> createState() => AddProductWizardState();
}

class AddProductWizardState extends State<AddProductWizard> {
  static const int _totalSteps = 4;

  /// Sentinel dropdown value for the "add a new vendor" entry — kept distinct
  /// from any real brand name and from the null placeholder (#266).
  static const String _addVendorSentinel = '__add_new_vendor__';

  final ImageService _imageService = ImageService();
  late final PhotoUploadService _uploadService =
      widget.photoUploadService ?? const PhotoUploadService();
  late final ProductService _productService =
      widget.productService ?? ProductService(Supabase.instance.client);

  /// Local, mutable copy of the injected vendor list so a vendor created inline
  /// (#266) immediately appears in the dropdown.
  late List<String> _brands;

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

  /// Barcode scanner. Null until [initState] completes; after initialisation
  /// the controller is non-null on every platform, including web. The live
  /// viewport renders only while its [ScannerService.controller] is non-null
  /// and the camera is not denied.
  ScannerService? _scannerService;

  /// Set when the OS reports camera permission was denied. Routed here via
  /// [MobileScanner.errorBuilder] so the degraded card is shown.
  bool _cameraDenied = false;

  /// Set when the OS reports camera permission is *permanently* denied (the
  /// user picked "don't ask again" / revoked it in Settings). In that state a
  /// fresh permission request is a no-op, so the denied card deep-links to
  /// system settings instead of offering a retry that silently does nothing.
  bool _cameraPermanentlyDenied = false;

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

  /// Test-only seam to populate the ingredients photo slot from a path,
  /// mirroring [selectFrontPhotoForTest] for the second photo field.
  @visibleForTesting
  Future<void> selectIngredientsPhotoForTest(String path) async {
    setState(() {
      _ingredientsImagePath = path;
      _ingredientsUploadFailed = false;
    });
    await _uploadIngredients();
  }

  @visibleForTesting
  String? get frontImagePathForTest => _frontImagePath;

  @visibleForTesting
  String? get ingredientsImagePathForTest => _ingredientsImagePath;

  @visibleForTesting
  Set<String> get containsAllergenIds => Set.unmodifiable(_selectedContains);

  @visibleForTesting
  Set<String> get mayContainAllergenIds => Set.unmodifiable(_selectedMayContain);

  @override
  void initState() {
    super.initState();
    _brands = List<String>.from(widget.brands);
    // Initialise the scanner on every platform. On web mounting the
    // [MobileScanner] viewport triggers the browser's camera-permission prompt
    // (issue #332); a denial routes through [onScannerError] to the recovery
    // card while the manual barcode field stays usable.
    _scannerService = widget.scannerService ?? ScannerService();
    _scannerService!.initialize();
  }

  @override
  void didUpdateWidget(AddProductWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.brands, widget.brands)) {
      _brands = List<String>.from(widget.brands);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _ingredientsUrlController.dispose();
    _scannerService?.dispose();
    super.dispose();
  }

  /// Routes camera errors surfaced by [MobileScanner.errorBuilder]. A
  /// permission denial flips [_cameraDenied] so the card degrades to the
  /// placeholder. The state mutation is deferred to the next frame because
  /// `errorBuilder` runs during [MobileScanner]'s build, and a synchronous
  /// `setState` there throws "setState() called during build".
  @visibleForTesting
  void onScannerError(MobileScannerException error) {
    if (ScannerService.isPermissionDenied(error.errorCode) && !_cameraDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_cameraDenied) {
          setState(() => _cameraDenied = true);
          // Resolve whether the denial is permanent so the CTA can deep-link to
          // system settings instead of re-prompting (a no-op once the user
          // picked "don't ask again"). Async — the denied card renders
          // immediately with the retry CTA and upgrades once this resolves.
          _resolvePermanentDenial();
        }
      });
    }
  }

  /// Queries the OS for whether camera permission is permanently denied and
  /// updates the denied card's CTA accordingly. Failures are swallowed — the
  /// card simply keeps the plain retry CTA.
  Future<void> _resolvePermanentDenial() async {
    // The browser has no "don't ask again" deep-link to system settings, so the
    // recovery card stays on its plain retry CTA on web.
    if (kIsWeb) return;
    final service = _scannerService;
    if (service == null) return;
    final permanent = await service.isCameraPermissionPermanentlyDenied();
    if (mounted && _cameraDenied && permanent != _cameraPermanentlyDenied) {
      setState(() => _cameraPermanentlyDenied = permanent);
    }
  }

  /// Deep-links to the OS app-settings page so the user can grant camera
  /// access. Wired to the "פתח הגדרות" CTA shown when permission is
  /// permanently denied.
  Future<void> _openCameraSettings() async {
    await _scannerService?.openSettings();
  }

  /// Clears the denied state and re-creates the scanner controller so the next
  /// frame re-mounts a fresh [MobileScanner]. Wired to the "נסה שוב" button on
  /// the permission-denied card — lets a user who has since granted permission
  /// in OS settings recover without leaving the wizard.
  void _retryCameraPermission() {
    _scannerService?.dispose();
    _scannerService = widget.scannerService ?? ScannerService();
    _scannerService!.initialize();
    setState(() {
      _cameraDenied = false;
      _cameraPermanentlyDenied = false;
    });
  }

  /// Test seam mirroring [MobileScanner.onDetect].
  @visibleForTesting
  void handleBarcodeScan(BarcodeCapture capture) => _handleBarcodeScan(capture);

  /// Applies a scanned barcode to the manual barcode field (issue #265 AC:
  /// "User can scan a barcode to pre-fill the product barcode field").
  void _handleBarcodeScan(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    // The same barcode fires across several consecutive frames while it stays
    // in view; skip the redundant setState once the field already holds it.
    if (_barcodeController.text == barcode) return;
    setState(() => _barcodeController.text = barcode);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  /// Step-2 skip handler (spec §7.4 / S2-9): "דילוג והזנה ידנית" discards any
  /// photos the user added and advances to step 3 with both photo fields null —
  /// distinct from "המשך", which keeps the selected photos. Photos are optional
  /// (§2), so neither control is gated (#330).
  void _skipPhotos() {
    setState(() {
      _frontImagePath = null;
      _ingredientsImagePath = null;
      _frontUploadFailed = false;
      _ingredientsUploadFailed = false;
    });
    _nextStep();
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

  /// True once the user has entered anything worth losing — used to gate the
  /// exit-confirmation prompt when leaving the wizard from step 1 (issue #328).
  bool get _hasUnsavedData =>
      _nameController.text.trim().isNotEmpty ||
      _barcodeController.text.trim().isNotEmpty ||
      _selectedBrand != null ||
      _selectedContains.isNotEmpty ||
      _selectedMayContain.isNotEmpty ||
      _frontImagePath != null ||
      _ingredientsImagePath != null;

  /// Handles the in-app back arrow / system back gesture (issue #328). On any
  /// step past the first it walks back one step (preserving entered data)
  /// rather than tearing down the whole wizard route; on step 1 it exits the
  /// wizard, prompting for confirmation first if data would be lost.
  Future<void> _onBackPressed() async {
    if (_currentStep > 1) {
      _prevStep();
      return;
    }
    await _maybeExitWizard();
  }

  /// Exits the wizard from step 1. If the form is dirty, confirms first so an
  /// accidental back tap doesn't silently discard the user's input (AC#3).
  Future<void> _maybeExitWizard() async {
    if (_hasUnsavedData) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('לצאת מהוספת המוצר?'),
            content: const Text('הפרטים שהזנת לא יישמרו.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('המשך עריכה'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('צא ללא שמירה'),
              ),
            ],
          ),
        ),
      );
      if (shouldExit != true) return;
    }
    if (!mounted) return;
    // Direct pop bypasses the PopScope guard (it only gates system/AppBar
    // maybePop), so there's no re-prompt loop.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
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
      final service = _productService;
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
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      // Only let the route pop directly when we're on step 1 with nothing to
      // lose. Otherwise intercept (system back / predictive back) and route it
      // through the same step-back / confirm-exit logic as the AppBar arrow.
      canPop: _currentStep == 1 && !_hasUnsavedData,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('הוספת מוצר חדש'),
            backgroundColor: colorScheme.surfaceContainerLowest,
            elevation: 0,
            // Override the auto-leading: the back arrow must step back through
            // the wizard, not tear down the whole route (issue #328).
            leading: BackButton(onPressed: _onBackPressed),
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

  /// Step-1 scanner card with a tri-state body (any platform, including web):
  /// the live camera viewport when permission is granted and the controller is
  /// ready → [_CameraPermissionDenied] when the OS/browser denied access →
  /// [_CameraUnavailablePlaceholder] before the controller is ready. The manual
  /// barcode field below stays functional in every state (spec §6 / §7.8 #8).
  Widget _buildScannerCard() {
    final controller = _scannerService?.controller;
    // A denied camera degrades to a recovery card. On native a *permanent*
    // denial swaps the retry CTA for a system-settings deep-link (AC#3); the
    // browser has no such deep-link, so web always keeps the plain retry. The
    // manual barcode field below stays usable in either state (issue #332).
    if (_cameraDenied) {
      return _CameraPermissionDenied(
        permanentlyDenied: !kIsWeb && _cameraPermanentlyDenied,
        onOpenSettings: _openCameraSettings,
        onRetry: _retryCameraPermission,
      );
    }
    if (controller == null) {
      return const _CameraUnavailablePlaceholder();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _kScannerCardMaxHeight),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.mobileScannerBuilder != null
              ? widget.mobileScannerBuilder!(
                  controller,
                  (ctx, error) {
                    onScannerError(error);
                    return const _CameraUnavailablePlaceholder();
                  },
                )
              : MobileScanner(
                  controller: controller,
                  onDetect: _handleBarcodeScan,
                  errorBuilder: (context, error) {
                    onScannerError(error);
                    return const _CameraUnavailablePlaceholder();
                  },
                  placeholderBuilder: (_) =>
                      const _CameraUnavailablePlaceholder(),
                ),
        ),
      ),
    );
  }

  /// Opens the inline "add new vendor" dialog (#266). On a successful create the
  /// new vendor is appended to [_brands] and auto-selected; on failure an inline
  /// error is shown inside the dialog and the form is left intact (no data loss).
  Future<void> _openAddVendorDialog() async {
    final created = await showDialog<String>(
      context: context,
      builder: (_) => _AddVendorDialog(onCreate: _productService.addBrand),
    );
    if (!mounted || created == null) return;
    setState(() {
      if (!_brands.contains(created)) _brands.add(created);
      _selectedBrand = created;
      _step1Submitted = true;
    });
  }

  Widget _buildStep1() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'סריקת ברקוד',
          style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'כוון את המצלמה אל הברקוד שעל גבי אריזת המוצר',
          style: AppTypography.bodySm.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildScannerCard(),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _barcodeController,
          // Barcodes are numeric; on web `keyboardType` is only a hint, so the
          // formatter is what actually blocks letters/symbols (issue #329).
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          // Rebuild so PopScope.canPop re-evaluates `_hasUnsavedData`; without
          // this, a stale `canPop: true` lets the system/predictive back gesture
          // skip the confirm dialog when only the barcode field is filled.
          onChanged: (_) => setState(() {}),
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
              color: appColors.avoid,
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
              color: appColors.avoid,
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('בחר מותג מהרשימה')),
            ..._brands.map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand),
            )),
            const DropdownMenuItem(
              value: _addVendorSentinel,
              child: Text('➕ הוסף מותג חדש'),
            ),
          ],
          onChanged: (val) {
            if (val == _addVendorSentinel) {
              _openAddVendorDialog();
              return;
            }
            setState(() {
              _selectedBrand = val;
              _step1Submitted = true;
            });
          },
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
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
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
            color: appColors.primaryTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb, color: colorScheme.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'כדאי לצלם במקום עם תאורה טובה ולהימנע מהשתקפויות של אור ישיר על האריזה. זה יעזור לנו לנתח את המידע בצורה מדויקת יותר.',
                  style: AppTypography.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  foregroundColor: colorScheme.primary,
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
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
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
          onPressed: _skipPhotos,
          child: Text(
            'דילוג והזנה ידנית',
            style: AppTypography.bodySm.copyWith(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
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
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'סמן את כל המרכיבים שמופיעים ברשימת הרכיבים',
          textAlign: TextAlign.right,
          style: AppTypography.bodyXs.copyWith(
            color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.onSurfaceVariant,
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
            color: appColors.primaryTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, color: colorScheme.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'סמן בדיוק את האלרגנים המצוינים ברשימת הרכיבים של המוצר',
                  style: AppTypography.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  foregroundColor: colorScheme.primary,
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
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
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
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "סמן אלרגנים המצוינים תחת 'עלול להכיל' או 'בסביבת עבודה'",
          textAlign: TextAlign.right,
          style: AppTypography.bodyXs.copyWith(
            color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.onSurfaceVariant,
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
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  foregroundColor: colorScheme.primary,
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
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'טעינת רשימת האלרגנים נכשלה. נסה שוב.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm
                  .copyWith(color: colorScheme.onErrorContainer),
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
    final colorScheme = Theme.of(context).colorScheme;
    final progress = currentStep / totalSteps;
    final percent = (progress * 100).round();
    // Spec: step 4 uses "הושלם" (singular); earlier steps use "הושלמו" (plural).
    final percentLabel =
        currentStep == totalSteps ? '$percent% הושלם' : '$percent% הושלמו';

    return Container(
      color: colorScheme.surface,
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
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'שלב $currentStep מתוך $totalSteps',
                style: AppTypography.labelSmRegular.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
              backgroundColor: colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
    final appColors = context.colors;
    // Cap the height so a 16:9 box stretched to the full container width on
    // wide (web) layouts doesn't balloon to ~675px tall (issue #332). On phone
    // widths the natural 16:9 height stays well under this cap, so the clamp is
    // a no-op there.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _kScannerCardMaxHeight),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: appColors.cameraSurfaceUnavailable,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.no_photography,
                  size: 48,
                  color: appColors.iconMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'המצלמה לא זמינה',
                  style: AppTypography.bodySm.copyWith(
                    color: appColors.iconMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recovery card shown when the OS denies camera permission. A recoverable
/// denial offers a "נסה שוב" retry; a *permanent* denial (the user picked
/// "don't ask again") swaps it for a "פתח הגדרות" deep-link to system settings,
/// since a re-prompt would be a silent no-op (issue #265 AC#3). The manual
/// barcode field below the card stays functional in either state.
class _CameraPermissionDenied extends StatelessWidget {
  final bool permanentlyDenied;
  final Future<void> Function() onOpenSettings;
  final VoidCallback onRetry;

  const _CameraPermissionDenied({
    required this.permanentlyDenied,
    required this.onOpenSettings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'גישה למצלמה נדחתה',
            style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'כדי לסרוק ברקודים יש לאפשר גישה למצלמה בהגדרות המכשיר.',
            style: AppTypography.bodyMd.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (permanentlyDenied)
            OutlinedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('פתח הגדרות'),
            )
          else
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
        ],
      ),
    );
  }
}

/// Inline "add new vendor" dialog (#266). Collects a vendor name, calls
/// [onCreate] (which persists to the `brands` table) and pops the created name
/// on success. On failure it stays open with an inline error so the user does
/// not lose what they typed.
class _AddVendorDialog extends StatefulWidget {
  final Future<String> Function(String nameHe) onCreate;

  const _AddVendorDialog({required this.onCreate});

  @override
  State<_AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<_AddVendorDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'נא להזין שם מותג');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.onCreate(name);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      debugPrint('addBrand failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'לא ניתן להוסיף מותג, נסו שוב';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('הוספת מותג חדש'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          enabled: !_saving,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: 'שם המותג',
            border: const OutlineInputBorder(),
            errorText: _error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('שמירה'),
          ),
        ],
      ),
    );
  }
}
