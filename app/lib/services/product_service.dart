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
    String? imageUrl,
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

    // Insert the product and its allergen rows atomically via a Postgres
    // function (issue #45). A function body is one implicit transaction, so the
    // product and all product_allergens rows commit together — no more
    // client-side "insert product, then delete it if the allergen insert fails"
    // rollback dance, and no orphaned-product window if the process dies
    // mid-call.
    final rows = await _client.rpc(
      'add_product_with_allergens',
      params: {
        'p_name_he': nameHe,
        'p_barcode': barcode,
        'p_brand_id': brandId,
        'p_ingredients': ingredients,
        'p_is_kosher': isKosher,
        'p_image_url': imageUrl,
        'contain_ids': containAllergenIds,
        'may_contain_ids': mayContainAllergenIds,
      },
    ) as List<dynamic>;

    final product = rows.first as Map<String, dynamic>;

    return Product(
      id: product['id'] as String,
      nameHe: product['name_he'] as String,
      barcode: product['barcode'] as String?,
      brandId: product['brand_id'] as String?,
      brandNameHe: product['brand_name_he'] as String?,
      brandTrustScore: (product['brand_trust_score'] as num?)?.toDouble(),
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

  Future<Product?> searchProduct(String barcode) async {
    final response = await _client
        .from('products')
        .select('*, brands(name_he, trust_score)')
        .eq('barcode', barcode)
        .maybeSingle();
    
    if (response == null) return null;
    
    final allergenResponse = await _client
        .from('product_allergens')
        .select('product_id, allergen_id, severity, allergens(name_he, emoji)')
        .eq('product_id', response['id']);
    
    final allergenIds = <String>[];
    for (final pa in allergenResponse) {
      allergenIds.add(pa['allergen_id'] as String);
    }
    
    return Product(
      id: response['id'] as String,
      nameHe: response['name_he'] as String,
      barcode: response['barcode'] as String?,
      brandId: response['brand_id'] as String?,
      brandNameHe: response['brands']?['name_he'] as String?,
      imageUrl: response['image_url'] as String?,
      ingredients: response['ingredients'] as String?,
      allergenIds: allergenIds,
    );
  }

  Future<void> updateProductAllergens(
    String productId,
    List<String> containAllergenIds,
    List<String> mayContainAllergenIds,
  ) async {
    await _client.from('product_allergens').delete().eq('product_id', productId);
    
    for (final id in containAllergenIds) {
      await _client.from('product_allergens').insert({
        'product_id': productId,
        'allergen_id': id,
        'severity': 'contains',
      });
    }
    
    for (final id in mayContainAllergenIds) {
      await _client.from('product_allergens').insert({
        'product_id': productId,
        'allergen_id': id,
        'severity': 'may_contain',
      });
    }
  }
}
