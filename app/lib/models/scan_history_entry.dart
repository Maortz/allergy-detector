import 'allergen.dart';

/// A persisted record of a product the user resolved via scan/search.
///
/// Unlike the presentation-only [RecentScan] / `RecentActivity` view models
/// (which carry a pre-formatted Hebrew `time` string), this is the durable
/// shape persisted by `ScanHistoryService`: it keeps the product identity and
/// a real [scannedAt] timestamp so the relative-time label can be recomputed
/// on every read.
class ScanHistoryEntry {
  final String productId;
  final String nameHe;
  final String? brandNameHe;
  final String? imageUrl;
  final AllergenStatus status;
  final DateTime scannedAt;

  const ScanHistoryEntry({
    required this.productId,
    required this.nameHe,
    this.brandNameHe,
    this.imageUrl,
    required this.status,
    required this.scannedAt,
  });

  /// Hebrew relative-time label for [scannedAt] relative to [now]
  /// (defaults to `DateTime.now()`). RTL-first copy, e.g. "לפני שעתיים".
  String relativeTime([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(scannedAt);

    if (diff.inMinutes < 1) return 'זה עתה';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? 'לפני דקה' : 'לפני $m דקות';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      if (h == 1) return 'לפני שעה';
      if (h == 2) return 'לפני שעתיים';
      return 'לפני $h שעות';
    }
    final d = diff.inDays;
    if (d == 1) return 'אתמול';
    if (d == 2) return 'שלשום';
    if (d < 7) return 'לפני $d ימים';
    final w = d ~/ 7;
    if (w == 1) return 'לפני שבוע';
    if (w == 2) return 'לפני שבועיים';
    return 'לפני $w שבועות';
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name_he': nameHe,
        'brand_name_he': brandNameHe,
        'image_url': imageUrl,
        'status': status.name,
        'scanned_at': scannedAt.toUtc().toIso8601String(),
      };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        productId: json['product_id'] as String,
        nameHe: json['name_he'] as String,
        brandNameHe: json['brand_name_he'] as String?,
        imageUrl: json['image_url'] as String?,
        status: AllergenStatus.values.firstWhere(
          (s) => s.name == json['status'],
          // Fail-safe: an unrecognised persisted status resolves to the
          // strongest warning rather than silently appearing "safe".
          orElse: () => AllergenStatus.avoid,
        ),
        scannedAt: DateTime.parse(json['scanned_at'] as String),
      );
}
