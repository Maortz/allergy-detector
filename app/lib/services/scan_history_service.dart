import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/scan_history_entry.dart';
import '../models/user_profile.dart';

/// Persists the user's recently-resolved products (scan or search → product
/// details) locally, mirroring the SharedPreferences-backed pattern of
/// `SearchCache`.
///
/// Storage is a single JSON array under [_storageKey], newest-first, capped at
/// [maxEntries]. Re-resolving a product already in history moves it to the
/// front (dedup by `productId`) rather than appending a duplicate, so the list
/// reflects distinct recent products in recency order.
///
/// MVP is local-only — no Supabase-backed history (issue #77 out of scope).
class ScanHistoryService {
  static const _storageKey = 'scan_history';

  /// Hard cap on persisted entries. Older entries beyond this are dropped on
  /// write so the list (and the SharedPreferences string) stay bounded.
  static const maxEntries = 50;

  /// Records that [product] was resolved, computed against [profile] so the
  /// stored [AllergenStatus] matches what the user saw. Moves an existing
  /// entry for the same product to the front and trims to [maxEntries].
  ///
  /// [now] is injectable for deterministic tests; defaults to `DateTime.now()`.
  static Future<void> record(
    Product product,
    UserProfile profile, {
    DateTime? now,
  }) async {
    final entry = ScanHistoryEntry(
      productId: product.id,
      nameHe: product.nameHe,
      brandNameHe: product.brandNameHe,
      imageUrl: product.imageUrl,
      status: profile.statusFor(product),
      scannedAt: now ?? DateTime.now(),
    );

    final existing = await recentScans();
    final deduped = existing.where((e) => e.productId != entry.productId);
    final updated = [entry, ...deduped].take(maxEntries).toList();
    await _save(updated);
  }

  /// Recent scans, newest-first. Pass [limit] to cap the returned count
  /// (e.g. the home feed shows only the few most recent); omit it for the
  /// full history (e.g. ScanHistoryScreen).
  static Future<List<ScanHistoryEntry>> recentScans({int? limit}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return const [];

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } on FormatException {
      // Corrupt payload — treat as empty rather than crashing the home feed.
      return const [];
    }

    final entries = decoded
        .map((e) => ScanHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    if (limit != null && entries.length > limit) {
      return entries.sublist(0, limit);
    }
    return entries;
  }

  /// Clears all persisted scan history.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _save(List<ScanHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
