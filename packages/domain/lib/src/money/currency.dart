/// An ISO 4217 currency and the number of decimals of its minor unit.
final class Currency {
  const Currency(this.code, {this.decimals = 2});

  static const eur = Currency('EUR');
  static const usd = Currency('USD');
  static const jpy = Currency('JPY', decimals: 0);

  final String code;
  final int decimals;

  @override
  bool operator ==(Object other) =>
      other is Currency && other.code == code && other.decimals == decimals;

  @override
  int get hashCode => Object.hash(code, decimals);

  @override
  String toString() => code;
}
