import '../money/money.dart';

/// What was earned minus what was spent in a period, by the end of one
/// day.
final class TrendPoint {
  const TrendPoint(this.day, this.total);

  final DateTime day;

  /// The total so far: negative when more was spent than earned.
  final Money total;
}
