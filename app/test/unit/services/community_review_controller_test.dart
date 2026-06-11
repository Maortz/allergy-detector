import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/services/community_review_controller.dart';

void main() {
  const allergens = [
    Allergen(id: 'a1', nameHe: 'בוטנים', nameEn: 'Peanuts'),
    Allergen(id: 'a2', nameHe: 'חלב', nameEn: 'Dairy'),
  ];
  final allergensById = {for (final a in allergens) a.id: a};

  group('CommunityReviewController', () {
    test('service exists', () {
      expect(CommunityReviewController, isNotNull);
    });
  });

  group('AllergenReportStatus wire mapping', () {
    test('round-trips every status', () {
      for (final s in AllergenReportStatus.values) {
        expect(AllergenReportStatus.fromWire(s.wireValue), s);
      }
    });

    test('contains / may_contain map to the matching enum', () {
      expect(AllergenReportStatus.fromWire('contains'),
          AllergenReportStatus.contains);
      expect(AllergenReportStatus.fromWire('may_contain'),
          AllergenReportStatus.mayContain);
      expect(
          AllergenReportStatus.fromWire('absent'), AllergenReportStatus.absent);
    });

    test('unknown / null wire value falls back to absent', () {
      expect(
          AllergenReportStatus.fromWire('bogus'), AllergenReportStatus.absent);
      expect(AllergenReportStatus.fromWire(null), AllergenReportStatus.absent);
    });
  });

  group('PendingReview.fromJson', () {
    test('maps a full pending_reviews row joined with product + brand', () {
      final row = <String, dynamic>{
        'id': 'r1',
        'product_id': 'p1',
        'contributor_note': 'בדקתי את האריזה',
        'allergen_reports': [
          {'allergen_id': 'a1', 'status': 'contains'},
          {'allergen_id': 'a2', 'status': 'may_contain'},
        ],
        'products': {
          'name_he': 'חטיף בוטנים',
          'image_url': 'https://example.com/x.png',
          'brands': {'name_he': 'סניקרס'},
        },
      };

      final review =
          PendingReview.fromJson(row, allergensById: allergensById);

      expect(review.id, 'r1');
      expect(review.productId, 'p1');
      expect(review.productName, 'חטיף בוטנים');
      expect(review.brandName, 'סניקרס');
      expect(review.imageUrl, 'https://example.com/x.png');
      expect(review.contributorNote, 'בדקתי את האריזה');
      expect(review.allergenReports, hasLength(2));
      expect(review.allergenReports[0].allergen.id, 'a1');
      expect(review.allergenReports[0].status, AllergenReportStatus.contains);
      expect(review.allergenReports[1].status, AllergenReportStatus.mayContain);
    });

    test('drops reports whose allergen is not in the catalog', () {
      final row = <String, dynamic>{
        'id': 'r2',
        'product_id': 'p2',
        'allergen_reports': [
          {'allergen_id': 'a1', 'status': 'contains'},
          {'allergen_id': 'unknown', 'status': 'contains'},
        ],
        'products': {'name_he': 'מוצר', 'brands': null},
      };

      final review =
          PendingReview.fromJson(row, allergensById: allergensById);

      expect(review.allergenReports, hasLength(1));
      expect(review.allergenReports.single.allergen.id, 'a1');
    });

    test('falls back to placeholder copy when product / brand are missing', () {
      final row = <String, dynamic>{
        'id': 'r3',
        'product_id': 'p3',
        'allergen_reports': const <dynamic>[],
      };

      final review =
          PendingReview.fromJson(row, allergensById: allergensById);

      expect(review.productName, 'מוצר ללא שם');
      expect(review.brandName, 'ללא מותג');
      expect(review.categoryLabel, 'כללי');
      expect(review.imageUrl, isNull);
      expect(review.allergenReports, isEmpty);
    });
  });
}
