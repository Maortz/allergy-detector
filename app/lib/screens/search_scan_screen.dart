import '../services/scanner_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../models/recent_scan.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../services/search_cache.dart';
import '../services/scan_history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/search_input.dart';
import '../widgets/state_view.dart';
import '../widgets/status_badge.dart';
import 'product_details.dart';
import 'search_screen.dart';

class SearchScanScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;
  final ProductService? productService;

  /// Optional scanner service override.  Used in tests to inject a
  /// pre-configured [ScannerService] (e.g. one whose [errorBuilder] fires
  /// a permission-denied error) without relying on fake camera hardware.
  final ScannerService? scannerService;

  /// Optional factory that wraps the [MobileScanner] widget.
  ///
  /// In production this is `null` and the default [MobileScanner] is used.
  /// Tests inject a no-op builder to avoid the real camera initialisation
  /// (which would cause the controller to attempt a platform-channel call
  /// in the CI environment).
  @visibleForTesting
  final Widget Function(
    MobileScannerController controller,
    Widget Function(BuildContext, MobileScannerException) errorBuilder,
  )? mobileScannerBuilder;

  /// Recently-scanned products to render under "נסרק לאחרונה", supplied by the
  /// host from real [ScanHistoryService] data. `null` (still loading) or empty
  /// renders the §7.4 empty-state — there is no mock fallback (issue #322).
  final List<RecentScan>? recentScans;

  /// Invoked after a scan is recorded to scan history so the host can refresh
  /// the recently-scanned feed (issue #322).
  final VoidCallback? onScanRecorded;

  final ValueChanged<UserProfile>? onProfileUpdated;

  /// Forwarded to the active-search overlay's "+" FAB so it can launch the
  /// add-product flow via the host (MainContainer). Optional for tests.
  final VoidCallback? onAddProductTap;

  const SearchScanScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.productService,
    this.onProfileUpdated,
    this.onAddProductTap,
    this.scannerService,
    this.mobileScannerBuilder,
    this.recentScans,
    this.onScanRecorded,
  });

  @override
  State<SearchScanScreen> createState() => SearchScanScreenState();
}

/// Public state class so tests can obtain a reference via
/// `tester.state<SearchScanScreenState>(find.byType(SearchScanScreen))`
/// and drive [onScannerError] directly without real camera hardware.
class SearchScanScreenState extends State<SearchScanScreen>
    with SingleTickerProviderStateMixin {
  ScannerService? _scannerService;

  /// Injected in tests; null in production until first use. Resolved lazily
  /// via [_resolvedProductService] so [initState] never touches
  /// `Supabase.instance.client` — that throws when Supabase is uninitialised
  /// (e.g. in widget tests mounting this screen or any [MainContainer]).
  ProductService? _productService;
  bool _scanBusy = false;

  ProductService get _resolvedProductService =>
      _productService ??= ProductService(Supabase.instance.client);

  /// Set to true when the OS reports camera permission was denied.
  /// Routed here via [MobileScanner.errorBuilder] so the real denial path
  /// is always reachable in production (unlike a flag set only in initialize).
  ///
  /// Private: tests assert against the rendered UI (the ground truth) rather
  /// than reading internal state. They drive the path via [onScannerError].
  bool _cameraDenied = false;

  /// Set when the OS reports camera permission is *permanently* denied
  /// (the user chose "don't ask again" or revoked it in Settings). In that
  /// state a retry that re-requests permission is a no-op, so the denied UI
  /// offers an "open settings" deep-link instead of a plain retry.
  bool _cameraPermanentlyDenied = false;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  /// Real host-fed recent scans (issue #322). `null` (loading) or empty renders
  /// the §7.4 empty-state — there is no mock fallback.
  List<RecentScan> get _recentScans => widget.recentScans ?? const [];

  final List<String> _safetyTips = [
    'סרוק את הברקוד על האריזה לקבלת מידע מדויק',
    'בדוק את רשימת המרכיבים בזהירות',
    'שמור על רשימת האלרגנים שלך מעודכנת',
  ];

  @override
  void initState() {
    super.initState();
    _productService = widget.productService;

    if (!kIsWeb) {
      // Use injected service (tests) or create a fresh one (production).
      _scannerService = widget.scannerService ?? ScannerService();
      _scannerService!.initialize();
    }
    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerService?.dispose();
    super.dispose();
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreenContent(
          userProfile: widget.userProfile,
          allergens: widget.allergens,
          onProfileUpdated: widget.onProfileUpdated ?? (_) {},
          onAddProductTap: widget.onAddProductTap,
        ),
      ),
    );
  }

  /// Test seam: drives the barcode-scan flow exactly as
  /// [MobileScanner.onDetect] would in production, so tests can exercise the
  /// scan → product-details → history-record path without real camera
  /// hardware. Tests obtain the state via
  /// `tester.state<SearchScanScreenState>(...)` and call this directly.
  @visibleForTesting
  Future<void> handleBarcodeScan(BarcodeCapture capture) =>
      _handleBarcodeScan(capture);

  Future<void> _handleBarcodeScan(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || _scanBusy) return;
    setState(() => _scanBusy = true);
    try {
      // Serve from the barcode cache first; on a miss, hit Supabase and cache
      // the result so a repeat scan of the same product skips the round-trip
      // (issue #81). A "not found" is left uncached on purpose.
      var product = await SearchCache.loadBarcode(barcode);
      if (product == null) {
        product = await _resolvedProductService.searchProduct(barcode);
        if (product != null) {
          await SearchCache.saveBarcode(barcode, product);
        }
      }
      if (!mounted) return;
      final resolved = product;
      if (resolved != null) {
        // Resolving a scanned barcode to its details is a "scan" event for
        // history purposes (#134) — mirrors the search → details path in
        // SearchScreenContent.
        await ScanHistoryService.record(resolved, widget.userProfile);
        if (!mounted) return;
        widget.onScanRecorded?.call();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: resolved,
              userProfile: widget.userProfile,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('מוצר לא נמצא במאגר')),
        );
      }
    } catch (e, st) {
      debugPrint('barcode scan ($barcode) failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בחיפוש מוצר')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildScannerSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildRecentScansSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildSafetyTipSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SearchInput(
      hintText: 'חפש מוצר או מרכיב...',
      readOnly: true,
      onTap: _openSearch,
    );
  }

  /// Called by [MobileScanner.errorBuilder] for every camera error.
  ///
  /// Routes [MobileScannerErrorCode.permissionDenied] errors into
  /// [_cameraDenied] so the real denial path is always reachable in production.
  /// Exposed (non-private) so tests can invoke it directly via
  /// `tester.state<SearchScanScreenState>(find.byType(SearchScanScreen))`.
  ///
  /// The state mutation is deferred to the next frame via
  /// [WidgetsBinding.addPostFrameCallback]: `errorBuilder` runs *during*
  /// MobileScanner's build, and calling [setState] synchronously from there
  /// throws "setState() called during build".
  @visibleForTesting
  void onScannerError(MobileScannerException error) {
    if (ScannerService.isPermissionDenied(error.errorCode) && !_cameraDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_cameraDenied) {
          setState(() {
            _cameraDenied = true;
            // The viewfinder (and its laser) is replaced by the denied UI;
            // stop the animation so it doesn't burn CPU off-screen.
            _laserController.stop();
          });
          // Resolve whether the denial is permanent so the CTA can deep-link
          // to system settings instead of re-prompting (which is a no-op once
          // the user picked "don't ask again"). Async — the denied UI renders
          // immediately with the retry CTA and upgrades once this resolves.
          _resolvePermanentDenial();
        }
      });
    }
  }

  /// Queries the OS for whether camera permission is permanently denied and
  /// updates the denied UI's CTA accordingly. Failures are swallowed — the UI
  /// simply keeps the plain retry CTA.
  Future<void> _resolvePermanentDenial() async {
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
  /// the permission-denied UI — lets a user who has since granted permission in
  /// OS settings recover without dismounting the screen.
  void _retryCameraPermission() {
    if (kIsWeb) return;
    _scannerService?.dispose();
    _scannerService = widget.scannerService ?? ScannerService();
    _scannerService!.initialize();
    setState(() {
      _cameraDenied = false;
      _cameraPermanentlyDenied = false;
      // Viewfinder is back — resume the scanning laser animation.
      _laserController.repeat(reverse: true);
    });
  }

  Widget _buildScannerSection() {
    if (kIsWeb) {
      return _buildManualBarcodeEntry();
    }

    if (_cameraDenied) {
      return _buildCameraPermissionDenied();
    }

    final controller = _scannerService?.controller;
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סריקת ברקוד',
          style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Live camera feed (or placeholder while loading).
                if (controller != null)
                  widget.mobileScannerBuilder != null
                      ? widget.mobileScannerBuilder!(
                          controller,
                          (ctx, error) {
                            onScannerError(error);
                            return _buildCameraError();
                          },
                        )
                      : MobileScanner(
                          controller: controller,
                          onDetect: _handleBarcodeScan,
                          errorBuilder: (context, error) {
                            onScannerError(error);
                            return _buildCameraError();
                          },
                          placeholderBuilder: (_) => ColoredBox(
                            color: colorScheme.inverseSurface,
                          ),
                        )
                else
                  ColoredBox(color: colorScheme.inverseSurface),
                // Instruction overlay — only over the black placeholder.
                // Once the live feed is up (controller != null) it would be
                // stamped over the viewfinder, so hide it then.
                if (controller == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: colorScheme.onInverseSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'הצמד את הברקוד למצלמה',
                          style: AppTypography.bodyMd.copyWith(
                            color: colorScheme.onInverseSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildCornerAccents(),
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 20 + (_laserAnimation.value * 200),
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: appColors.scanFrame,
                          boxShadow: [
                            BoxShadow(
                              color: appColors.scanFrame.withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shown inside the viewfinder when [MobileScanner] reports a non-permission
  /// error (generic / unsupported).  For the permission-denied case the whole
  /// section switches to [_buildCameraPermissionDenied] instead.
  Widget _buildCameraError() {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.inverseSurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onInverseSurface,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'שגיאת מצלמה',
              style: AppTypography.bodyMd.copyWith(
                color: colorScheme.onInverseSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-section replacement shown when the OS has denied camera permission.
  Widget _buildCameraPermissionDenied() {
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
            size: 64,
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
          // When the OS permanently denied access, a retry would silently
          // re-prompt with no effect — deep-link to system settings instead.
          if (_cameraPermanentlyDenied)
            OutlinedButton.icon(
              onPressed: _openCameraSettings,
              icon: const Icon(Icons.settings),
              label: const Text('פתח הגדרות'),
            )
          else
            OutlinedButton.icon(
              onPressed: _retryCameraPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
        ],
      ),
    );
  }

  Widget _buildManualBarcodeEntry() {
    return ManualBarcodeEntry(
      onSubmitted: (barcode) {
        if (barcode.isNotEmpty) {
          _handleBarcodeScan(
            BarcodeCapture(barcodes: [Barcode(rawValue: barcode)]),
          );
        }
      },
    );
  }

  Widget _buildCornerAccents() {
    const cornerSize = 32.0;
    const strokeWidth = 4.0;
    final scanFrameColor = context.colors.scanFrame;

    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          child: _buildCorner(scanFrameColor, cornerSize, strokeWidth,
              topLeft: true),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _buildCorner(scanFrameColor, cornerSize, strokeWidth,
              topRight: true),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: _buildCorner(scanFrameColor, cornerSize, strokeWidth,
              bottomLeft: true),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildCorner(scanFrameColor, cornerSize, strokeWidth,
              bottomRight: true),
        ),
      ],
    );
  }

  Widget _buildCorner(
    Color color,
    double size,
    double strokeWidth, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          strokeWidth: strokeWidth,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  Widget _buildRecentScansSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'נסרק לאחרונה',
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Per spec §7.4 (search-scan.md) the section is NOT hidden when empty —
        // the drawn empty-state (Stitch bc36d27a) is rendered instead.
        if (_recentScans.isEmpty)
          const StateView(
            icon: Icons.history,
            title: 'אין סריקות אחרונות',
            message: 'מוצרים שתסרוק יופיעו כאן.',
          )
        else
          ..._recentScans.map((scan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RecentScanCard(scan: scan),
              )),
      ],
    );
  }

  Widget _buildSafetyTipSection() {
    final tip = _safetyTips[DateTime.now().day % _safetyTips.length];

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primaryContainer,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'טיפ בטיחות',
                  style: AppTypography.labelBold.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tip,
                  style: AppTypography.bodyMd.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Manual barcode entry shown on web (no camera). Extracted as a named,
/// [visibleForTesting] widget so its digit-only restriction and width
/// constraint (issue #323) are unit-testable without faking `kIsWeb`.
@visibleForTesting
class ManualBarcodeEntry extends StatelessWidget {
  /// Called with the trimmed entered barcode when the user submits the field.
  final ValueChanged<String> onSubmitted;

  /// Max width of the input, keeping it consistent with other form fields
  /// instead of stretching full-width on wide web viewports (issue #323).
  static const double maxFieldWidth = 320;

  const ManualBarcodeEntry({super.key, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הכנס ברקוד',
          style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxFieldWidth),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'הכנס ברקוד',
                      hintText: '72900...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    // On web `keyboardType` is only a hint; the formatter is
                    // what actually blocks letters/symbols (issue #323).
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => onSubmitted(value.trim()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final RecentScan scan;

  const _RecentScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_basket,
              // outlineVariant is the nearest token to the original
              // Colors.grey[400], preserving the light mid-grey look.
              color: colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.name,
                  style: AppTypography.labelBold.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  scan.brand,
                  style: AppTypography.labelSm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: scan.status),
              const SizedBox(height: AppSpacing.xs),
              Text(
                scan.time,
                style: AppTypography.labelSm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (bottomRight) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}