import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/pending_review.dart';
import 'package:app/services/community_review_controller.dart';
import 'package:app/services/review_queue_service.dart';
import 'package:app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Minimal stubs ────────────────────────────────────────────────────────────

/// Records approve / reject calls so tests can assert the controller was invoked.
/// Does NOT hit Supabase — responds with a canned 200 to every HTTP call.
class _RecordingHttpClient extends http.BaseClient {
  final List<String> _approveCalls = [];
  final List<String> _rejectCalls = [];

  List<String> get approveCalls => List.unmodifiable(_approveCalls);
  List<String> get rejectCalls => List.unmodifiable(_rejectCalls);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Detect approve vs reject from the PATCH body.
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final status = body['status'] as String?;
        if (status == 'approved') {
          final id = request.url.queryParameters['id'];
          if (id != null) _approveCalls.add(id.replaceAll('eq.', ''));
        } else if (status == 'rejected') {
          final id = request.url.queryParameters['id'];
          if (id != null) _rejectCalls.add(id.replaceAll('eq.', ''));
        }
      } catch (_) {}
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode('[]')),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(super.client);

  @override
  Future<User> ensureSession() async {
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _allergens = <Allergen>[
  Allergen(id: 'a1', nameHe: 'גלוטן'),
  Allergen(id: 'a2', nameHe: 'חלב'),
];

PendingReview _review(String id) => PendingReview(
      id: id,
      productId: 'p-$id',
      productName: 'מוצר $id',
      brandName: 'מותג',
      categoryLabel: 'כללי',
    );

/// Builds a [CommunityReviewController] backed by a Supabase client that uses
/// [_RecordingHttpClient]. Returns the controller and the recording client.
(CommunityReviewController, _RecordingHttpClient) _makeController() {
  final recording = _RecordingHttpClient();
  // Build a SupabaseClient that routes HTTP through our recording client.
  final client = SupabaseClient(
    'https://fake.supabase.co',
    'fake-anon-key',
    httpClient: recording,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final auth = _FakeAuthService(client);
  return (CommunityReviewController.withAuth(client, auth), recording);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ReviewQueueService', () {
    // ── Queue state ──────────────────────────────────────────────────────────
    test('withQueue: currentItem returns first item', () {
      final (controller, _) = _makeController();
      final queue = [_review('r1'), _review('r2')];
      final service = ReviewQueueService.withQueue(controller, _allergens, queue);

      expect(service.currentItem?.id, 'r1');
      expect(service.remaining, 2);
    });

    test('withQueue: empty queue → currentItem is null', () {
      final (controller, _) = _makeController();
      final service =
          ReviewQueueService.withQueue(controller, _allergens, const []);

      expect(service.currentItem, isNull);
      expect(service.remaining, 0);
    });

    // ── Approve path ─────────────────────────────────────────────────────────
    test('approve: advances cursor, returns true while items remain', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1'), _review('r2')]);

      final moreRemain = await service.approve(_review('r1'));

      expect(moreRemain, isTrue);
      expect(service.currentItem?.id, 'r2');
      expect(service.remaining, 1);
    });

    test('approve: returns false when last item is reviewed', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1')]);

      final moreRemain = await service.approve(_review('r1'));

      expect(moreRemain, isFalse);
      expect(service.currentItem, isNull);
      expect(service.remaining, 0);
    });

    // ── Reject path ───────────────────────────────────────────────────────────
    test('reject: advances cursor, returns true while items remain', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1'), _review('r2')]);

      final moreRemain = await service.reject(_review('r1'), 'מידע שגוי');

      expect(moreRemain, isTrue);
      expect(service.currentItem?.id, 'r2');
    });

    test('reject: returns false when last item is reviewed', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1')]);

      final moreRemain = await service.reject(_review('r1'), 'נסיון');

      expect(moreRemain, isFalse);
      expect(service.currentItem, isNull);
    });

    // ── Session accumulators ──────────────────────────────────────────────────
    test('approve: increments sessionReviewed and sessionPoints', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1'), _review('r2'), _review('r3')]);

      expect(service.sessionReviewed, 0);
      expect(service.sessionPoints, 0);

      await service.approve(_review('r1'));
      expect(service.sessionReviewed, 1);
      expect(service.sessionPoints, 10); // _pointsPerReview = 10

      await service.approve(_review('r2'));
      expect(service.sessionReviewed, 2);
      expect(service.sessionPoints, 20);
    });

    test('reject: increments sessionReviewed and sessionPoints', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1')]);

      await service.reject(_review('r1'), 'סיבה');

      expect(service.sessionReviewed, 1);
      expect(service.sessionPoints, 10);
    });

    test('mixed approve+reject: accumulators sum correctly', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(controller, _allergens, [
        _review('r1'),
        _review('r2'),
        _review('r3'),
      ]);

      await service.approve(_review('r1'));
      await service.reject(_review('r2'), 'סיבה');

      expect(service.sessionReviewed, 2);
      expect(service.sessionPoints, 20);
    });

    // ── skip path ─────────────────────────────────────────────────────────────
    test('skip: advances cursor without recording a review', () {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1'), _review('r2')]);

      final moreRemain = service.skip();

      expect(moreRemain, isTrue);
      expect(service.currentItem?.id, 'r2');
      expect(service.remaining, 1);
      // Skip must NOT credit points or count the item as reviewed.
      expect(service.sessionReviewed, 0);
      expect(service.sessionPoints, 0);
    });

    test('skip: returns false when last item is skipped', () {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(
          controller, _allergens, [_review('r1')]);

      final moreRemain = service.skip();

      expect(moreRemain, isFalse);
      expect(service.currentItem, isNull);
      expect(service.sessionReviewed, 0);
      expect(service.sessionPoints, 0);
    });

    // ── remaining ─────────────────────────────────────────────────────────────
    test('remaining decrements with each advance', () async {
      final (controller, _) = _makeController();
      final service = ReviewQueueService.withQueue(controller, _allergens, [
        _review('r1'),
        _review('r2'),
        _review('r3'),
      ]);

      expect(service.remaining, 3);
      await service.approve(_review('r1'));
      expect(service.remaining, 2);
      await service.approve(_review('r2'));
      expect(service.remaining, 1);
      await service.approve(_review('r3'));
      expect(service.remaining, 0);
    });
  });
}
