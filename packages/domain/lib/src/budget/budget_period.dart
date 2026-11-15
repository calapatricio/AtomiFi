import '../stats/date_range.dart';
import '../time/recurrence.dart';

/// The stretch of time a budget's limit applies to.
sealed class BudgetPeriod {
  const BudgetPeriod();

  /// The period that [moment] falls in.
  DateRange rangeAt(DateTime moment);
}

/// A period that starts over: every month, every two weeks, every year.
final class RecurringPeriod extends BudgetPeriod {
  const RecurringPeriod(this.recurrence);

  final Recurrence recurrence;

  @override
  DateRange rangeAt(DateTime moment) => recurrence.periodAt(moment);
}

/// One period that never repeats, such as a holiday.
final class FixedPeriod extends BudgetPeriod {
  const FixedPeriod(this.range);

  final DateRange range;

  @override
  DateRange rangeAt(DateTime moment) => range;
}
