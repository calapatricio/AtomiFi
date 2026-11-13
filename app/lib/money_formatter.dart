import 'dart:math' as math;

import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';

/// Writes amounts of money the way a locale reads them.
final class MoneyFormatter {
  const MoneyFormatter(this.locale);

  /// The locale to write for, such as `en` or `es`.
  final String locale;

  String format(Money money) {
    final currency = money.currency;
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: currency.code,
      decimalDigits: currency.decimals,
    ).format(money.minorUnits / math.pow(10, currency.decimals));
  }
}
