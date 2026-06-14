import 'allergen.dart';

/// How a contributor reported a single allergen for a pending product.
enum AllergenReportStatus {
  contains,
  mayContain,
  absent;

  /// The wire value stored in `pending_reviews.allergen_reports[].status`.
  String get wireValue => switch (this) {
        AllergenReportStatus.contains => 'contains',
        AllergenReportStatus.mayContain => 'may_contain',
        AllergenReportStatus.absent => 'absent',
      };

  /// Parses the Supabase wire value; unknown values fall back to [absent].
  static AllergenReportStatus fromWire(String? value) => switch (value) {
        'contains' => AllergenReportStatus.contains,
        'may_contain' => AllergenReportStatus.mayContain,
        _ => AllergenReportStatus.absent,
      };
}

/// One allergen line inside a [PendingReview].
class AllergenReport {
  final Allergen allergen;
  final AllergenReportStatus status;

  const AllergenReport({
    required this.allergen,
    required this.status,
  });
}

/// A community-contributed product awaiting moderator approval.
class PendingReview {
  final String id;
  final String productId;
  final String productName;
  final String brandName;
  final String categoryLabel;
  final String? imageUrl;
  final List<AllergenReport> allergenReports;
  final String? contributorNote;

  const PendingReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.categoryLabel,
    this.imageUrl,
    this.allergenReports = const [],
    this.contributorNote,
  });

  /// Builds a [PendingReview] from a `pending_reviews` row joined with its
  /// product/brand fields, resolving each `allergen_reports` entry against
  /// [allergensById]. Reports whose `allergen_id` is missing from the catalog
  /// are dropped (the allergen can't be rendered without its name/icon).
  factory PendingReview.fromJson(
    Map<String, dynamic> json, {
    required Map<String, Allergen> allergensById,
  }) {
    final product = json['products'] as Map<String, dynamic>?;
    final brand = product?['brands'] as Map<String, dynamic>?;

    final rawReports =
        (json['allergen_reports'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    final reports = <AllergenReport>[];
    for (final entry in rawReports) {
      final allergen = allergensById[entry['allergen_id'] as String?];
      if (allergen == null) continue;
      reports.add(AllergenReport(
        allergen: allergen,
        status: AllergenReportStatus.fromWire(entry['status'] as String?),
      ));
    }

    return PendingReview(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: product?['name_he'] as String? ?? 'מוצר ללא שם',
      brandName: brand?['name_he'] as String? ?? 'ללא מותג',
      categoryLabel: product?['category'] as String? ?? 'כללי',
      imageUrl: product?['image_url'] as String?,
      allergenReports: reports,
      contributorNote: json['contributor_note'] as String?,
    );
  }
}

/// Outcome of one of the reviewer's own past contributions.
enum ContributionOutcome { approved, pending, rejected }

/// A row in the reviewer's "תרומות אחרונות שלך" history strip.
class PastContribution {
  final String productId;
  final String productName;
  final String? imageUrl;
  final ContributionOutcome outcome;

  const PastContribution({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.outcome,
  });
}
