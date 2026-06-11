import 'product.dart';

/// A persisted "favorite" product, saved locally so the user can return to
/// products they care about without re-scanning.
///
/// Like [ScanHistoryEntry], this is a durable, presentation-light snapshot of
/// the product identity captured at the moment it was favorited — enough to
/// render the FavoritesScreen list tile (name, brand, image) without a network
/// round-trip. Allergen status is intentionally NOT stored: it depends on the
/// current profile and is recomputed when the user opens the product.
///
/// MVP is local-only — no Supabase-backed favorites sync until auth lands
/// (issue #85 "Out of scope").
class FavoriteProduct {
  final String productId;
  final String nameHe;
  final String? brandNameHe;
  final String? imageUrl;
  final DateTime addedAt;

  const FavoriteProduct({
    required this.productId,
    required this.nameHe,
    this.brandNameHe,
    this.imageUrl,
    required this.addedAt,
  });

  /// Builds a favorite snapshot from a resolved [product].
  ///
  /// [now] is injectable for deterministic tests; defaults to `DateTime.now()`.
  factory FavoriteProduct.fromProduct(Product product, {DateTime? now}) =>
      FavoriteProduct(
        productId: product.id,
        nameHe: product.nameHe,
        brandNameHe: product.brandNameHe,
        imageUrl: product.imageUrl,
        addedAt: now ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name_he': nameHe,
        'brand_name_he': brandNameHe,
        'image_url': imageUrl,
        'added_at': addedAt.toUtc().toIso8601String(),
      };

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) =>
      FavoriteProduct(
        productId: json['product_id'] as String,
        nameHe: json['name_he'] as String,
        brandNameHe: json['brand_name_he'] as String?,
        imageUrl: json['image_url'] as String?,
        addedAt: DateTime.parse(json['added_at'] as String),
      );
}
