import '../time/recurrence.dart';
import 'date_range.dart';

/// The stretch of time the statistics look at, as the user chooses it.
sealed class StatsPeriod {
  const StatsPeriod();

  /// The dates it covers when looked at on [moment].
  DateRange rangeAt(DateTime moment);
}

/// Everything there is.
final class AllTime extends StatsPeriod {
  const AllTime();

  @override
  DateRange rangeAt(DateTime moment) => DateRange.allTime;
}

/// The time between two chosen dates.
final class BetweenDates extends StatsPeriod {
  const BetweenDates(this.range);

  final DateRange range;

  @override
  DateRange rangeAt(DateTime moment) => range;
}

/// One of the periods that follow each other, such as every month or every
/// two weeks from a chosen day: the one the moment falls in.
final class RepeatingPeriod extends StatsPeriod {
  const RepeatingPeriod(this.recurrence);

  final Recurrence recurrence;

  @override
  DateRange rangeAt(DateTime moment) => recurrence.periodAt(moment);
}

/// The last so many days, today included.
final class LastDays extends StatsPeriod {
  LastDays(this.days) {
    if (days < 1) {
      throw ArgumentError.value(days, 'days', 'must be at least 1');
    }
  }

  final int days;

  @override
  DateRange rangeAt(DateTime moment) => DateRange(
        DateTime(moment.year, moment.month, moment.day + 1 - days),
        DateTime(moment.year, moment.month, moment.day + 1),
      );
}
