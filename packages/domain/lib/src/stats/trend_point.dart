import '../money/money.dart';

/// What the spending or the income of a period had added up to by the end
/// of one day.
final class TrendPoint {
  const TrendPoint(this.day, this.total);

  final DateTime day;

  /// The total so far, positive for money spent on the expense side and
  /// for money earned on the income side.
  final Money total;
}
