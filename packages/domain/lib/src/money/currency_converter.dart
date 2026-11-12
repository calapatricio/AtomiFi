import 'currency.dart';
import 'money.dart';

/// Expresses an amount in another currency.
abstract interface class CurrencyConverter {
  Money convert(Money amount, Currency target);
}

/// Thrown when an amount cannot be converted for lack of a rate.
final class MissingExchangeRate implements Exception {
  const MissingExchangeRate(this.currency);

  final Currency currency;

  @override
  String toString() => 'MissingExchangeRate: no rate for $currency';
}
