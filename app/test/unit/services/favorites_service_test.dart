import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/models/product.dart';
import 'package:app/services/favorites_service.dart';

Product _product(String id, {String? name}) =>
    Product(id: id, nameHe: name ?? 'מוצר $id', brandNameHe: 'מותג $id');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('FavoritesService', () {
    test('starts empty', () async {
      expect(await FavoritesService.favorites(), isEmpty);
      expect(await FavoritesService.isFavorite('a'), isFalse);
    });

    test('add then read back', () async {
      await FavoritesService.add(_product('a', name: 'חלב'));

      final all = await FavoritesService.favorites();
      expect(all, hasLength(1));
      expect(all.single.productId, 'a');
      expect(all.single.nameHe, 'חלב');
      expect(all.single.brandNameHe, 'מותג a');
      expect(await FavoritesService.isFavorite('a'), isTrue);
    });

    test('newest-first ordering', () async {
      final base = DateTime.utc(2026, 1, 1, 12);
      await FavoritesService.add(_product('a'), now: base);
      await FavoritesService.add(
        _product('b'),
        now: base.add(const Duration(minutes: 1)),
      );

      final ids = (await FavoritesService.favorites()).map((f) => f.productId);
      expect(ids, ['b', 'a']);
    });

    test('re-adding moves to front without duplicating', () async {
      await FavoritesService.add(_product('a'));
      await FavoritesService.add(_product('b'));
      await FavoritesService.add(_product('a'));

      final ids = (await FavoritesService.favorites()).map((f) => f.productId);
      expect(ids, ['a', 'b']);
    });

    test('remove deletes the matching favorite', () async {
      await FavoritesService.add(_product('a'));
      await FavoritesService.add(_product('b'));

      await FavoritesService.remove('a');

      final ids = (await FavoritesService.favorites()).map((f) => f.productId);
      expect(ids, ['b']);
      expect(await FavoritesService.isFavorite('a'), isFalse);
    });

    test('remove is a no-op for an unfavorited product', () async {
      await FavoritesService.add(_product('a'));
      await FavoritesService.remove('zzz');
      expect(await FavoritesService.favorites(), hasLength(1));
    });

    test('clear empties favorites', () async {
      await FavoritesService.add(_product('a'));
      await FavoritesService.clear();
      expect(await FavoritesService.favorites(), isEmpty);
    });
  });
}
