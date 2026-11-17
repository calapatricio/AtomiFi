import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

void main() {
  final moment = DateTime(2026, 11, 13, 16, 50);

  group('The period the statistics look at', () {
    test('can be everything there is', () {
      final range = const AllTime().rangeAt(moment);

      expect(range.contains(DateTime(1990)), isTrue);
      expect(range.contains(DateTime(2100)), isTrue);
    });

    test('can be the time between two dates, whatever the moment', () {
      final summer = DateRange(DateTime(2026, 7), DateTime(2026, 9));

      expect(BetweenDates(summer).rangeAt(moment), summer);
    });

    test('can be the one that a moment falls in, of those that repeat', () {
      final everyTwoWeeks = RepeatingPeriod(
        Recurrence(
          every: 2,
          unit: RecurrenceUnit.week,
          anchor: DateTime(2026, 7),
        ),
      );

      expect(
        everyTwoWeeks.rangeAt(moment),
        DateRange(DateTime(2026, 11, 4), DateTime(2026, 11, 18)),
      );
    });

    test('can be the last days up to today, today included', () {
      expect(
        LastDays(7).rangeAt(moment),
        DateRange(DateTime(2026, 11, 7), DateTime(2026, 11, 14)),
      );
      expect(
        LastDays(1).rangeAt(moment),
        DateRange(DateTime(2026, 11, 13), DateTime(2026, 11, 14)),
      );
    });

    test('needs at least one last day', () {
      expect(() => LastDays(0), throwsArgumentError);
    });
  });
}
