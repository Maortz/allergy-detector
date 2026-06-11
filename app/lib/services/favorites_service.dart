import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_product.dart';
import '../models/product.dart';

/// Persists the user's favorite products locally, mirroring the
/// SharedPreferences-backed pattern of `ScanHistoryService` / `SearchCache`.
///
/// Storage is a single JSON array under [_storageKey], newest-first, deduped by
/// `productId`. There is no hard cap — a user's favorites set is small and
/// intentional (unlike scan history), so entries persist until explicitly
/// removed.
///
/// MVP is local-only — no Supabase-backed favorites sync (issue #85 out of
/// scope; waits on the auth backend).
class FavoritesService {
  static const _storageKey = 'favorite_products';

  /// Adds [product] to favorites (newest-first). Re-adding a product already
  /// favorited is a no-op beyond moving it to the front, so there are never
  /// duplicates.
  ///
  /// [now] is injectable for deterministic tests; defaults to `DateTime.now()`.
  static Future<void> add(Product product, {DateTime? now}) async {
    final favorite = FavoriteProduct.fromProduct(product, now: now);
    final existing = await favorites();
    final deduped = existing.where((f) => f.productId != favorite.productId);
    await _save([favorite, ...deduped]);
  }

  /// Removes the favorite matching [productId]. No-op if it isn't favorited.
  static Future<void> remove(String productId) async {
    final existing = await favorites();
    final updated =
        existing.where((f) => f.productId != productId).toList();
    await _save(updated);
  }

  /// Whether [productId] is currently favorited.
  static Future<bool> isFavorite(String productId) async {
    final all = await favorites();
    return all.any((f) => f.productId == productId);
  }

  /// All favorites, newest-first.
  static Future<List<FavoriteProduct>> favorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return const [];

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } on FormatException {
      // Corrupt payload — treat as empty rather than crashing the list.
      return const [];
    }

    return decoded
        .map((e) => FavoriteProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Clears all persisted favorites.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _save(List<FavoriteProduct> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
