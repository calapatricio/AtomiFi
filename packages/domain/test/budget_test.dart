import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

const _categories = [
  Category(id: CategoryId('food'), name: 'Food', side: CategorySide.expense),
  Category(
    id: CategoryId('leisure'),
    name: 'Leisure',
    side: CategorySide.expense,
  ),
  Category(
    id: CategoryId('alcohol'),
    name: 'Alcohol',
    side: CategorySide.expense,
    parentId: CategoryId('leisure'),
  ),
  Category(id: CategoryId('salary'), name: 'Salary', side: CategorySide.income),
  Category(
    id: CategoryId('correction'),
    name: 'Balance correction',
    side: CategorySide.neutral,
  ),
];

Budget _budget({
  int limitCents = 100000,
  BudgetPeriod? period,
  BudgetScope scope = const AllSpending(),
}) =>
    Budget(
      id: const BudgetId('budget'),
      name: 'Budget',
      limit: eur(limitCents),
      period: period ?? RecurringPeriod(Recurrence.calendarMonths),
      scope: scope,
    );

BudgetProgress _progress(
  Budget budget,
  List<Transaction> ledger, {
  DateTime? at,
  CurrencyConverter? converter,
}) =>
    BudgetProgressCalculator(categories: _categories, converter: converter)
        .progressOf(budget, ledger, at: at ?? DateTime(2026, 11, 15));

void main() {
  group('Budget', () {
    test('rejects a limit that is not positive', () {
      expect(() => _budget(limitCents: 0), throwsArgumentError);
      expect(() => _budget(limitCents: -100), throwsArgumentError);
    });
  });

  group('BudgetPeriod', () {
    test('a recurring period is the one its recurrence gives', () {
      final fortnightly = RecurringPeriod(
        Recurrence(
          every: 2,
          unit: RecurrenceUnit.week,
          anchor: DateTime(2026, 11, 13),
        ),
      );

      expect(
        fortnightly.rangeAt(DateTime(2026, 11, 20)),
        DateRange(DateTime(2026, 11, 13), DateTime(2026, 11, 27)),
      );
    });

    test('a fixed period is the same whenever it is asked', () {
      final holidays = DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 16));

      expect(FixedPeriod(holidays).rangeAt(DateTime(2026, 11, 15)), holidays);
    });
  });

  group('A budget for all spending', () {
    test('counts what was spent in its current period', () {
      final progress = _progress(_budget(), [
        on(DateTime(2026, 10, 31), [mine(-9900)]),
        on(DateTime(2026, 11, 2), [mine(-1500)]),
        on(DateTime(2026, 11, 9), [mine(-1200, category: 'alcohol')]),
      ]);

      expect(progress.spent, eur(2700));
      expect(progress.remaining, eur(97300));
      expect(progress.range.start, DateTime(2026, 11));
      expect(progress.isOverspent, isFalse);
    });

    test('counts only my share of what I paid for others too', () {
      final progress = _progress(_budget(), [
        on(DateTime(2026, 11, 7), [
          shared({me: -1250, moy: -1400}),
        ]),
      ]);

      expect(progress.spent, eur(1250));
    });

    test('does not count income', () {
      final progress = _progress(_budget(), [
        on(DateTime(2026, 11, 1), [mine(150000, category: 'salary')]),
      ]);

      expect(progress.spent, eur(0));
    });

    test('gets back what a refund returns', () {
      final progress = _progress(_budget(), [
        on(DateTime(2026, 11, 3), [mine(-5000)]),
        on(DateTime(2026, 11, 10), [mine(2000)]),
      ]);

      expect(progress.spent, eur(3000));
    });

    test('leaves out the categories it is told to, and their subcategories',
        () {
      final budget = _budget(
        scope: const AllSpending(except: {CategoryId('leisure')}),
      );

      final progress = _progress(budget, [
        on(DateTime(2026, 11, 2), [
          mine(-1500, category: 'food'),
          mine(-800, category: 'leisure'),
          mine(-1200, category: 'alcohol'),
        ]),
      ]);

      expect(progress.spent, eur(1500));
    });

    test('does not count what is in a neutral category', () {
      final progress = _progress(_budget(), [
        on(DateTime(2026, 11, 1), [mine(250000, category: 'correction')]),
        on(DateTime(2026, 11, 2), [mine(-1500)]),
      ]);

      expect(progress.spent, eur(1500));
    });

    test('is overspent once more than its limit is gone', () {
      final progress = _progress(_budget(limitCents: 1000), [
        on(DateTime(2026, 11, 2), [mine(-1500)]),
      ]);

      expect(progress.remaining, eur(-500));
      expect(progress.isOverspent, isTrue);
    });

    test('counts spending in other currencies in its own', () {
      final dollars = Item.mine(
        id: const ItemId('dollars'),
        name: 'Dollars',
        categoryId: const CategoryId('food'),
        price: usd(-1080),
      );

      final progress = _progress(
        _budget(),
        [
          on(DateTime(2026, 11, 2), [dollars], account: broker),
        ],
        converter: RateTable(
          base: Currency.eur,
          unitsPerBase: {Currency.usd: 1.08},
        ),
      );

      expect(progress.spent, eur(1000));
    });
  });

  group('A budget for some categories', () {
    final budget = _budget(
      scope: const CategorySpending({CategoryId('leisure')}),
    );

    test('counts those categories and their subcategories', () {
      final progress = _progress(budget, [
        on(DateTime(2026, 11, 2), [
          mine(-1500, category: 'food'),
          mine(-800, category: 'leisure'),
          mine(-1200, category: 'alcohol'),
        ]),
      ]);

      expect(progress.spent, eur(2000));
    });
  });

  group('A budget for chosen items', () {
    final budget = _budget(
      period: FixedPeriod(
        DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 16)),
      ),
      scope: const ChosenItems({ItemId('hotel'), ItemId('dinner')}),
    );

    test('counts those items and no others', () {
      final progress = _progress(budget, [
        on(DateTime(2026, 8, 2), [
          mine(-20000, id: 'hotel'),
          mine(-900, id: 'gym'),
        ]),
        on(DateTime(2026, 8, 3), [
          shared({me: -3000, moy: -3000}, id: 'dinner'),
        ]),
      ]);

      expect(progress.spent, eur(23000));
      expect(progress.range.end, DateTime(2026, 8, 16));
    });

    test('leaves out a chosen item from outside its period', () {
      final progress = _progress(budget, [
        on(DateTime(2026, 9, 1), [mine(-20000, id: 'hotel')]),
      ]);

      expect(progress.spent, eur(0));
    });

    test('can take in one more item', () {
      final extended = budget.withItem(const ItemId('museum'));

      expect(
        (extended.scope as ChosenItems).itemIds,
        contains(const ItemId('museum')),
      );
      expect(extended.id, budget.id);
    });
  });
}
