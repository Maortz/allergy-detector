import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class SearchCache {
  static const _cacheKey = 'search_cache';
  static const _cacheTimestampKey = 'search_cache_timestamp';
  static const _staleThreshold = Duration(minutes: 30);

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
      if (DateTime.now().difference(timestamp) > _staleThreshold) {
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
    return DateTime.now().difference(timestamp) > _staleThreshold;
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
