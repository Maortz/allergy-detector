import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client;

  ProductService(this._client);

  Future<List<Product>> searchProducts(String query) async {
    final response = await _client
        .from('products')
        .select(
            ''', brands(name_he, trust_score), product_allergens(allergen_id, severity, allergens(name_he))''')
        .ilike('name_he', '%$query%')
        .eq('is_archived', false)
        .limit(20);

    return (response as List).map((json) {
      final map = json as Map<String, dynamic>;
      final allergenList = (map['product_allergens'] as List?)?.map((pa) {
            final paMap = pa as Map<String, dynamic>;
            final allergen = paMap['allergens'] as Map<String, dynamic>;
            return ProductAllergen(
              allergenId: paMap['allergen_id'] as String,
              allergenNameHe: allergen['name_he'] as String,
              severity: paMap['severity'] as String,
            );
          }).toList() ??
          [];

      return Product(
        id: map['id'] as String,
        nameHe: map['name_he'] as String,
        barcode: map['barcode'] as String?,
        brandId: map['brand_id'] as String?,
        brandNameHe: map['brands']?['name_he'] as String?,
        brandTrustScore: map['brands']?['trust_score'] as double?,
        imageUrl: map['image_url'] as String?,
        isArchived: map['is_archived'] as bool? ?? false,
        allergens: allergenList,
      );
    }).toList();
  }
}
