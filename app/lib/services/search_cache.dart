import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class SearchCache {
  static const _cacheKey = 'search_cache';
  static const _cacheTimestampKey = 'search_cache_timestamp';

  // --- Barcode-result cache (issue #81) ---
  //
  // Barcode scans resolve to a single product by exact barcode, so they cache
  // independently of the text-search results map (keyed by barcode string)
  // with their own freshness timestamp. Same SharedPreferences-backed,
  // TTL-bounded pattern as the text search above; reuses [_productToJson] /
  // [_productFromJson] for the payload shape.
  static const _barcodeCacheKey = 'search_cache_barcode';
  static const _barcodeTimestampKey = 'search_cache_barcode_timestamp';

  /// How long a cached result stays fresh.
  ///
  /// 30 minutes balances two forces: product/allergen rows change rarely
  /// (admin edits, not user-facing churn), so a long TTL avoids redundant
  /// Supabase round-trips on repeat searches/scans; but the catalog *can* be
  /// corrected (e.g. a fixed allergen mislabel), so we don't want a stale entry
  /// to outlive a realistic browsing session. Note: the **allergen status**
  /// shown to the user is NOT cached — it's recomputed at render time against
  /// the live profile (see `ProductCard.status`), so a profile/allergen change
  /// is reflected immediately regardless of this TTL. Reviewed for #81; kept.
  static const staleThreshold = Duration(minutes: 30);

  static Future<void> save(String query, List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = await _getFullCache();
    cache[query.toLowerCase()] =
        products.map((p) => _productToJson(p)).toList();
    await prefs.setString(_cacheKey, jsonEncode(cache));
    await prefs.setString(
        _cacheTimestampKey, DateTime.now().toUtc().toIso8601String());
  }

  static Future<List<Product>?> load(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_cacheTimestampKey);
    if (timestampStr != null) {
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > staleThreshold) {
        return null;
      }
    }

    final cache = await _getFullCache();
    final cached = cache[query.toLowerCase()];
    if (cached == null) return null;

    return (cached as List)
        .map((json) => _productFromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> isStale() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_cacheTimestampKey);
    if (timestampStr == null) return true;
    final timestamp = DateTime.parse(timestampStr);
    return DateTime.now().difference(timestamp) > staleThreshold;
  }

  /// Caches the [product] resolved for an exact [barcode] scan. Storing `null`
  /// is intentionally not supported — a "not found" result is cheap to re-query
  /// and we don't want to pin a miss past a later catalog insert.
  static Future<void> saveBarcode(String barcode, Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = await _getBarcodeCache();
    cache[barcode] = _productToJson(product);
    await prefs.setString(_barcodeCacheKey, jsonEncode(cache));
    await prefs.setString(
        _barcodeTimestampKey, DateTime.now().toUtc().toIso8601String());
  }

  /// Returns the cached product for [barcode], or `null` on a miss or once the
  /// barcode cache has aged past [staleThreshold].
  static Future<Product?> loadBarcode(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_barcodeTimestampKey);
    if (timestampStr != null) {
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > staleThreshold) {
        return null;
      }
    }

    final cache = await _getBarcodeCache();
    final cached = cache[barcode];
    if (cached == null) return null;
    return _productFromJson(cached as Map<String, dynamic>);
  }

  /// Clears every cached search/barcode result and their freshness timestamps.
  /// Used by the app-preferences "clear search cache" action (issue #188); the
  /// next search/scan re-queries Supabase from scratch.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_barcodeCacheKey);
    await prefs.remove(_barcodeTimestampKey);
  }

  static Future<Map<String, dynamic>> _getBarcodeCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_barcodeCacheKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _getFullCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Map<String, dynamic> _productToJson(Product p) => {
        'id': p.id,
        'name_he': p.nameHe,
        'barcode': p.barcode,
        'brand_name_he': p.brandNameHe,
        'brand_trust_score': p.brandTrustScore,
        'image_url': p.imageUrl,
        'allergens': p.allergens
            .map((a) => {
                  'allergen_id': a.allergenId,
                  'allergen_name_he': a.allergenNameHe,
                  'severity': a.severity,
                })
            .toList(),
      };

  static Product _productFromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        nameHe: json['name_he'] as String,
        barcode: json['barcode'] as String?,
        brandNameHe: json['brand_name_he'] as String?,
        brandTrustScore: json['brand_trust_score'] as double?,
        imageUrl: json['image_url'] as String?,
        allergens: (json['allergens'] as List?)
                ?.map((a) {
                  final m = a as Map;
                  return ProductAllergen(
                    allergenId: m['allergen_id'] as String,
                    allergenNameHe: m['allergen_name_he'] as String,
                    severity: m['severity'] as String,
                  );
                })
                .toList() ??
            [],
      );
}
