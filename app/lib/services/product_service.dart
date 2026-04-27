import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client;

  ProductService(this._client);

  Future<List<Product>> searchProducts(String query, {int page = 0, int limit = 20}) async {
    PostgrestList productResponse;
    
    if (query.trim().isEmpty) {
      productResponse = await _client
          .from('products')
          .select('*, brands(name_he, trust_score)')
          .eq('is_archived', false)
          .range(page * limit, (page + 1) * limit - 1)
          .order('name_he');
    } else {
      productResponse = await _client
          .from('products')
          .select('*, brands(name_he, trust_score)')
          .eq('is_archived', false)
          .like('name_he', '%$query%')
          .range(page * limit, (page + 1) * limit - 1)
          .order('name_he');
    }

    if (productResponse.isEmpty) return [];

    final productIds = productResponse.map((p) => p['id'] as String).toList();

    final allergenResponse = await _client
        .from('product_allergens')
        .select('product_id, allergen_id, severity, allergens(name_he)')
        .filter('product_id', 'in', '(${productIds.join(",")})');

    final allergenByProduct = <String, List<ProductAllergen>>{};
    for (final pa in allergenResponse) {
      final productId = pa['product_id'] as String;
      final allergenData = pa['allergens'] as Map<String, dynamic>?;
      allergenByProduct.putIfAbsent(productId, () => []);
      allergenByProduct[productId]!.add(ProductAllergen(
        allergenId: pa['allergen_id'] as String,
        allergenNameHe: allergenData?['name_he'] as String? ?? 'לא ידוע',
        severity: pa['severity'] as String,
      ));
    }

    return productResponse.map((map) {
      return Product(
        id: map['id'] as String,
        nameHe: map['name_he'] as String,
        barcode: map['barcode'] as String?,
        brandId: map['brand_id'] as String?,
        brandNameHe: map['brands']?['name_he'] as String?,
        brandTrustScore: map['brands']?['trust_score'] as double?,
        imageUrl: map['image_url'] as String?,
        ingredients: map['ingredients'] as String?,
        isKosher: map['is_kosher'] as bool? ?? false,
        isArchived: map['is_archived'] as bool? ?? false,
        allergens: allergenByProduct[map['id'] as String] ?? [],
      );
    }).toList();
  }

  Future<Product> addProduct({
    required String nameHe,
    String? brandName,
    String? barcode,
    String? ingredients,
    bool isKosher = false,
    List<String> containAllergenIds = const [],
    List<String> mayContainAllergenIds = const [],
  }) async {
    String? brandId;
    
    if (brandName != null && brandName.isNotEmpty) {
      final brandResponse = await _client
          .from('brands')
          .select('id')
          .eq('name_he', brandName)
          .maybeSingle();
      
      if (brandResponse != null) {
        brandId = brandResponse['id'] as String;
      } else {
        final newBrand = await _client
            .from('brands')
            .insert({
              'name_he': brandName,
              'trust_score': 0.5,
            })
            .select()
            .single();
        brandId = newBrand['id'] as String;
      }
    }

    final product = await _client
        .from('products')
        .insert({
          'name_he': nameHe,
          'barcode': barcode,
          'brand_id': brandId,
          'ingredients': ingredients,
          'is_kosher': isKosher,
        })
        .select('*, brands(name_he, trust_score)')
        .single();

    final productId = product['id'] as String;

    final allergenInserts = <Map<String, dynamic>>[];
    
    for (final allergenId in containAllergenIds) {
      allergenInserts.add({
        'product_id': productId,
        'allergen_id': allergenId,
        'severity': 'contains',
      });
    }
    
    for (final allergenId in mayContainAllergenIds) {
      allergenInserts.add({
        'product_id': productId,
        'allergen_id': allergenId,
        'severity': 'may_contain',
      });
    }

    if (allergenInserts.isNotEmpty) {
      await _client.from('product_allergens').insert(allergenInserts);
    }

    return Product(
      id: productId,
      nameHe: product['name_he'] as String,
      barcode: product['barcode'] as String?,
      brandId: product['brand_id'] as String?,
      brandNameHe: product['brands']?['name_he'] as String?,
      brandTrustScore: product['brands']?['trust_score'] as double?,
      imageUrl: product['image_url'] as String?,
      ingredients: product['ingredients'] as String?,
      isKosher: product['is_kosher'] as bool? ?? false,
      isArchived: product['is_archived'] as bool? ?? false,
      allergens: [],
    );
  }

  Future<void> archiveProduct(String productId) async {
    await _client
        .from('products')
        .update({'is_archived': true})
        .eq('id', productId);
  }
}
