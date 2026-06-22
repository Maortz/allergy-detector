import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/services/community_review_controller.dart';
import 'package:app/services/auth_service.dart';

/// Captures every PostgREST request issued by the controller and returns a
/// canned response, so the tests assert on the real `.from().select()/.update()`
/// chain (table, columns, filters, body, HTTP verb) without a live Supabase.
class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient(
    this._bodyForRequest, {
    this.statusForRequest,
    this.headersForRequest,
  });

  /// Returns the JSON body string a request should resolve to.
  final String Function(http.BaseRequest request) _bodyForRequest;

  /// Optional per-request HTTP status override (defaults to 200). Lets a test
  /// simulate a server-side failure for a specific table/verb.
  final int Function(http.BaseRequest request)? statusForRequest;

  /// Optional per-request response-header override. Used to attach the
  /// `content-range` header PostgREST returns for `count=exact` queries (the
  /// count is parsed from `*/N`), which the client reads instead of the body.
  final Map<String, String> Function(http.BaseRequest request)?
      headersForRequest;

  final List<http.Request> requests = [];

  http.Request get lastRequest => requests.last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final typed = request as http.Request;
    requests.add(typed);
    final body = _bodyForRequest(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusForRequest?.call(request) ?? 200,
      request: request,
      headers: {
        'content-type': 'application/json',
        ...?headersForRequest?.call(request),
      },
    );
  }
}

/// Test double for [AuthService] that records each [ensureSession] call and
/// resolves without any network round-trip. Lets the controller's pre-flight
/// run in unit tests without firing a real anonymous sign-in against the
/// recording HTTP client (which would return an empty body and throw).
class _FakeAuthService extends AuthService {
  // AuthService's constructor takes one positional SupabaseClient (a private
  // field), so forward it explicitly with super(...) — `super.client` would not
  // compile because the parent param is the private `_client`.
  _FakeAuthService(super.client);

  int ensureSessionCalls = 0;

  /// When set, [ensureSession] throws this instead of resolving — used to prove
  /// a failed pre-flight aborts the privileged write.
  Object? throwOnEnsure;

  @override
  Future<User> ensureSession() async {
    ensureSessionCalls++;
    final error = throwOnEnsure;
    if (error != null) throw error;
    return User(
      id: 'fake-user',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      isAnonymous: true,
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

({CommunityReviewController controller, _FakeAuthService auth})
    _controllerWithFakeAuth(_RecordingHttpClient httpClient) {
  final client = SupabaseClient(
    'http://localhost',
    'anon-key',
    httpClient: httpClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final auth = _FakeAuthService(client);
  return (
    controller: CommunityReviewController.withAuth(client, auth),
    auth: auth,
  );
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
    test('runs the ensureSession pre-flight, then PATCHes the row to approved '
        'with cleared reason and a reviewed_at timestamp', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final (:controller, :auth) = _controllerWithFakeAuth(httpClient);

      await controller.approve('r-123', 'prod-x');

      // Pre-flight ran exactly once before the write.
      expect(auth.ensureSessionCalls, 1);

      final req = httpClient.requests
          .firstWhere((r) => r.url.path.endsWith('/rest/v1/pending_reviews'));
      expect(req.method, 'PATCH');
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

    test('also marks the linked product verified (#263)', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final (:controller, :auth) = _controllerWithFakeAuth(httpClient);

      await controller.approve('r-123', 'prod-9');

      final productReq = httpClient.requests
          .lastWhere((r) => r.url.path.endsWith('/rest/v1/products'));
      expect(productReq.method, 'PATCH');
      expect(productReq.url.queryParameters['id'], 'eq.prod-9');
      final body = jsonDecode(productReq.body) as Map<String, dynamic>;
      expect(body['verified'], true);
    });

    test('a failed pre-flight aborts the write — no PATCH is issued', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final (:controller, :auth) = _controllerWithFakeAuth(httpClient);
      auth.throwOnEnsure = StateError('offline');

      await expectLater(
        controller.approve('r-123', 'prod-x'),
        throwsA(isA<StateError>()),
      );

      expect(auth.ensureSessionCalls, 1);
      // ensureSession threw before any REST call — nothing was sent.
      expect(httpClient.requests, isEmpty);
    });

    test('rethrows when the products verify PATCH fails after the review row '
        'was already approved (#263 partial-state guard)', () async {
      // The pending_reviews PATCH succeeds; the products PATCH returns 500.
      final httpClient = _RecordingHttpClient(
        (_) => '',
        statusForRequest: (req) =>
            req.url.path.endsWith('/rest/v1/products') ? 500 : 200,
      );
      final (:controller, :auth) = _controllerWithFakeAuth(httpClient);

      await expectLater(
        controller.approve('r-123', 'prod-9'),
        throwsA(isA<PostgrestException>()),
      );

      // The review row was patched first (now stranded as approved) and the
      // products PATCH was attempted before the failure surfaced.
      expect(
        httpClient.requests.any(
            (r) => r.url.path.endsWith('/rest/v1/pending_reviews')),
        isTrue,
      );
      expect(
        httpClient.requests
            .any((r) => r.url.path.endsWith('/rest/v1/products')),
        isTrue,
      );
    });
  });

  group('CommunityReviewController.fetchStats (#263)', () {
    test('counts approved reviews and total products via exact-count HEAD '
        'requests (no row fetch, so the 1000-row default ceiling never '
        'undercounts)', () async {
      // PostgREST exact-count returns the total in the `content-range` header
      // (`*/N`) with an empty body, fetched via HEAD — not by pulling rows.
      final httpClient = _RecordingHttpClient(
        (_) => '',
        headersForRequest: (req) {
          final path = req.url.path;
          if (path.endsWith('/rest/v1/pending_reviews')) {
            return {'content-range': '*/3'};
          }
          if (path.endsWith('/rest/v1/products')) {
            return {'content-range': '*/2'};
          }
          return const {};
        },
      );
      final controller = _controllerReturning(httpClient);

      final stats = await controller.fetchStats();

      expect(stats.verified, 3);
      expect(stats.added, 2);

      final reviewReq = httpClient.requests
          .firstWhere((r) => r.url.path.endsWith('/rest/v1/pending_reviews'));
      expect(reviewReq.method, 'HEAD');
      expect(reviewReq.headers['Prefer'], contains('count=exact'));
      expect(reviewReq.url.queryParameters['status'], 'eq.approved');

      final productReq = httpClient.requests
          .firstWhere((r) => r.url.path.endsWith('/rest/v1/products'));
      expect(productReq.method, 'HEAD');
      expect(productReq.headers['Prefer'], contains('count=exact'));
    });
  });

  group('CommunityReviewController.reject', () {
    test('runs the ensureSession pre-flight, then PATCHes the row to rejected '
        'with the supplied reason and a reviewed_at timestamp', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final (:controller, :auth) = _controllerWithFakeAuth(httpClient);

      await controller.reject('r-456', 'חסר מידע על אלרגנים');

      expect(auth.ensureSessionCalls, 1);

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

    test('a failed pre-flight aborts the write — no PATCH is issued', () async {
      final httpClient = _RecordingHttpClient((_) => '');
      final (:controller, :auth) = _controllerWithFakeAuth(httpClient);
      auth.throwOnEnsure = StateError('offline');

      await expectLater(
        controller.reject('r-456', 'חסר מידע'),
        throwsA(isA<StateError>()),
      );

      expect(auth.ensureSessionCalls, 1);
      // ensureSession threw before any REST call — nothing was sent.
      expect(httpClient.requests, isEmpty);
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
