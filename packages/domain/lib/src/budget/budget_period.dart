import '../stats/date_range.dart';

/// The stretch of time a budget's limit applies to.
sealed class BudgetPeriod {
  const BudgetPeriod();

  /// The period that [moment] falls in.
  DateRange rangeAt(DateTime moment);
}

/// A new period every calendar month.
final class EveryMonth extends BudgetPeriod {
  const EveryMonth();

  @override
  DateRange rangeAt(DateTime moment) =>
      DateRange.month(moment.year, moment.month);
}

/// One period that never repeats, such as a holiday.
final class FixedPeriod extends BudgetPeriod {
  const FixedPeriod(this.range);

  final DateRange range;

  @override
  DateRange rangeAt(DateTime moment) => range;
}
