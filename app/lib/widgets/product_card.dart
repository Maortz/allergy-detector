import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/user_profile.dart';

enum AllergenStatus { safe, caution, avoid }

class ProductCard extends StatelessWidget {
  final Product product;
  final UserProfile userProfile;
  final VoidCallback? onReport;

  const ProductCard({
    super.key,
    required this.product,
    required this.userProfile,
    this.onReport,
  });

  AllergenStatus get status {
    final userAllergenIds = userProfile.selectedAllergenIds;
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

  Color get statusColor {
    switch (status) {
      case AllergenStatus.avoid:
        return Colors.red;
      case AllergenStatus.caution:
        return Colors.orange;
      case AllergenStatus.safe:
        return Colors.green;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(Icons.image_not_supported),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.nameHe,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (product.brandNameHe != null)
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Text(
                              product.brandNameHe!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (product.brandTrustScore != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                product.brandTrustScore! >= 0.7
                                    ? Icons.verified
                                    : Icons.help_outline,
                                size: 16,
                                color: product.brandTrustScore! >= 0.7
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (product.containsAllergens.isNotEmpty)
              _buildAllergenRow('מכיל:', product.containsAllergens, Colors.red),
            if (product.mayContainAllergens.isNotEmpty)
              _buildAllergenRow(
                  'עשוי להכיל:', product.mayContainAllergens, Colors.orange),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (onReport != null)
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.report, size: 16),
                    label: const Text('דווח בעיה'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenRow(
      String label, List<ProductAllergen> allergens, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: allergens
                  .map((a) => Chip(
                        label: Text(a.allergenNameHe),
                        labelStyle: const TextStyle(fontSize: 12),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
