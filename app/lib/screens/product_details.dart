import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'feedback_screen.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';
import '../widgets/bottom_nav_bar.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final UserProfile userProfile;
  final VoidCallback? onReport;
  final VoidCallback? onDeleted;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.userProfile,
    this.onReport,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final status = _computeStatus(product, userProfile);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(product.nameHe),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareProduct(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBanner(status),
              if (product.imageUrl != null)
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 300,
                      color: AppColors.surfaceContainerHigh,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.nameHe,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (product.brandNameHe != null)
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            product.brandNameHe!,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (product.brandTrustScore != null &&
                              product.brandTrustScore! >= 0.7) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                    if (product.isKosher) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.safeText, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'כשר',
                            style: AppTypography.labelBold.copyWith(color: AppColors.safeText),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildAllergensSection(),
                    if (product.ingredients != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildIngredientsSection(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeedbackScreen(
                                productId: product.id,
                                productName: product.nameHe,
                                onSubmit: (type, message) async {},
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.flag),
                        label: const Text('דיווח על טעות'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          side: BorderSide(color: AppColors.outlineVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: (index) {},
        ),
      ),
    );
  }

  Widget _buildStatusBanner(AllergenStatus status) {
    final (backgroundColor, textColor, label) = switch (status) {
      AllergenStatus.avoid => (
          AppColors.avoid,
          AppColors.onAvoid,
          'הימנע – מכיל אלרגנים',
        ),
      AllergenStatus.caution => (
          AppColors.cautionBackground,
          AppColors.cautionText,
          'זהירות - עשוי להכיל',
        ),
      AllergenStatus.safe => (
          AppColors.safeBackground,
          AppColors.safeText,
          '✓ בטוח - ללא אלרגנים עבורך',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == AllergenStatus.safe
                ? Icons.check_circle
                : status == AllergenStatus.caution
                    ? Icons.warning
                    : Icons.cancel,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: AppTypography.h3.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensSection() {
    final userAllergenIds = userProfile.selectedAllergenIds;
    final allProductAllergens = [...product.containsAllergens, ...product.mayContainAllergens];

    if (allProductAllergens.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'אלרגנים שזוהו',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        ...allProductAllergens.map((pa) {
          final isDangerous = pa.severity == 'contains' && userAllergenIds.contains(pa.allergenId);
          final isCaution = pa.severity == 'may_contain' && userAllergenIds.contains(pa.allergenId);

          final color = isDangerous ? AppColors.avoidText : isCaution ? AppColors.cautionText : AppColors.safeText;
          final label = isDangerous ? 'הימנע' : isCaution ? 'זהירות' : 'בטוח לך';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAllergenIcon(pa.allergenId),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      pa.allergenNameHe,
                      style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.labelBold.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'רכיבים',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            childrenPadding: const EdgeInsets.all(AppSpacing.md),
            title: Text(
              'לחץ להצגת רכיבים',
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
            children: [
              Text(
                product.ingredients!,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  IconData _getAllergenIcon(String allergenId) {
    final id = allergenId.toLowerCase();
    if (id.contains('milk') || id.contains('dairy')) {
      return Icons.water_drop;
    } else if (id.contains('egg')) {
      return Icons.egg;
    } else if (id.contains('wheat') || id.contains('gluten')) {
      return Icons.grass;
    } else if (id.contains('soy')) {
      return Icons.eco;
    } else if (id.contains('nut') || id.contains('peanut')) {
      return Icons.spa;
    } else if (id.contains('fish')) {
      return Icons.set_meal;
    } else if (id.contains('shellfish') || id.contains('crustacean')) {
      return Icons.pool;
    } else if (id.contains('sesame')) {
      return Icons.grain;
    }
    return Icons.warning_amber;
  }

  void _shareProduct(BuildContext context) {
    final text = 'בדוק את המוצר ${product.nameHe} באפליקציית Allergy Detector';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.success(context, 'הקישור הועתק ללוח');
  }

  AllergenStatus _computeStatus(Product product, UserProfile profile) {
    final userAllergenIds = profile.selectedAllergenIds;
    for (final a in product.containsAllergens) {
      if (userAllergenIds.contains(a.allergenId)) {
        return AllergenStatus.avoid;
      }
    }
    for (final a in product.mayContainAllergens) {
      if (userAllergenIds.contains(a.allergenId)) {
        return AllergenStatus.caution;
      }
    }
    return AllergenStatus.safe;
  }
}
