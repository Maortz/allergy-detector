class Product {
  final String id;
  final String nameHe;
  final String? barcode;
  final String? brandId;
  final String? brandNameHe;
  final double? brandTrustScore;
  final String? imageUrl;
  final String? ingredients;
  final bool isKosher;
  final List<ProductAllergen> allergens;
  final bool isArchived;
  final List<String>? allergenIds;

  const Product({
    required this.id,
    required this.nameHe,
    this.barcode,
    this.brandId,
    this.brandNameHe,
    this.brandTrustScore,
    this.imageUrl,
    this.ingredients,
    this.isKosher = false,
    this.allergens = const [],
    this.isArchived = false,
    this.allergenIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      nameHe: json['name_he'] as String,
      barcode: json['barcode'] as String?,
      brandId: json['brand_id'] as String?,
      brandNameHe: json['brands']?['name_he'] as String?,
      brandTrustScore: json['brands']?['trust_score'] as double?,
      imageUrl: json['image_url'] as String?,
      ingredients: json['ingredients'] as String?,
      isKosher: json['is_kosher'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  List<ProductAllergen> get containsAllergens =>
      allergens.where((a) => a.severity == 'contains').toList();

  List<ProductAllergen> get mayContainAllergens =>
      allergens.where((a) => a.severity == 'may_contain').toList();
}

class ProductAllergen {
  final String allergenId;
  final String allergenNameHe;
  final String severity;

  const ProductAllergen({
    required this.allergenId,
    required this.allergenNameHe,
    required this.severity,
  });
}
