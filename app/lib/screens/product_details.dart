import 'package:flutter/material.dart';
import 'feedback_screen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        appBar: AppBar(title: Text(product.nameHe)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (product.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 200,
                        child: Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                product.nameHe,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.right,
              ),
              if (product.isKosher) ...[
                const SizedBox(height: 4),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text('כשר', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ],
              if (product.brandNameHe != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(product.brandNameHe!),
                      if (product.brandTrustScore != null &&
                          product.brandTrustScore! >= 0.7) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                    ],
                  ),
                ),
              if (product.barcode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('ברקוד: ${product.barcode}'),
                ),
              const Divider(height: 32),
              _buildStatusBanner(status),
              const SizedBox(height: 16),
              if (product.containsAllergens.isNotEmpty) ...[
                Text(
                  'מכיל:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: product.containsAllergens
                      .map(
                        (a) => Chip(
                          label: Text(a.allergenNameHe),
                          backgroundColor: Colors.red[50],
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (product.mayContainAllergens.isNotEmpty) ...[
                Text(
                  'עשוי להכיל:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: product.mayContainAllergens
                      .map(
                        (a) => Chip(
                          label: Text(a.allergenNameHe),
                          backgroundColor: Colors.orange[50],
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (product.ingredients != null) ...[
                const Divider(height: 32),
                Text(
                  'רכיבים:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(product.ingredients!, textAlign: TextAlign.right),
              ],
              const SizedBox(height: 24),
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
                          onSubmit: (type, message) async {
                            // TODO: Implement feedback submission
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.report),
                  label: const Text('דווח בעיה'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete),
                  label: const Text('הסר מוצר'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildStatusBanner(AllergenStatus status) {
    final color = switch (status) {
      AllergenStatus.avoid => Colors.red,
      AllergenStatus.caution => Colors.orange,
      AllergenStatus.safe => Colors.green,
    };

    final label = switch (status) {
      AllergenStatus.avoid => 'הימנע',
      AllergenStatus.caution => 'זהירות',
      AllergenStatus.safe => 'בטוח',
    };

    final icon = switch (status) {
      AllergenStatus.avoid => Icons.dangerous,
      AllergenStatus.caution => Icons.warning,
      AllergenStatus.safe => Icons.check_circle,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הסר מוצר'),
        content: Text('האם אתה בטוח שברצונך להסיר את "${product.nameHe}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('הסר'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _archiveProduct(context);
    }
  }

  Future<void> _archiveProduct(BuildContext context) async {
    try {
      final productService = ProductService(Supabase.instance.client);
      await productService.archiveProduct(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('המוצר הוסר בהצלחה')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה: ${e.toString()}')));
      }
    }
  }
}
