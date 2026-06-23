import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final UserProfile userProfile;
  final VoidCallback? onTap;
  final VoidCallback? onReport;

  const ProductCard({
    super.key,
    required this.product,
    required this.userProfile,
    this.onTap,
    this.onReport,
  });

  AllergenStatus get status => userProfile.statusFor(product);

  String get statusLabel {
    switch (status) {
      case AllergenStatus.avoid:
        return 'הימנע';
      case AllergenStatus.caution:
        return 'זהירות';
      case AllergenStatus.safe:
        return 'בטוח';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AllergenStatus.avoid:
        return Icons.dangerous;
      case AllergenStatus.caution:
        return Icons.warning;
      case AllergenStatus.safe:
        return Icons.check_circle;
    }
  }

  Color _statusColor(AppColorsExt colors) {
    switch (status) {
      case AllergenStatus.avoid:
        return colors.avoid;
      case AllergenStatus.caution:
        return colors.warning;
      case AllergenStatus.safe:
        return colors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      product.nameHe,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (product.isKosher)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 6),
                                      child: _buildKosherBadge(context),
                                    ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(context),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildBrandRow(context),
                      ],
                    ),
                  ),
                ],
              ),
              if (product.containsAllergens.isNotEmpty ||
                  product.mayContainAllergens.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _buildContainsRow(context),
                if (product.mayContainAllergens.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildMayContainRow(context),
                ],
              ],
              if (onReport != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag, size: 14),
                    label: const Text('דווח בעיה'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKosherBadge(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.safeBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.safeText),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.abc, size: 11, color: colors.safeText),
          const SizedBox(width: 2),
          Text(
            'כשר',
            style: TextStyle(fontSize: 11, color: colors.safeText),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final surfaceContainerLow =
        Theme.of(context).colorScheme.surfaceContainerLow;
    final iconMuted = context.colors.iconMuted;
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.imageUrl != null
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.shopping_basket, color: iconMuted),
            )
          : Icon(Icons.shopping_basket, color: iconMuted, size: 28),
    );
  }

  Widget _buildBrandRow(BuildContext context) {
    final onSurfaceVariant =
        Theme.of(context).colorScheme.onSurfaceVariant;
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        if (product.brandNameHe != null) ...[
          Flexible(
            child: Text(
              product.brandNameHe!,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (product.brandTrustScore != null &&
              product.brandTrustScore! >= 0.7) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified, size: 14, color: primary),
          ],
        ],
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final statusColor = _statusColor(context.colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 14),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainsRow(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'מכיל:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.avoidText,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: product.containsAllergens
                .map((a) => _buildAllergenChip(a.allergenNameHe, colors.avoid))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMayContainRow(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'עשוי להכיל:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.cautionText,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: product.mayContainAllergens
                .map((a) =>
                    _buildAllergenChip(a.allergenNameHe, colors.warning))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAllergenChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}
