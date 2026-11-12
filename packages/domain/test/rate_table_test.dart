import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('RateTable', () {
    final rates = RateTable(
      base: Currency.eur,
      unitsPerBase: {Currency.usd: 1.08, Currency.jpy: 162},
    );

    test('leaves an amount in the target currency untouched', () {
      expect(rates.convert(usd(500), Currency.usd), usd(500));
    });

    test('converts from the base currency', () {
      expect(rates.convert(eur(10000), Currency.usd), usd(10800));
    });

    test('converts to the base currency', () {
      expect(rates.convert(usd(10800), Currency.eur), eur(10000));
    });

    test('converts between two other currencies through the base', () {
      expect(
        rates.convert(usd(1080), Currency.jpy),
        const Money(1620, Currency.jpy),
      );
    });

    test('rounds to the nearest minor unit and keeps the sign', () {
      expect(rates.convert(eur(-1), Currency.usd), usd(-1));
      expect(rates.convert(eur(-7), Currency.usd), usd(-8));
    });

    test('rejects a currency it has no rate for', () {
      const gbp = Currency('GBP');

      expect(
        () => rates.convert(eur(100), gbp),
        throwsA(isA<MissingExchangeRate>()),
      );
    });
  });
}
