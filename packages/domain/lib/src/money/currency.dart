/// An ISO 4217 currency and the number of decimals of its minor unit.
final class Currency {
  const Currency(this.code, {this.decimals = 2});

  /// The currency with this ISO 4217 [code] and its usual decimals.
  factory Currency.iso(String code) =>
      Currency(code, decimals: _codesWithoutDecimals.contains(code) ? 0 : 2);

  static const eur = Currency('EUR');
  static const usd = Currency('USD');
  static const jpy = Currency('JPY', decimals: 0);

  static const _codesWithoutDecimals = {'CLP', 'ISK', 'JPY', 'KRW', 'VND'};

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
