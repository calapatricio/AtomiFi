import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The ways to say which period the statistics look at.
enum PeriodKind { repeating, lastDays, betweenDates, allTime }

/// The state of the form that chooses the period of the statistics.
final class PeriodFormViewModel extends ChangeNotifier {
  PeriodFormViewModel({
    required StatsPeriod current,
    required DateTime Function() now,
  }) {
    final today = _dayOf(now());
    _start = DateTime(today.year, today.month);
    _firstDay = _start;
    _lastDay = today;
    switch (current) {
      case RepeatingPeriod(:final recurrence):
        _kind = PeriodKind.repeating;
        _every = '${recurrence.every}';
        _unit = recurrence.unit;
        _start = recurrence.anchor;
      case LastDays(:final days):
        _kind = PeriodKind.lastDays;
        _days = '$days';
      case BetweenDates(:final range):
        _kind = PeriodKind.betweenDates;
        _firstDay = range.start;
        _lastDay = _dayBefore(range.end);
      case AllTime():
        _kind = PeriodKind.allTime;
    }
  }

  late PeriodKind _kind;
  String _every = '1';
  RecurrenceUnit _unit = RecurrenceUnit.month;
  late DateTime _start;
  String _days = '30';
  late DateTime _firstDay;
  late DateTime _lastDay;

  PeriodKind get kind => _kind;

  set kind(PeriodKind kind) => _change(() => _kind = kind);

  /// How many units a repeating period lasts, as typed.
  String get every => _every;

  set every(String every) => _change(() => _every = every);

  RecurrenceUnit get unit => _unit;

  set unit(RecurrenceUnit unit) => _change(() => _unit = unit);

  /// The first day of one of the repeating periods.
  DateTime get start => _start;

  set start(DateTime start) => _change(() => _start = start);

  /// How many last days to look at, as typed.
  String get days => _days;

  set days(String days) => _change(() => _days = days);

  /// The first of the two dates to look between.
  DateTime get firstDay => _firstDay;

  set firstDay(DateTime firstDay) => _change(() => _firstDay = firstDay);

  /// The last of the two dates to look between, which is looked at too.
  DateTime get lastDay => _lastDay;

  set lastDay(DateTime lastDay) => _change(() => _lastDay = lastDay);

  bool get canApply => _typedPeriod != null;

  /// The period as filled in.
  StatsPeriod get period =>
      _typedPeriod ?? (throw StateError('The period is not complete yet.'));

  StatsPeriod? get _typedPeriod => switch (_kind) {
    PeriodKind.repeating => switch (_wholeNumberIn(_every)) {
      final every? => RepeatingPeriod(
        Recurrence(every: every, unit: _unit, anchor: _start),
      ),
      null => null,
    },
    PeriodKind.lastDays => switch (_wholeNumberIn(_days)) {
      final days? => LastDays(days),
      null => null,
    },
    PeriodKind.betweenDates =>
      _lastDay.isBefore(_firstDay)
          ? null
          : BetweenDates(
              DateRange(
                _firstDay,
                DateTime(_lastDay.year, _lastDay.month, _lastDay.day + 1),
              ),
            ),
    PeriodKind.allTime => const AllTime(),
  };

  void _change(void Function() change) {
    change();
    notifyListeners();
  }

  /// The whole number of at least one that [text] holds, if it does.
  static int? _wholeNumberIn(String text) {
    final number = int.tryParse(text.trim());
    return number == null || number < 1 ? null : number;
  }

  static DateTime _dayOf(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  static DateTime _dayBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);
}
