import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/services/allergen_service.dart';

void main() {
  group('AllergenService', () {
    test('Allergen model correctly parses from JSON', () {
      final json = {'id': '1', 'name_he': 'גלוטן', 'name_en': 'Gluten'};
      final allergen = Allergen.fromJson(json);

      expect(allergen.id, '1');
      expect(allergen.nameHe, 'גלוטן');
      expect(allergen.nameEn, 'Gluten');
    });

    test('allergens list can be mapped from response data', () {
      final data = [
        {'id': '1', 'name_he': 'גלוטן', 'name_en': 'Gluten'},
        {'id': '2', 'name_he': 'חלב', 'name_en': 'Milk'},
      ];

      final allergens = data
          .map((json) => Allergen.fromJson(json))
          .toList();

      expect(allergens.length, 2);
      expect(allergens[0].nameHe, 'גלוטן');
      expect(allergens[1].nameHe, 'חלב');
    });
  });

  group('AllergenService.fetchWithRetry', () {
    final sample = [
      {'id': '1', 'name_he': 'גלוטן', 'name_en': 'Gluten'},
      {'id': '2', 'name_he': 'חלב', 'name_en': 'Milk'},
    ];

    test('parses allergens and queries once on first-try success', () async {
      var calls = 0;
      final result = await AllergenService.fetchWithRetry(
        () async {
          calls++;
          return sample;
        },
        backoff: Duration.zero,
      );

      expect(calls, 1);
      expect(result.map((a) => a.nameHe).toList(), ['גלוטן', 'חלב']);
    });

    test('retries and succeeds after two transient failures', () async {
      var calls = 0;
      final result = await AllergenService.fetchWithRetry(
        () async {
          calls++;
          if (calls < 3) throw const SocketishError();
          return sample;
        },
        backoff: Duration.zero,
      );

      expect(calls, 3);
      expect(result.length, 2);
    });

    test('a TimeoutException is retryable like any other error', () async {
      var calls = 0;
      final result = await AllergenService.fetchWithRetry(
        () async {
          calls++;
          if (calls < 2) throw TimeoutException('slow', Duration.zero);
          return sample;
        },
        backoff: Duration.zero,
      );

      expect(calls, 2);
      expect(result.length, 2);
    });

    test('throws AllergenLoadException after exhausting attempts, '
        'preserving the last error', () async {
      var calls = 0;
      Object? thrown;
      try {
        await AllergenService.fetchWithRetry(
          () async {
            calls++;
            throw TimeoutException('attempt $calls');
          },
          backoff: Duration.zero,
        );
      } catch (e) {
        thrown = e;
      }

      expect(calls, AllergenService.maxAttempts);
      expect(thrown, isA<AllergenLoadException>());
      final cause = (thrown as AllergenLoadException).cause;
      expect(cause, isA<TimeoutException>());
      expect(
        (cause as TimeoutException).message,
        'attempt ${AllergenService.maxAttempts}',
      );
    });
  });
}

/// Stand-in transient error for the retry test (no real sockets in unit tests).
class SocketishError implements Exception {
  const SocketishError();
}
