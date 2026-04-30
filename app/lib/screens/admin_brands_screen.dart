import 'package:flutter/material.dart' hide NavigationDrawer;
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/search_input.dart';

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _brands = [
    {'id': 1, 'name': 'שוקולד עלית', 'enabled': true},
    {'id': 2, 'name': 'קוקה קולה', 'enabled': true},
    {'id': 3, 'name': 'תנובה', 'enabled': true},
    {'id': 4, 'name': 'פריגת', 'enabled': true},
    {'id': 5, 'name': 'אסם', 'enabled': true},
    {'id': 6, 'name': 'מאמא', 'enabled': false},
    {'id': 7, 'name': 'סנפרוסט', 'enabled': true},
    {'id': 8, 'name': 'בזק', 'enabled': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          'ניהול מותגים',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const NavigationDrawer(),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _brands.length,
              itemBuilder: (context, index) {
                final brand = _brands[index];
                return _buildBrandItem(brand);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('הוספת מותג חדש'),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Icon(Icons.business, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${_brands.length} מותגים רשומים',
          style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBrandItem(Map<String, dynamic> brand) {
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.store, color: Colors.grey[400], size: 20),
        ),
        title: Text(
          brand['name'] as String,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: brand['enabled'] as bool,
          onChanged: (value) {
            setState(() {
              brand['enabled'] = value;
            });
          },
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }
}