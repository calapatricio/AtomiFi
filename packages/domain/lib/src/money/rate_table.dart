import 'dart:math' as math;

import 'currency.dart';
import 'currency_converter.dart';
import 'money.dart';

/// Converts with a fixed table of rates quoted against one [base] currency.
final class RateTable implements CurrencyConverter {
  const RateTable({
    required this.base,
    Map<Currency, double> unitsPerBase = const {},
  }) : _unitsPerBase = unitsPerBase;

  final Currency base;

  /// How many units of each currency one unit of [base] buys.
  final Map<Currency, double> _unitsPerBase;

  @override
  Money convert(Money amount, Currency target) {
    if (amount.currency == target) return amount;
    final inBase = _toMajorUnits(amount) / _rateOf(amount.currency);
    final inTarget = inBase * _rateOf(target);
    return Money((inTarget * _minorUnitsPerUnit(target)).round(), target);
  }

  double _rateOf(Currency currency) {
    if (currency == base) return 1;
    return _unitsPerBase[currency] ?? (throw MissingExchangeRate(currency));
  }

  static double _toMajorUnits(Money amount) =>
      amount.minorUnits / _minorUnitsPerUnit(amount.currency);

  static num _minorUnitsPerUnit(Currency currency) =>
      math.pow(10, currency.decimals);
}
