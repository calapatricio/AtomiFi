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
  Category(
    id: CategoryId('clothes'),
    name: 'Clothes',
    side: CategorySide.expense,
  ),
  Category(id: CategoryId('salary'), name: 'Salary', side: CategorySide.income),
  Category(
    id: CategoryId('betting'),
    name: 'Betting',
    side: CategorySide.income,
  ),
];

final _october = DateRange.month(2026, 10);
final _november = DateRange.month(2026, 11);

PeriodStats _stats(
  DateRange period,
  List<Transaction> ledger, {
  OffsetDating offsetDating = OffsetDating.originalItemDate,
}) =>
    StatsCalculator(
      categories: _categories,
      currency: Currency.eur,
      offsetDating: offsetDating,
    ).statsFor(period, ledger);

void main() {
  group('StatsCalculator', () {
    test('reports each item of one transaction in its own category', () {
      final ledger = [
        on(DateTime(2026, 11, 6), [
          mine(-1200, category: 'alcohol'),
          mine(-180, category: 'food'),
        ]),
      ];

      final stats = _stats(_november, ledger);

      expect(stats.netFor(const CategoryId('alcohol')), eur(-1200));
      expect(stats.netFor(const CategoryId('food')), eur(-180));
      expect(stats.expenses, eur(1380));
    });

    test('reports income separately from expenses', () {
      final ledger = [
        on(DateTime(2026, 11, 1), [mine(150000, category: 'salary')]),
        on(DateTime(2026, 11, 2), [mine(-500)]),
      ];

      final stats = _stats(_november, ledger);

      expect(stats.income, eur(150000));
      expect(stats.expenses, eur(500));
    });

    test('leaves out transactions of other periods', () {
      final ledger = [
        on(DateTime(2026, 10, 31, 23, 59), [mine(-500)]),
      ];

      expect(_stats(_november, ledger).expenses, eur(0));
    });

    test('counts only my share of an item I paid for others too', () {
      final ledger = [
        on(DateTime(2026, 11, 7), [
          shared({me: -1250, moy: -1400}),
        ]),
      ];

      expect(_stats(_november, ledger).expenses, eur(1250));
    });

    test('ignores what others pay me back, whenever they pay', () {
      final ledger = [
        on(DateTime(2026, 10, 30), [
          shared({me: -1250, moy: -1400}, id: 'tacos'),
        ]),
        on(DateTime(2026, 11, 8), [
          shared({moy: 1400}, offsets: 'tacos'),
        ]),
      ];

      expect(_stats(_october, ledger).expenses, eur(1250));
      expect(_stats(_november, ledger).expenses, eur(0));
      expect(_stats(_november, ledger).income, eur(0));
    });

    test('nets a refund against the spending of its category', () {
      final ledger = [
        on(DateTime(2026, 11, 3), [mine(-5000, category: 'clothes')]),
        on(DateTime(2026, 11, 20), [mine(5000, category: 'clothes')]),
      ];

      final stats = _stats(_november, ledger);

      expect(stats.expenses, eur(0));
      expect(stats.income, eur(0));
    });

    test('shows an unresolved bet as money gone', () {
      final ledger = [
        on(DateTime(2026, 10, 30), [mine(-50000, category: 'betting')]),
      ];

      expect(_stats(_october, ledger).income, eur(-50000));
    });

    test('books a payout in the month of the bet it offsets', () {
      final ledger = [
        on(DateTime(2026, 10, 30), [
          mine(-50000, category: 'betting', id: 'stake'),
        ]),
        on(DateTime(2026, 11, 2), [
          mine(52000, category: 'betting', offsets: 'stake'),
        ]),
      ];

      expect(_stats(_october, ledger).income, eur(2000));
      expect(_stats(_november, ledger).income, eur(0));
    });

    test('books a payout on its own date when asked to', () {
      final ledger = [
        on(DateTime(2026, 10, 30), [
          mine(-50000, category: 'betting', id: 'stake'),
        ]),
        on(DateTime(2026, 11, 2), [
          mine(52000, category: 'betting', offsets: 'stake'),
        ]),
      ];

      final october =
          _stats(_october, ledger, offsetDating: OffsetDating.ownDate);
      final november =
          _stats(_november, ledger, offsetDating: OffsetDating.ownDate);

      expect(october.income, eur(-50000));
      expect(november.income, eur(52000));
    });

    test('books an item on its own date when its original is gone', () {
      final ledger = [
        on(DateTime(2026, 11, 2), [
          mine(52000, category: 'betting', offsets: 'deleted'),
        ]),
      ];

      expect(_stats(_november, ledger).income, eur(52000));
    });

    test('converts items of other currencies to the stats currency', () {
      final dollars = Item.mine(
        id: const ItemId('dollars'),
        name: 'Dollars',
        categoryId: const CategoryId('food'),
        price: usd(-1080),
      );
      final calculator = StatsCalculator(
        categories: _categories,
        currency: Currency.eur,
        converter: RateTable(
          base: Currency.eur,
          unitsPerBase: {Currency.usd: 1.08},
        ),
      );

      final stats = calculator.statsFor(_november, [
        on(DateTime(2026, 11, 2), [dollars], account: broker),
        on(DateTime(2026, 11, 3), [mine(-500)]),
      ]);

      expect(stats.expenses, eur(1500));
    });

    test('rejects an item in a category it does not know', () {
      final ledger = [
        on(DateTime(2026, 11, 2), [mine(-100, category: 'unknown')]),
      ];

      expect(() => _stats(_november, ledger), throwsArgumentError);
    });
  });
}
