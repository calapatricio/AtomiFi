import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

Recurrence _every(int count, RecurrenceUnit unit, DateTime anchor) =>
    Recurrence(every: count, unit: unit, anchor: anchor);

void main() {
  group('Recurrence', () {
    test('every calendar month runs from the first day to the next first', () {
      final period = Recurrence.calendarMonths.periodAt(
        DateTime(2026, 11, 15, 13),
      );

      expect(period, DateRange(DateTime(2026, 11), DateTime(2026, 12)));
    });

    test('every two weeks counts fourteen days from its first day', () {
      final fortnightly =
          _every(2, RecurrenceUnit.week, DateTime(2026, 11, 13));

      expect(
        fortnightly.periodAt(DateTime(2026, 11, 20)),
        DateRange(DateTime(2026, 11, 13), DateTime(2026, 11, 27)),
      );
      expect(
        fortnightly.periodAt(DateTime(2026, 11, 27)),
        DateRange(DateTime(2026, 11, 27), DateTime(2026, 12, 11)),
      );
    });

    test('also has periods before its first day', () {
      final fortnightly =
          _every(2, RecurrenceUnit.week, DateTime(2026, 11, 13));

      expect(
        fortnightly.periodAt(DateTime(2026, 11, 12, 23, 59)),
        DateRange(DateTime(2026, 10, 30), DateTime(2026, 11, 13)),
      );
    });

    test('every few days counts in days', () {
      final everyThreeDays =
          _every(3, RecurrenceUnit.day, DateTime(2026, 11, 1));

      expect(
        everyThreeDays.periodAt(DateTime(2026, 11, 8)),
        DateRange(DateTime(2026, 11, 7), DateTime(2026, 11, 10)),
      );
    });

    test('every year keeps its day, whatever the length of the year', () {
      final yearly = _every(1, RecurrenceUnit.year, DateTime(2026, 6, 20));

      expect(
        yearly.periodAt(DateTime(2026, 11, 15)),
        DateRange(DateTime(2026, 6, 20), DateTime(2027, 6, 20)),
      );
      expect(
        yearly.periodAt(DateTime(2026, 3, 1)),
        DateRange(DateTime(2025, 6, 20), DateTime(2026, 6, 20)),
      );
    });

    test('falls on the last day of a month too short for its day', () {
      final monthly = _every(1, RecurrenceUnit.month, DateTime(2026, 1, 31));

      expect(
        monthly.periodAt(DateTime(2026, 2, 10)),
        DateRange(DateTime(2026, 1, 31), DateTime(2026, 2, 28)),
      );
      expect(
        monthly.periodAt(DateTime(2026, 2, 28)),
        DateRange(DateTime(2026, 2, 28), DateTime(2026, 3, 31)),
      );
    });

    test('keeps a leap day for the years that have one', () {
      final yearly = _every(1, RecurrenceUnit.year, DateTime(2024, 2, 29));

      expect(
        yearly.periodAt(DateTime(2025, 6, 1)),
        DateRange(DateTime(2025, 2, 28), DateTime(2026, 2, 28)),
      );
      expect(
        yearly.periodAt(DateTime(2028, 3, 1)),
        DateRange(DateTime(2028, 2, 29), DateTime(2029, 2, 28)),
      );
    });

    test('every few months skips the months in between', () {
      final quarterly = _every(3, RecurrenceUnit.month, DateTime(2026, 1, 1));

      expect(
        quarterly.periodAt(DateTime(2026, 5, 20)),
        DateRange(DateTime(2026, 4, 1), DateTime(2026, 7, 1)),
      );
    });

    test('starts its periods at the beginning of the day', () {
      final weekly = _every(1, RecurrenceUnit.week, DateTime(2026, 11, 2, 18));

      expect(weekly.anchor, DateTime(2026, 11, 2));
    });

    test('rejects a count that is not positive', () {
      expect(
        () => _every(0, RecurrenceUnit.week, DateTime(2026)),
        throwsArgumentError,
      );
    });

    test('is the same as another with the same count, unit and first day', () {
      expect(
        _every(2, RecurrenceUnit.week, DateTime(2026, 11, 13)),
        _every(2, RecurrenceUnit.week, DateTime(2026, 11, 13)),
      );
    });
  });
}
