import 'dart:math' as math;

import '../stats/date_range.dart';

/// What a recurrence counts in.
enum RecurrenceUnit { day, week, month, year }

/// Something that starts over every so often: every month, every two
/// weeks, every year.
///
/// Its periods are counted from the day of [anchor], in whole days. Months
/// and years keep the day of the month of the anchor, or fall on the last
/// day of a month that is too short for it.
final class Recurrence {
  Recurrence({
    required this.every,
    required this.unit,
    required DateTime anchor,
  }) : anchor = DateTime(anchor.year, anchor.month, anchor.day) {
    if (every < 1) {
      throw ArgumentError.value(every, 'every', 'must be at least 1');
    }
  }

  /// Every calendar month, from its first day.
  static final calendarMonths = Recurrence(
    every: 1,
    unit: RecurrenceUnit.month,
    anchor: DateTime(2000),
  );

  static const _daysInWeek = 7;
  static const _monthsInYear = 12;

  /// How many [unit]s each period lasts.
  final int every;
  final RecurrenceUnit unit;

  /// The first day of one of the periods.
  final DateTime anchor;

  /// The period that [moment] falls in.
  DateRange periodAt(DateTime moment) {
    var index = _roughIndexOf(moment);
    while (_startOf(index).isAfter(moment)) {
      index--;
    }
    while (!_startOf(index + 1).isAfter(moment)) {
      index++;
    }
    return DateRange(_startOf(index), _startOf(index + 1));
  }

  @override
  bool operator ==(Object other) =>
      other is Recurrence &&
      other.every == every &&
      other.unit == unit &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(every, unit, anchor);

  @override
  String toString() => 'every $every ${unit.name} from $anchor';

  /// The start of the period that is [index] periods after the anchor.
  DateTime _startOf(int index) => switch (unit) {
        RecurrenceUnit.day => _daysLater(index * every),
        RecurrenceUnit.week => _daysLater(index * every * _daysInWeek),
        RecurrenceUnit.month => _monthsLater(index * every),
        RecurrenceUnit.year => _monthsLater(index * every * _monthsInYear),
      };

  /// A period close to the one [moment] falls in, to start looking from.
  int _roughIndexOf(DateTime moment) => switch (unit) {
        RecurrenceUnit.day => _daysUntil(moment) ~/ every,
        RecurrenceUnit.week => _daysUntil(moment) ~/ (every * _daysInWeek),
        RecurrenceUnit.month => _monthsUntil(moment) ~/ every,
        RecurrenceUnit.year => _monthsUntil(moment) ~/ (every * _monthsInYear),
      };

  DateTime _daysLater(int days) =>
      DateTime(anchor.year, anchor.month, anchor.day + days);

  DateTime _monthsLater(int months) {
    final firstOfMonth = DateTime(anchor.year, anchor.month + months);
    final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      math.min(anchor.day, lastDay),
    );
  }

  /// Whole days from the anchor to the day of [moment], whatever the clocks
  /// did in between.
  int _daysUntil(DateTime moment) =>
      DateTime.utc(moment.year, moment.month, moment.day)
          .difference(DateTime.utc(anchor.year, anchor.month, anchor.day))
          .inDays;

  int _monthsUntil(DateTime moment) =>
      (moment.year - anchor.year) * _monthsInYear + moment.month - anchor.month;
}
