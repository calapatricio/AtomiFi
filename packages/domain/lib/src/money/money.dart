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
      throw ArgumentError.value(weights, 'weights', 'must add up to more than 0');
    }
    return total;
  }
}
