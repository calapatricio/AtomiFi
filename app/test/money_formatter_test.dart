import 'package:atomifi/money_formatter.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter', () {
    const formatter = MoneyFormatter('en');

    test('writes an amount with the symbol of its currency', () {
      expect(formatter.format(const Money(123456, Currency.eur)), '€1,234.56');
      expect(formatter.format(const Money(500, Currency.usd)), r'$5.00');
    });

    test('writes the sign of money that left', () {
      expect(formatter.format(const Money(-1250, Currency.eur)), '-€12.50');
    });

    test('writes no decimals for a currency that has none', () {
      expect(formatter.format(const Money(1620, Currency.jpy)), '¥1,620');
    });
  });
}
