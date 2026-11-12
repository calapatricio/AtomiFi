import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Money', () {
    test('adds, subtracts and negates amounts of one currency', () {
      expect(eur(250) + eur(125), eur(375));
      expect(eur(250) - eur(375), eur(-125));
      expect(-eur(250), eur(-250));
    });

    test('refuses to combine different currencies', () {
      expect(
        () => eur(1) + const Money(1, Currency.usd),
        throwsA(isA<CurrencyMismatch>()),
      );
    });

    test('compares amounts of one currency', () {
      expect(eur(1).compareTo(eur(2)), isNegative);
    });
  });

  group('Money.allocate', () {
    test('gives the indivisible cents to the first parts', () {
      expect(
        eur(625).allocate([1, 1, 1, 1]),
        [eur(157), eur(156), eur(156), eur(156)],
      );
    });

    test('keeps the sign of an outflow', () {
      expect(eur(-625).allocate([1, 1]), [eur(-313), eur(-312)]);
    });

    test('follows the weights', () {
      expect(eur(100).allocate([3, 1]), [eur(75), eur(25)]);
    });

    test('gives nothing to a part with no weight', () {
      expect(eur(1).allocate([0, 1]), [eur(0), eur(1)]);
    });

    test('rejects weights that are negative or add up to nothing', () {
      expect(() => eur(100).allocate([1, -1]), throwsArgumentError);
      expect(() => eur(100).allocate([0, 0]), throwsArgumentError);
      expect(() => eur(100).allocate([]), throwsArgumentError);
    });
  });
}
