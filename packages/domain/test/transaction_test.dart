import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Transaction', () {
    test('has the sum of its items as total', () {
      final shopping = on(DateTime(2026, 11, 6), [
        mine(-1200, category: 'alcohol'),
        mine(-180, category: 'food'),
      ]);

      expect(shopping.total, eur(-1380));
    });

    test('rejects a transaction without items', () {
      expect(() => on(DateTime(2026, 11, 6), []), throwsArgumentError);
    });

    test('rejects items of different currencies', () {
      final dollars = Item.mine(
        id: const ItemId('dollars'),
        name: 'Dollars',
        categoryId: const CategoryId('food'),
        price: const Money(-100, Currency.usd),
      );

      expect(
        () => on(DateTime(2026, 11, 6), [mine(-100), dollars]),
        throwsA(isA<CurrencyMismatch>()),
      );
    });
  });
}
