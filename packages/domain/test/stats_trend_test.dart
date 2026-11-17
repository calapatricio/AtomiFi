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
];

final _november = DateRange.month(2026, 11);

List<TrendPoint> _trend(
  List<Transaction> ledger, {
  CategorySide side = CategorySide.expense,
  bool Function(Item item)? where,
}) =>
    StatsCalculator(categories: _categories, currency: Currency.eur)
        .trendFor(_november, ledger, side, where: where);

void main() {
  group('How the expenses build up over a period', () {
    test('is the total so far on each day something was spent', () {
      final trend = _trend([
        on(DateTime(2026, 11, 9, 21), [mine(-500)]),
        on(DateTime(2026, 11, 2, 10), [mine(-1000)]),
        on(DateTime(2026, 11, 2, 18), [mine(-200, category: 'alcohol')]),
      ]);

      expect(trend.map((point) => point.day), [
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 9),
      ]);
      expect(trend.map((point) => point.total), [eur(1200), eur(1700)]);
    });

    test('goes down on a day more came back than was spent', () {
      final trend = _trend([
        on(DateTime(2026, 11, 2), [mine(-1000)]),
        on(DateTime(2026, 11, 3), [mine(300)]),
      ]);

      expect(trend.last.total, eur(700));
    });

    test('counts only my share, inside the period, on that side', () {
      final trend = _trend([
        on(DateTime(2026, 10, 31), [mine(-9900)]),
        on(DateTime(2026, 11, 2), [
          shared({me: -600, moy: -400}),
          mine(5000, category: 'salary'),
        ]),
      ]);

      expect(trend.single.total, eur(600));
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

      expect(trend.single.total, eur(200));
    });

    test('is empty when nothing was spent', () {
      expect(_trend([]), isEmpty);
    });
  });

  group('How the income builds up over a period', () {
    test('is the total earned so far', () {
      final trend = _trend(
        [
          on(DateTime(2026, 11, 1), [mine(5000, category: 'salary')]),
          on(DateTime(2026, 11, 2), [mine(-1000)]),
        ],
        side: CategorySide.income,
      );

      expect(trend.single.total, eur(5000));
    });
  });
}
