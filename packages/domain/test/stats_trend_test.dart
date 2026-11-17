import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

const _categories = [
  Category(id: CategoryId('food'), name: 'Food', side: CategorySide.expense),
  Category(
    id: CategoryId('alcohol'),
    name: 'Alcohol',
    side: CategorySide.expense,
  ),
  Category(id: CategoryId('salary'), name: 'Salary', side: CategorySide.income),
  Category(
    id: CategoryId('correction'),
    name: 'Balance correction',
    side: CategorySide.neutral,
  ),
];

final _november = DateRange.month(2026, 11);

final _calculator =
    StatsCalculator(categories: _categories, currency: Currency.eur);

List<TrendPoint> _trend(
  List<Transaction> ledger, {
  bool Function(Item item)? where,
}) =>
    _calculator.trendFor(_november, ledger, where: where);

List<StatsEntry> _entries(
  List<Transaction> ledger, {
  bool Function(Item item)? where,
}) =>
    _calculator.entriesFor(_november, ledger, where: where);

void main() {
  group('How my money built up over a period', () {
    test('is what was earned minus what was spent so far, day by day', () {
      final trend = _trend([
        on(DateTime(2026, 11, 9, 21), [mine(-500)]),
        on(DateTime(2026, 11, 2, 10), [mine(5000, category: 'salary')]),
        on(DateTime(2026, 11, 2, 18), [mine(-200, category: 'alcohol')]),
      ]);

      expect(trend.map((point) => point.day), [
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 9),
      ]);
      expect(trend.map((point) => point.total), [eur(4800), eur(4300)]);
    });

    test('counts only my share, inside the period', () {
      final trend = _trend([
        on(DateTime(2026, 10, 31), [mine(-9900)]),
        on(DateTime(2026, 11, 2), [
          shared({me: -600, moy: -400}),
        ]),
      ]);

      expect(trend.single.total, eur(-600));
    });

    test('leaves out what is neither income nor spending', () {
      final trend = _trend([
        on(DateTime(2026, 11, 2), [
          mine(-600),
          mine(-5000, category: 'correction'),
        ]),
      ]);

      expect(trend.single.total, eur(-600));
    });

    test('counts only the items that are asked for', () {
      final trend = _trend(
        [
          on(DateTime(2026, 11, 2), [
            mine(-1000),
            mine(-200, category: 'alcohol'),
          ]),
        ],
        where: (item) => item.categoryId == const CategoryId('alcohol'),
      );

      expect(trend.single.total, eur(-200));
    });

    test('is empty when nothing happened', () {
      expect(_trend([]), isEmpty);
    });
  });

  group('The transactions that count in a period', () {
    final lunch = on(DateTime(2026, 11, 9, 14), [
      shared({me: -600, moy: -400}),
      mine(-200, category: 'alcohol'),
    ]);
    final payroll = on(DateTime(2026, 11, 2), [
      mine(5000, category: 'salary'),
    ]);
    final earlier = on(DateTime(2026, 10, 31), [mine(-9900)]);

    test('are those with something of mine in it, the latest first', () {
      final entries = _entries([payroll, earlier, lunch]);

      expect(entries.map((entry) => entry.transaction), [lunch, payroll]);
      expect(entries.map((entry) => entry.date), [
        DateTime(2026, 11, 9, 14),
        DateTime(2026, 11, 2),
      ]);
    });

    test('come with what each one counts for: my share of its items', () {
      final entries = _entries([lunch, payroll]);

      expect(entries.map((entry) => entry.amount), [eur(-800), eur(5000)]);
    });

    test('count only the items that are asked for', () {
      final entries = _entries(
        [lunch, payroll],
        where: (item) => item.categoryId == const CategoryId('alcohol'),
      );

      expect(entries.single.transaction, lunch);
      expect(entries.single.amount, eur(-200));
    });

    test('leave out what is neither income nor spending', () {
      final entries = _entries([
        on(DateTime(2026, 11, 2), [mine(-5000, category: 'correction')]),
      ]);

      expect(entries, isEmpty);
    });

    test('show an item that offsets an earlier one on the earlier date', () {
      final dinner = on(DateTime(2026, 11, 20), [mine(-3000, id: 'dinner')]);
      final refund = on(DateTime(2026, 12, 3), [
        mine(1000, id: 'refund', offsets: 'dinner'),
      ]);

      final entries = _entries([dinner, refund]);

      expect(entries.map((entry) => entry.transaction), [dinner, refund]);
      expect(entries.last.date, DateTime(2026, 11, 20));
    });
  });
}
