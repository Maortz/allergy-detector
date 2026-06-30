import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';

/// Thrown by [AllergenService.fetchAllergens] when every retry attempt to load
/// the allergen catalog fails. Preserves the last underlying error's string so
/// callers that sniff for network markers (e.g. AppShell's socket/connection
/// check) keep working.
class AllergenLoadException implements Exception {
  const AllergenLoadException(this.cause);

  final Object? cause;

  @override
  String toString() => 'AllergenLoadException: $cause';
}

class AllergenService {
  final SupabaseClient _client;

  AllergenService(this._client);

  /// Per-attempt network timeout. More generous than the original 10s so a slow
  /// Android cold-start TLS handshake does not trip it on the first try
  /// (issue #336).
  static const Duration perAttemptTimeout = Duration(seconds: 15);

  /// Total attempts (1 initial + retries) before giving up.
  static const int maxAttempts = 3;

  /// Base linear backoff between attempts (attempt N waits base * N).
  static const Duration retryBackoff = Duration(milliseconds: 400);

  Future<List<Allergen>> fetchAllergens() {
    return fetchWithRetry(
      () => _client.from('allergens').select().timeout(perAttemptTimeout),
    );
  }

  /// Pure, injectable retry+parse policy. [query] performs one network read;
  /// its result is parsed into [Allergen]s. Retries up to [maxAttempts] on any
  /// error (timeout, transient network), waiting [backoff] * attempt between
  /// tries. Throws [AllergenLoadException] wrapping the last error when all
  /// attempts fail. Extracted as a static so it is testable without a live
  /// Supabase client.
  @visibleForTesting
  static Future<List<Allergen>> fetchWithRetry(
    Future<dynamic> Function() query, {
    int maxAttempts = AllergenService.maxAttempts,
    Duration backoff = AllergenService.retryBackoff,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await query();
        return (response as List)
            .map((json) => Allergen.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(backoff * attempt);
        }
      }
    }
    throw AllergenLoadException(lastError);
  }
}
