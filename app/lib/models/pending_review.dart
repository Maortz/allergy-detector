import 'allergen.dart';

/// How a contributor reported a single allergen for a pending product.
enum AllergenReportStatus { contains, mayContain, absent }

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
