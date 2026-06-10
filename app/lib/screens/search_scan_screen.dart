import '../services/scanner_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../models/recent_scan.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
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

  /// Recent scans to render. `null` falls back to a sample list **in debug
  /// builds only**; pass `const []` to render the empty-state StateView
  /// (spec §7.4 bc36d27a). Exists purely as a test seam — production
  /// callers must not bypass [SearchCache] (spec §6).
  @visibleForTesting
  final List<RecentScan>? recentScans;

  final ValueChanged<UserProfile>? onProfileUpdated;

  const SearchScanScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.productService,
    this.onProfileUpdated,
    this.scannerService,
    this.mobileScannerBuilder,
    this.recentScans,
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

  static const List<RecentScan> _sampleRecentScans = [
    RecentScan(
      name: 'חלב שולו 5%',
      brand: 'שולו',
      time: 'לפני שעה',
      status: AllergenStatus.safe,
    ),
    RecentScan(
      name: 'לחם מחמצת',
      brand: 'לחמייה',
      time: 'אתמול',
      status: AllergenStatus.caution,
    ),
  ];

  /// In release builds the sample list is suppressed so users don't see mock
  /// scans they never made; until real `SearchCache` wiring lands, the section
  /// stays hidden via the §7.4 empty-state path. Debug builds keep the sample
  /// for dev/Stitch parity.
  List<RecentScan> get _recentScans =>
      widget.recentScans ?? (kDebugMode ? _sampleRecentScans : const []);

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
        ),
      ),
    );
  }

  Future<void> _handleBarcodeScan(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || _scanBusy) return;
    setState(() => _scanBusy = true);
    try {
      final product = await _resolvedProductService.searchProduct(barcode);
      if (!mounted) return;
      if (product != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              userProfile: widget.userProfile,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('מוצר לא נמצא במאגר')),
        );
      }
    } catch (_) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סריקת ברקוד',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
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
                          placeholderBuilder: (_) => const ColoredBox(
                            color: AppColors.inverseSurface,
                          ),
                        )
                else
                  const ColoredBox(color: AppColors.inverseSurface),
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
                          color: AppColors.inverseOnSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'הצמד את הברקוד למצלמה',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.inverseOnSurface.withValues(alpha: 0.7),
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
                          color: AppColors.scanFrame,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.scanFrame.withValues(alpha: 0.8),
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
    return ColoredBox(
      color: AppColors.inverseSurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.inverseOnSurface,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'שגיאת מצלמה',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.inverseOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-section replacement shown when the OS has denied camera permission.
  Widget _buildCameraPermissionDenied() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'גישה למצלמה נדחתה',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'כדי לסרוק ברקודים יש לאפשר גישה למצלמה בהגדרות המכשיר.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הכנס ברקוד',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard,
                  size: 48,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'הכנס ברקוד',
                    hintText: '72900...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    final barcode = value.trim();
                    if (barcode.isNotEmpty) {
                      _handleBarcodeScan(
                        BarcodeCapture(
                          barcodes: [Barcode(rawValue: barcode)],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerAccents() {
    const cornerSize = 32.0;
    const strokeWidth = 4.0;
    const scanFrameColor = AppColors.scanFrame;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'נסרק לאחרונה',
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryFixedDim,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: AppColors.onPrimary,
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
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tip,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
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

class _RecentScanCard extends StatelessWidget {
  final RecentScan scan;

  const _RecentScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_basket,
              // outlineVariant (#C2C6D4) is the nearest token to the original
              // Colors.grey[400] (#BDBDBD), preserving the light mid-grey look.
              color: AppColors.outlineVariant,
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
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  scan.brand,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
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
                  color: AppColors.onSurfaceVariant,
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