import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand.dart';
import '../services/brand_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';
import '../widgets/search_input.dart';
import '../widgets/admin_brand_form_sheet.dart';
import 'admin_navigation_drawer.dart';

class AdminBrandsScreen extends StatefulWidget {
  final SupabaseClient client;

  /// Called from the admin drawer's logout button after this screen closes
  /// its own drawer. The host (typically `MainContainer`) is responsible for
  /// popping this route and surfacing the standard logout confirmation flow.
  final VoidCallback? onLogout;

  const AdminBrandsScreen({
    super.key,
    required this.client,
    this.onLogout,
  });

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Brand> _brands = [];
  late BrandService _brandService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brandService = BrandService(widget.client);
    _loadBrands();
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
      if (mounted) {
        AppToast.error(context, 'שגיאה בטעינת המותגים');
      }
    }
  }

  void _onAdminDrawerDestinationSelected(AdminDrawerDestination destination) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // close drawer
    if (destination == AdminDrawerDestination.brandManagement) {
      return; // already on this screen
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('מסך זה עדיין בפיתוח — בקרוב')),
    );
  }

  void _onAdminDrawerLogout() {
    Navigator.pop(context); // close drawer
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        title: Text(
          'ניהול מותגים',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        centerTitle: true,
      ),
      endDrawer: AdminNavigationDrawer(
        onDestinationSelected: _onAdminDrawerDestinationSelected,
        onLogout: _onAdminDrawerLogout,
        activeDestination: AdminDrawerDestination.brandManagement,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                SearchInput(
                  controller: _searchController,
                  hintText: 'חפש מותג...',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStats(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _brands.isEmpty
                    ? const _BrandsEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: _brands.length,
                        itemBuilder: (context, index) {
                          return _buildBrandItem(_brands[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showBrandFormSheet(context, brandService: _brandService)
              .then((changed) {
            if (changed) _loadBrands();
          });
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('הוספת מותג חדש'),
      ),
    );
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

  Widget _buildStats() {
    return Row(
      children: [
        Icon(Icons.business, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${_brands.length} מותגים רשומים',
          style: AppTypography.labelSm
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBrandItem(Brand brand) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: brand.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    brand.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.store,
                        color: AppColors.onSurfaceVariant,
                        size: 20),
                  ),
                )
              : Icon(Icons.store,
                  color: AppColors.onSurfaceVariant, size: 20),
        ),
        title: Text(
          brand.name,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  onChanged: (value) => _toggleVerification(brand, value),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showBrandFormSheet(
                  context,
                  brand: brand,
                  brandService: _brandService,
                ).then((changed) {
                  if (changed) _loadBrands();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty-state shown when no brands are registered. Spec ref:
/// `admin-trusted-brands.md §5.3`.
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
            Icon(
              Icons.branding_watermark,
              size: 48,
              color: AppColors.outline,
            ),
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
