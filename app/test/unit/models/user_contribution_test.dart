import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_contribution.dart';

void main() {
  group('ContributionStatus.fromWire', () {
    test('maps known wire values', () {
      expect(ContributionStatus.fromWire('approved'),
          ContributionStatus.approved);
      expect(ContributionStatus.fromWire('rejected'),
          ContributionStatus.rejected);
      expect(
          ContributionStatus.fromWire('pending'), ContributionStatus.pending);
    });

    test('falls back to pending for unknown / null', () {
      expect(ContributionStatus.fromWire(null), ContributionStatus.pending);
      expect(ContributionStatus.fromWire('???'), ContributionStatus.pending);
    });
  });

  group('MyReview.fromJson', () {
    test('hydrates product, brand, note, status and date', () {
      final review = MyReview.fromJson({
        'id': 'r1',
        'contributor_note': '  המידע נכון  ',
        'status': 'approved',
        'created_at': '2026-06-14T09:00:00Z',
        'products': {
          'name_he': 'יוגורט סויה',
          'image_url': 'http://x/i.png',
          'brands': {'name_he': 'טבעי'},
        },
      });

      expect(review.id, 'r1');
      expect(review.productName, 'יוגורט סויה');
      expect(review.brandName, 'טבעי');
      expect(review.imageUrl, 'http://x/i.png');
      expect(review.note, 'המידע נכון');
      expect(review.status, ContributionStatus.approved);
      expect(review.submittedAt.toUtc(), DateTime.utc(2026, 6, 14, 9));
    });

    test('treats a blank note as null and a missing product as a fallback', () {
      final review = MyReview.fromJson({
        'id': 'r2',
        'contributor_note': '   ',
        'status': 'pending',
        'created_at': '2026-06-14T09:00:00Z',
        'products': null,
      });

      expect(review.note, isNull);
      expect(review.productName, 'מוצר ללא שם');
      expect(review.brandName, isNull);
    });
  });

  group('ProductContribution.fromJson', () {
    test('hydrates product, brand, status and date', () {
      final c = ProductContribution.fromJson({
        'id': 'c1',
        'status': 'rejected',
        'created_at': '2026-06-14T09:00:00Z',
        'products': {
          'name_he': 'לחם',
          'brands': {'name_he': 'מאפיה'},
        },
      });

      expect(c.id, 'c1');
      expect(c.productName, 'לחם');
      expect(c.brandName, 'מאפיה');
      expect(c.status, ContributionStatus.rejected);
    });
  });

  group('relativeTimeHe', () {
    final now = DateTime(2026, 6, 14, 12);

    test('renders Hebrew relative labels', () {
      expect(relativeTimeHe(now, now), 'זה עתה');
      expect(relativeTimeHe(now.subtract(const Duration(minutes: 1)), now),
          'לפני דקה');
      expect(relativeTimeHe(now.subtract(const Duration(hours: 2)), now),
          'לפני שעתיים');
      expect(relativeTimeHe(now.subtract(const Duration(days: 1)), now),
          'אתמול');
      expect(relativeTimeHe(now.subtract(const Duration(days: 14)), now),
          'לפני שבועיים');
    });

    test('future timestamps clamp to "זה עתה"', () {
      expect(relativeTimeHe(now.add(const Duration(hours: 1)), now), 'זה עתה');
    });
  });
}
