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

  List<ProductAllergen> get containsAllergens => allergens
      .where((a) => a.severityLevel == AllergenSeverity.contains)
      .toList();

  List<ProductAllergen> get mayContainAllergens => allergens
      .where((a) => a.severityLevel == AllergenSeverity.mayContain)
      .toList();
}

/// Severity of an allergen's presence in a product.
///
/// Maps the raw DB `severity` string fail-safe: any unrecognised value
/// (typo, `trace`, a future severity, …) resolves to [contains] — the
/// strongest warning — so an unknown severity is never silently treated as
/// safe. See issue #105.
enum AllergenSeverity {
  contains('contains'),
  mayContain('may_contain');

  const AllergenSeverity(this.wireValue);

  /// The raw string stored in / sent to the DB `product_allergens.severity`.
  final String wireValue;

  /// Parses a raw DB severity string, defaulting unknown values to [contains].
  static AllergenSeverity fromWire(String? value) {
    return AllergenSeverity.values.firstWhere(
      (s) => s.wireValue == value,
      orElse: () => AllergenSeverity.contains,
    );
  }
}

class ProductAllergen {
  final String allergenId;
  final String allergenNameHe;

  /// Raw severity string as stored in the DB. Prefer [severityLevel] for any
  /// safety logic — it resolves unknown values fail-safe to "contains".
  final String severity;

  ProductAllergen({
    required this.allergenId,
    required this.allergenNameHe,
    required this.severity,
  });

  /// Lazily-parsed, cached severity. Computed once on first access to avoid
  /// re-running [AllergenSeverity.fromWire]'s linear enum scan on every call —
  /// [severityLevel] is read repeatedly per allergen per frame in hot paths
  /// (e.g. rendering long search-results lists). See issue #113.
  late final AllergenSeverity _severityLevel = AllergenSeverity.fromWire(
    severity,
  );

  /// The fail-safe parsed severity. Unknown raw values resolve to
  /// [AllergenSeverity.contains] so they are never treated as safe (#105).
  AllergenSeverity get severityLevel => _severityLevel;
}
