import 'currency.dart';

/// Thrown when two amounts of different currencies are combined.
final class CurrencyMismatch implements Exception {
  const CurrencyMismatch(this.expected, this.actual);

  final Currency expected;
  final Currency actual;

  @override
  String toString() => 'CurrencyMismatch: expected $expected, got $actual';
}

/// A signed amount stored in the minor unit of its currency (cents for EUR).
///
/// Negative amounts are money leaving an account, positive ones money
/// entering it.
final class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  const Money.zero(this.currency) : minorUnits = 0;

  /// Reads an amount as a person types it, such as `12`, `12.5` or `12,50`.
  ///
  /// Gives nothing for text that is not an amount, that carries a sign or
  /// that has more decimals than [currency] has.
  static Money? tryParse(String text, Currency currency) {
    final match = _typedAmount.firstMatch(text.trim());
    final decimals = match?.group(2) ?? '';
    if (match == null || decimals.length > currency.decimals) return null;
    final digits = match.group(1)! + decimals.padRight(currency.decimals, '0');
    return Money(int.parse(digits), currency);
  }

  static final _typedAmount = RegExp(r'^(\d+)(?:[.,](\d+))?$');

  final int minorUnits;
  final Currency currency;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) =>
      Money(minorUnits + _unitsOf(other), currency);

  Money operator -(Money other) =>
      Money(minorUnits - _unitsOf(other), currency);

  Money operator -() => Money(-minorUnits, currency);

  /// This amount without its sign.
  Money abs() => Money(minorUnits.abs(), currency);

  /// Splits this amount in proportion to [weights] without losing a unit.
  ///
  /// Units that cannot be divided evenly go, one each, to the first parts
  /// with a positive weight.
  List<Money> allocate(List<int> weights) {
    final totalWeight = _totalOf(weights);
    final magnitude = minorUnits.abs();
    final parts = [
      for (final weight in weights) magnitude * weight ~/ totalWeight,
    ];
    var leftover = magnitude - parts.fold(0, (sum, part) => sum + part);
    for (var index = 0; leftover > 0; index++) {
      if (weights[index] == 0) continue;
      parts[index]++;
      leftover--;
    }
    return [for (final part in parts) Money(part * minorUnits.sign, currency)];
  }

  /// The amount in whole units of its currency, such as `-12.50`.
  String toDecimalString() {
    final sign = isNegative ? '-' : '';
    final digits =
        minorUnits.abs().toString().padLeft(currency.decimals + 1, '0');
    final whole = digits.substring(0, digits.length - currency.decimals);
    final fraction = digits.substring(digits.length - currency.decimals);
    return fraction.isEmpty ? '$sign$whole' : '$sign$whole.$fraction';
  }

  @override
  int compareTo(Money other) => minorUnits.compareTo(_unitsOf(other));

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '$minorUnits $currency (minor units)';

  int _unitsOf(Money other) {
    if (other.currency != currency) {
      throw CurrencyMismatch(currency, other.currency);
    }
    return other.minorUnits;
  }

  static int _totalOf(List<int> weights) {
    if (weights.any((weight) => weight < 0)) {
      throw ArgumentError.value(weights, 'weights', 'must not be negative');
    }
    final total = weights.fold(0, (sum, weight) => sum + weight);
    if (total == 0) {
      throw ArgumentError.value(
          weights, 'weights', 'must add up to more than 0');
    }
    return total;
  }
}
