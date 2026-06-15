// lib/screens/admin_brands_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand.dart';
import '../models/user_contribution.dart' show relativeTimeHe;
import '../services/brand_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';
import '../widgets/admin_brand_form_sheet.dart';
import 'admin_navigation_drawer.dart';

class AdminBrandsScreen extends StatefulWidget {
  final SupabaseClient? client;
  final BrandService? _brandServiceOverride;
  final bool _isAdminOverride;

  /// Called from the admin drawer's logout button after this screen closes
  /// its own drawer.
  final VoidCallback? onLogout;

  /// Called when another admin-drawer row is tapped while this screen is open.
  final ValueChanged<AdminDrawerDestination>? onDestinationSelected;

  const AdminBrandsScreen({
    super.key,
    required this.client,
    this.onLogout,
    this.onDestinationSelected,
  })  : _brandServiceOverride = null,
        _isAdminOverride = true;

  /// Test-only constructor: injects a pre-built [BrandService] and optional
  /// [isAdmin] override so unit/widget tests never touch Supabase.
  @visibleForTesting
  const AdminBrandsScreen.testable({
    super.key,
    required BrandService brandService,
    bool isAdmin = true,
    this.onLogout,
    this.onDestinationSelected,
  })  : client = null,
        _brandServiceOverride = brandService,
        _isAdminOverride = isAdmin;

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Brand> _brands = [];
  late BrandService _brandService;
  bool _isLoading = false;
  String _searchQuery = '';

  List<Brand> get _filteredBrands {
    if (_searchQuery.isEmpty) return _brands;
    final q = _searchQuery.toLowerCase();
    return _brands.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  int get _verifiedCount => _brands.where((b) => b.isVerified).length;

  double get _verifiedFraction =>
      _brands.isEmpty ? 0.0 : _verifiedCount / _brands.length;

  @override
  void initState() {
    super.initState();
    _brandService =
        widget._brandServiceOverride ?? BrandService(widget.client!);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);
    try {
      final brands = await _brandService.fetchBrands();
      setState(() {
        _brands = brands;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) AppToast.error(context, 'שגיאה בטעינת המותגים');
    }
  }

  void _onAdminDrawerDestinationSelected(AdminDrawerDestination destination) {
    Navigator.pop(context); // close drawer
    if (destination == AdminDrawerDestination.brandManagement) return;
    widget.onDestinationSelected?.call(destination);
  }

  void _onAdminDrawerLogout() {
    Navigator.pop(context);
    widget.onLogout?.call();
  }

  Future<void> _toggleVerification(Brand brand, bool newValue) async {
    if (brand.id == null) return;
    final index = _brands.indexOf(brand);
    if (index == -1) return;
    setState(() => _brands[index] = brand.copyWith(isVerified: newValue));
    try {
      await _brandService.updateVerification(brand.id!, newValue);
    } catch (_) {
      if (!mounted) return;
      setState(() => _brands[index] = brand);
      AppToast.error(context, 'שגיאה בעדכון סטטוס המותג');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
          ),
        ),
        // AppBar has no page title per spec; the H1 lives in the body header.
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
      ),
      endDrawer: AdminNavigationDrawer(
        onDestinationSelected: _onAdminDrawerDestinationSelected,
        onLogout: _onAdminDrawerLogout,
        activeDestination: AdminDrawerDestination.brandManagement,
      ),
      body: widget._isAdminOverride
          ? _buildAuthorisedBody()
          : _buildDeniedBody(),
    );
  }

  // ── Admin-gate denied view (TB11 / §5.9) ─────────────────────────────────

  Widget _buildDeniedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'הגישה מוגבלת למנהלים בלבד',
              textAlign: TextAlign.center,
              style:
                  AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main authorised body ──────────────────────────────────────────────────

  Widget _buildAuthorisedBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.margin,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildBentoRow(),
          const SizedBox(height: AppSpacing.xl),
          _buildBrandList(),
          const SizedBox(height: AppSpacing.xl),
          _buildAddBrandButton(),
        ],
      ),
    );
  }

  // ── Page-header block (TB1 / TB3) ─────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'ניהול מותגים מאושרים',
          style: AppTypography.h1.copyWith(color: AppColors.primary),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'עדכן ואמת מותגים במאגר הנתונים של הקליניקה',
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  // ── Search + Stats bento (TB4 / TB5) ──────────────────────────────────────

  Widget _buildBentoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats card — col-span-1 (narrower, on the left in RTL layout)
        Expanded(
          flex: 1,
          child: _buildStatsCard(),
        ),
        const SizedBox(width: AppSpacing.md),
        // Search card — col-span-2 (wider, on the right in RTL reading order)
        Expanded(
          flex: 2,
          child: _buildSearchCard(),
        ),
      ],
    );
  }

  static BoxDecoration get _bentoCardDecoration => BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0,0,0,0.05)
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _bentoCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'חיפוש מותג',
            style: AppTypography.labelBold
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchController,
            textAlign: TextAlign.right,
            style:
                AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'הקלד שם מותג…',
              hintStyle: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              suffixIcon: const Icon(Icons.search, color: AppColors.outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final total = _brands.length;
    final fraction = _verifiedFraction;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _bentoCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'מותגים רשומים',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              Text(
                _isLoading ? '—' : '$total',
                style: AppTypography.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand list (TB6 / TB7 / TB8) ──────────────────────────────────────────

  Widget _buildBrandList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final filtered = _filteredBrands;
    if (_brands.isEmpty) return const _BrandsEmptyState();
    if (filtered.isEmpty) {
      // Search active but no results
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            'לא נמצאו מותגים עבור «$_searchQuery»',
            style:
                AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final brand in filtered) ...[
          _BrandRowCard(
            brand: brand,
            onToggle: (v) => _toggleVerification(brand, v),
            onEdit: () {
              showBrandFormSheet(
                context,
                brand: brand,
                brandService: _brandService,
              ).then((changed) {
                if (changed) _loadBrands();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  // ── Add-brand button (TB10) ────────────────────────────────────────────────

  Widget _buildAddBrandButton() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FilledButton.icon(
        onPressed: () {
          showBrandFormSheet(context, brandService: _brandService)
              .then((changed) {
            if (changed) _loadBrands();
          });
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          textStyle: AppTypography.labelBold,
        ),
        icon: const Icon(Icons.add, size: 24),
        label: const Text('הוספת מותג חדש'),
      ),
    );
  }
}

// ── Brand row card (stateless) ────────────────────────────────────────────────

class _BrandRowCard extends StatelessWidget {
  final Brand brand;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _BrandRowCard({
    required this.brand,
    required this.onToggle,
    required this.onEdit,
  });

  String get _metadataLine {
    if (!brand.isVerified) return 'ממתין לבדיקת רכיבים';
    if (brand.lastUpdated == null) return 'מאומת';
    return 'עדכון אחרון: ${relativeTimeHe(brand.lastUpdated!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Right side: toggle + edit (RTL: physically on the left)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'סטטוס אימות',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.outline),
                ),
                Switch(
                  value: brand.isVerified,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton(
              icon: const Icon(Icons.edit),
              color: AppColors.outline,
              onPressed: onEdit,
            ),
            const Spacer(),
            // Left side: name + metadata (RTL: physically on the right, leading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  brand.name,
                  style: AppTypography.h3
                      .copyWith(color: AppColors.onSurface),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _metadataLine,
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Thumbnail (56×56, initial-letter chip when no logo)
            _BrandThumbnail(brand: brand),
          ],
        ),
      ),
    );
  }
}

// ── Brand thumbnail (56 pt, initial-letter fallback) ─────────────────────────

class _BrandThumbnail extends StatelessWidget {
  final Brand brand;

  const _BrandThumbnail({required this.brand});

  String get _initial => brand.name.isNotEmpty ? brand.name[0] : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      clipBehavior: Clip.antiAlias,
      child: brand.logoUrl != null
          ? Image.network(
              brand.logoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) =>
                  _InitialChip(initial: _initial),
            )
          : _InitialChip(initial: _initial),
    );
  }
}

class _InitialChip extends StatelessWidget {
  final String initial;

  const _InitialChip({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.primaryTint, // #EBF4FF
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.h3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
      ),
    );
  }
}

// ── Empty state (§5.3) ────────────────────────────────────────────────────────

class _BrandsEmptyState extends StatelessWidget {
  const _BrandsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.branding_watermark, size: 48, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'אין מותגים רשומים',
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'הוסף מותג חדש כדי להתחיל',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
