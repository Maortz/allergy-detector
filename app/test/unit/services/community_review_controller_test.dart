import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/services/community_review_controller.dart';

/// Captures every PostgREST request issued by the controller and returns a
/// canned response, so the tests assert on the real `.from().select()/.update()`
/// chain (table, columns, filters, body, HTTP verb) without a live Supabase.
class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient(this._bodyForRequest);

  /// Returns the JSON body string a request should resolve to.
  final String Function(http.BaseRequest request) _bodyForRequest;

  final List<http.Request> requests = [];

  http.Request get lastRequest => requests.last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final typed = request as http.Request;
    requests.add(typed);
    final body = _bodyForRequest(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}

CommunityReviewController _controllerReturning(
  _RecordingHttpClient httpClient,
) {
  final client = SupabaseClient(
    'http://localhost',
    'anon-key',
    httpClient: httpClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  return CommunityReviewController(client);
}

void main() {
  const allergens = [
    Allergen(id: 'a1', nameHe: 'בוטנים', nameEn: 'Peanuts'),
    Allergen(id: 'a2', nameHe: 'חלב', nameEn: 'Dairy'),
  ];
  final allergensById = {for (final a in allergens) a.id: a};

  group('CommunityReviewController.fetchPending', () {
    test('selects from pending_reviews filtered to status=pending, oldest-first,'
        ' and hydrates rows', () async {
      final httpClient = _RecordingHttpClient((_) => jsonEncode([
            {
              'id': 'r1',
              'product_id': 'p1',
              'contributor_note': null,
              'allergen_reports': [
                {'allergen_id': 'a1', 'status': 'contains'},
              ],
              'products': {
                'name_he': 'חטיף בוטנים',
                'image_url': null,
                'brands': {'name_he': 'אסם'},
              },
            },
          ]));
      final controller = _controllerReturning(httpClient);

      final result = await controller.fetchPending(allergens);

      final uri = httpClient.lastRequest.url;
      expect(httpClient.lastRequest.method, 'GET');
      expect(uri.path, endsWith('/rest/v1/pending_reviews'));
      expect(uri.queryParameters['status'], 'eq.pending');
      expect(uri.queryParameters['order'], startsWith('created_at.asc'));
      // The nested select must pull the product + brand columns the model reads.
      final select = uri.queryParameters['select'];
      expect(select, contains('allergen_reports'));
      expect(select, contains('products('));
      expect(select, contains('category'));
      expect(select, contains('brands('));

      expect(result, hasLength(1));
      expect(result.single.productName, 'חטיף בוטנים');
      expect(result.single.brandName, 'אסם');
      expect(result.single.allergenReports.single.allergen.id, 'a1');
    });
  });

  group('CommunityReviewController.approve', () {
    test('PATCHes pending_reviews row to approved with cleared reason and a '
        'reviewed_at timestamp', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final controller = _controllerReturning(httpClient);

      await controller.approve('r-123');

      final req = httpClient.lastRequest;
      expect(req.method, 'PATCH');
      expect(req.url.path, endsWith('/rest/v1/pending_reviews'));
      expect(req.url.queryParameters['id'], 'eq.r-123');

      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['status'], 'approved');
      expect(body['rejection_reason'], isNull);
      expect(body['reviewed_at'], isNotNull);
      expect(
        DateTime.parse(body['reviewed_at'] as String).isUtc,
        isTrue,
      );
    });
  });

  group('CommunityReviewController.reject', () {
    test('PATCHes pending_reviews row to rejected with the supplied reason and '
        'a reviewed_at timestamp', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final controller = _controllerReturning(httpClient);

      await controller.reject('r-456', 'חסר מידע על אלרגנים');

      final req = httpClient.lastRequest;
      expect(req.method, 'PATCH');
      expect(req.url.path, endsWith('/rest/v1/pending_reviews'));
      expect(req.url.queryParameters['id'], 'eq.r-456');

      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['status'], 'rejected');
      expect(body['rejection_reason'], 'חסר מידע על אלרגנים');
      expect(body['reviewed_at'], isNotNull);
      expect(
        DateTime.parse(body['reviewed_at'] as String).isUtc,
        isTrue,
      );
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
          'category': 'חטיפים',
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
      expect(review.categoryLabel, 'חטיפים');
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
