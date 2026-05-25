import '../services/scanner_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/search_input.dart';
import '../widgets/state_view.dart';
import '../widgets/status_badge.dart';

class SearchScanScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;
  final ProductService? productService;

  /// Injectable for tests/empty-state; null falls back to the sample list.
  final List<RecentScan>? recentScans;

  /// Injectable for tests; null constructs a real [ScannerService] off-web.
  final ScannerService? scannerService;

  const SearchScanScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.productService,
    this.recentScans,
    this.scannerService,
  });

  @override
  State<SearchScanScreen> createState() => _SearchScanScreenState();
}

class _SearchScanScreenState extends State<SearchScanScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  ScannerService? _scannerService;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _cameraDenied = false;

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

  List<RecentScan> get _recentScans => widget.recentScans ?? _sampleRecentScans;

  final List<String> _safetyTips = [
    'סרוק את הברקוד על האריזה לקבלת מידע מדויק',
    'בדוק את רשימת המרכיבים בזהירות',
    'שמור על רשימת האלרגנים שלך מעודכנת',
  ];

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _scannerService = widget.scannerService ?? ScannerService();
      _initScanner();
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
    _searchController.dispose();
    _laserController.dispose();
    _scannerService?.dispose();
    super.dispose();
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
      controller: _searchController,
      hintText: 'חפש מוצר או מרכיב...',
    );
  }

  Future<void> _initScanner() async {
    try {
      await _scannerService!.initialize();
    } catch (_) {
      if (mounted) setState(() => _cameraDenied = true);
    }
  }

  Widget _buildScannerSection() {
    if (kIsWeb) {
      return _buildManualBarcodeEntry();
    }

    if (_cameraDenied) {
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
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: StateView(
                icon: Icons.no_photography_outlined,
                title: 'אין גישה למצלמה',
                message: 'כדי לסרוק ברקוד, יש לאפשר גישה למצלמה בהגדרות המכשיר.',
                actionLabel: 'נסה שוב',
                onAction: () {
                  setState(() => _cameraDenied = false);
                  _initScanner();
                },
              ),
            ),
          ),
        ],
      );
    }

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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'הצמד את הברקוד למצלמה',
                        style: AppTypography.bodyMd.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
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
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.8),
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
                  decoration: InputDecoration(
                    labelText: 'הכנס ברקוד',
                    hintText: '72900...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
    const redColor = Colors.red;

    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          child: _buildCorner(redColor, cornerSize, strokeWidth, topLeft: true),
        ),
        Positioned(
          top: 12,
          right: 12,
          child:
              _buildCorner(redColor, cornerSize, strokeWidth, topRight: true),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: _buildCorner(redColor, cornerSize, strokeWidth,
              bottomLeft: true),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildCorner(redColor, cornerSize, strokeWidth,
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
            const Icon(
              Icons.history,
              color: AppColors.onSurfaceVariant,
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

class RecentScan {
  final String name;
  final String brand;
  final String time;
  final AllergenStatus status;

  const RecentScan({
    required this.name,
    required this.brand,
    required this.time,
    required this.status,
  });
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_basket,
              color: Colors.grey[400],
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