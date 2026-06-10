import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/models/allergen.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/services/scan_history_service.dart';

Product _product(
  String id, {
  String? name,
  List<ProductAllergen> allergens = const [],
}) =>
    Product(
      id: id,
      nameHe: name ?? 'מוצר $id',
      brandNameHe: 'מותג $id',
      allergens: allergens,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const emptyProfile = UserProfile();

  group('ScanHistoryService', () {
    test('starts empty', () async {
      expect(await ScanHistoryService.recentScans(), isEmpty);
    });

    test('records a scan and reads it back', () async {
      await ScanHistoryService.record(_product('a', name: 'חלב'), emptyProfile);

      final history = await ScanHistoryService.recentScans();
      expect(history, hasLength(1));
      expect(history.single.productId, 'a');
      expect(history.single.nameHe, 'חלב');
      expect(history.single.brandNameHe, 'מותג a');
    });

    test('newest-first ordering', () async {
      final base = DateTime.utc(2026, 1, 1, 12);
      await ScanHistoryService.record(_product('a'), emptyProfile, now: base);
      await ScanHistoryService.record(
        _product('b'),
        emptyProfile,
        now: base.add(const Duration(minutes: 1)),
      );
      await ScanHistoryService.record(
        _product('c'),
        emptyProfile,
        now: base.add(const Duration(minutes: 2)),
      );

      final ids =
          (await ScanHistoryService.recentScans()).map((e) => e.productId);
      expect(ids, ['c', 'b', 'a']);
    });

    test('re-recording a product moves it to the front (dedup, no dupes)',
        () async {
      await ScanHistoryService.record(_product('a'), emptyProfile);
      await ScanHistoryService.record(_product('b'), emptyProfile);
      await ScanHistoryService.record(_product('a'), emptyProfile);

      final history = await ScanHistoryService.recentScans();
      expect(history.map((e) => e.productId), ['a', 'b']);
    });

    test('caps at maxEntries, dropping the oldest', () async {
      final base = DateTime.utc(2026, 1, 1);
      for (var i = 0; i < ScanHistoryService.maxEntries + 5; i++) {
        await ScanHistoryService.record(
          _product('p$i'),
          emptyProfile,
          now: base.add(Duration(minutes: i)),
        );
      }

      final history = await ScanHistoryService.recentScans();
      expect(history, hasLength(ScanHistoryService.maxEntries));
      // Newest survives, oldest (p0) is dropped.
      expect(history.first.productId, 'p${ScanHistoryService.maxEntries + 4}');
      expect(history.map((e) => e.productId), isNot(contains('p0')));
    });

    test('limit caps the returned count', () async {
      for (var i = 0; i < 5; i++) {
        await ScanHistoryService.record(_product('p$i'), emptyProfile);
      }
      expect(await ScanHistoryService.recentScans(limit: 3), hasLength(3));
    });

    test('stores the status computed against the profile', () async {
      final milkAllergen = ProductAllergen(
        allergenId: 'milk',
        allergenNameHe: 'חלב',
        severity: 'contains',
      );
      final profile =
          const UserProfile().copyWith(selectedAllergenIds: {'milk'});

      await ScanHistoryService.record(
        _product('a', allergens: [milkAllergen]),
        profile,
      );

      final entry = (await ScanHistoryService.recentScans()).single;
      expect(entry.status, AllergenStatus.avoid);
    });

    test('clear empties the history', () async {
      await ScanHistoryService.record(_product('a'), emptyProfile);
      await ScanHistoryService.clear();
      expect(await ScanHistoryService.recentScans(), isEmpty);
    });
  });

  group('ScanHistoryEntry.relativeTime', () {
    test('Hebrew relative labels', () async {
      final base = DateTime.utc(2026, 1, 10, 12);
      await ScanHistoryService.record(
        _product('a'),
        emptyProfile,
        now: base.subtract(const Duration(hours: 2)),
      );
      final entry = (await ScanHistoryService.recentScans()).single;
      expect(entry.relativeTime(base), 'לפני שעתיים');
      expect(
        entry.relativeTime(base.subtract(const Duration(hours: 2)))
            .contains('עתה'),
        isTrue,
      );
    });
  });
}
