/// The moderation outcome of one of the user's own `pending_reviews` rows.
///
/// Mirrors the `pending_review_status` Postgres enum
/// (`supabase/schema.sql`): `pending` | `approved` | `rejected`.
enum ContributionStatus {
  pending,
  approved,
  rejected;

  /// Parses the Supabase wire value; an unknown value falls back to [pending]
  /// (a row that exists but whose status we can't read is, at worst, still
  /// awaiting a decision).
  static ContributionStatus fromWire(String? value) => switch (value) {
        'approved' => ContributionStatus.approved,
        'rejected' => ContributionStatus.rejected,
        _ => ContributionStatus.pending,
      };

  /// Hebrew label for the status pill.
  String get labelHe => switch (this) {
        ContributionStatus.pending => 'ממתין לאישור',
        ContributionStatus.approved => 'אושר',
        ContributionStatus.rejected => 'נדחה',
      };
}

/// Hebrew relative-time label for [timestamp] relative to [now]
/// (defaults to `DateTime.now()`). RTL-first copy, e.g. "לפני שעתיים".
///
/// Shared by the user's reviews / contributions cards so both render dates the
/// same way `ScanHistoryEntry` does.
String relativeTimeHe(DateTime timestamp, [DateTime? now]) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(timestamp);

  if (diff.isNegative) return 'זה עתה';
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
  if (w < 5) return 'לפני $w שבועות';
  final mo = d ~/ 30;
  if (mo <= 1) return 'לפני חודש';
  if (mo == 2) return 'לפני חודשיים';
  if (mo < 12) return 'לפני $mo חודשים';
  final y = d ~/ 365;
  return y == 1 ? 'לפני שנה' : 'לפני $y שנים';
}

/// One of the current user's community reviews — a `pending_reviews` row they
/// submitted, hydrated with the product/brand it targets.
///
/// Backs `MyReviewsScreen`; carries the reviewer's free-text note and the
/// moderation [status] so the card can render text + status + date.
class MyReview {
  final String id;
  final String productName;
  final String? brandName;
  final String? imageUrl;
  final String? note;
  final ContributionStatus status;
  final DateTime submittedAt;

  const MyReview({
    required this.id,
    required this.productName,
    this.brandName,
    this.imageUrl,
    this.note,
    required this.status,
    required this.submittedAt,
  });

  /// Builds a [MyReview] from a `pending_reviews` row joined with its
  /// `products(name_he, image_url, brands(name_he))`.
  factory MyReview.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final brand = product?['brands'] as Map<String, dynamic>?;
    return MyReview(
      id: json['id'] as String,
      productName: product?['name_he'] as String? ?? 'מוצר ללא שם',
      brandName: brand?['name_he'] as String?,
      imageUrl: product?['image_url'] as String?,
      note: (json['contributor_note'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['contributor_note'] as String).trim(),
      status: ContributionStatus.fromWire(json['status'] as String?),
      submittedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// One product the current user submitted to the community — a `pending_reviews`
/// row, surfaced as a contribution to the catalog.
///
/// Backs `ContributionHistoryScreen`; carries product name + brand + status +
/// date (no free-text note — that's the "review" view's concern).
class ProductContribution {
  final String id;
  final String productName;
  final String? brandName;
  final String? imageUrl;
  final ContributionStatus status;
  final DateTime submittedAt;

  const ProductContribution({
    required this.id,
    required this.productName,
    this.brandName,
    this.imageUrl,
    required this.status,
    required this.submittedAt,
  });

  /// Builds a [ProductContribution] from a `pending_reviews` row joined with its
  /// `products(name_he, image_url, brands(name_he))`.
  factory ProductContribution.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final brand = product?['brands'] as Map<String, dynamic>?;
    return ProductContribution(
      id: json['id'] as String,
      productName: product?['name_he'] as String? ?? 'מוצר ללא שם',
      brandName: brand?['name_he'] as String?,
      imageUrl: product?['image_url'] as String?,
      status: ContributionStatus.fromWire(json['status'] as String?),
      submittedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
