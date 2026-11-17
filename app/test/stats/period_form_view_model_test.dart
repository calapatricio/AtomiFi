import 'package:atomifi/stats/period_form_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

PeriodFormViewModel _formFor(StatsPeriod current) =>
    PeriodFormViewModel(current: current, now: () => now);

void main() {
  group('Choosing the period of the statistics', () {
    test('starts from a period that repeats', () {
      final recurrence = Recurrence(
        every: 2,
        unit: RecurrenceUnit.week,
        anchor: DateTime(2026, 7),
      );
      final form = _formFor(RepeatingPeriod(recurrence));

      expect(form.kind, PeriodKind.repeating);
      expect(form.every, '2');
      expect(form.unit, RecurrenceUnit.week);
      expect(form.start, DateTime(2026, 7));
      expect((form.period as RepeatingPeriod).recurrence, recurrence);
    });

    test('can repeat every so many days from a chosen day', () {
      final form = _formFor(const AllTime())
        ..kind = PeriodKind.repeating
        ..every = '20'
        ..unit = RecurrenceUnit.day
        ..start = DateTime(2026, 8);

      expect(
        (form.period as RepeatingPeriod).recurrence,
        Recurrence(every: 20, unit: RecurrenceUnit.day, anchor: DateTime(2026, 8)),
      );
    });

    test('suggests every month from the first day of this one', () {
      final form = _formFor(const AllTime())..kind = PeriodKind.repeating;

      expect(form.every, '1');
      expect(form.unit, RecurrenceUnit.month);
      expect(form.start, DateTime(2026, 11));
    });

    test('needs a whole number of at least one to repeat', () {
      final form = _formFor(const AllTime())..kind = PeriodKind.repeating;

      for (final every in ['', '0', 'two']) {
        form.every = every;
        expect(form.canApply, isFalse, reason: 'every "$every"');
      }
    });

    test('starts from the last days', () {
      final form = _formFor(LastDays(7));

      expect(form.kind, PeriodKind.lastDays);
      expect(form.days, '7');
      expect((form.period as LastDays).days, 7);
    });

    test('suggests the last thirty days', () {
      final form = _formFor(const AllTime())..kind = PeriodKind.lastDays;

      expect((form.period as LastDays).days, 30);
    });

    test('needs at least one last day', () {
      final form = _formFor(LastDays(7));

      for (final days in ['', '0', 'x']) {
        form.days = days;
        expect(form.canApply, isFalse, reason: 'days "$days"');
      }
    });

    test('starts from two dates, showing the last day inside them', () {
      final form = _formFor(
        BetweenDates(DateRange(DateTime(2026, 7), DateTime(2026, 9))),
      );

      expect(form.kind, PeriodKind.betweenDates);
      expect(form.firstDay, DateTime(2026, 7));
      expect(form.lastDay, DateTime(2026, 8, 31));
    });

    test('covers both chosen dates', () {
      final form = _formFor(const AllTime())
        ..kind = PeriodKind.betweenDates
        ..firstDay = DateTime(2026, 8, 1)
        ..lastDay = DateTime(2026, 8, 15);

      expect(
        (form.period as BetweenDates).range,
        DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 16)),
      );
    });

    test('suggests this month so far', () {
      final form = _formFor(const AllTime())..kind = PeriodKind.betweenDates;

      expect(form.firstDay, DateTime(2026, 11));
      expect(form.lastDay, DateTime(2026, 11, 13));
    });

    test('cannot end before it starts', () {
      final form = _formFor(const AllTime())
        ..kind = PeriodKind.betweenDates
        ..firstDay = DateTime(2026, 8, 15)
        ..lastDay = DateTime(2026, 8, 1);

      expect(form.canApply, isFalse);
      expect(() => form.period, throwsStateError);
    });

    test('can be everything', () {
      final form = _formFor(LastDays(7))..kind = PeriodKind.allTime;

      expect(form.period, isA<AllTime>());
    });

    test('tells its listeners about every change', () {
      var notifications = 0;
      _formFor(const AllTime())
        ..addListener(() => notifications++)
        ..kind = PeriodKind.lastDays
        ..days = '3';

      expect(notifications, 2);
    });
  });
}
