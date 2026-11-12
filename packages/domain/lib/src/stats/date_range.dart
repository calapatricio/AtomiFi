/// A period of time that includes [start] and excludes [end].
final class DateRange {
  DateRange(this.start, this.end) {
    if (!end.isAfter(start)) {
      throw ArgumentError('A date range must end after it starts.');
    }
  }

  factory DateRange.month(int year, int month) =>
      DateRange(DateTime(year, month), DateTime(year, month + 1));

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}
