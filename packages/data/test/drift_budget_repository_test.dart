import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

final _fortnightly = Recurrence(
  every: 2,
  unit: RecurrenceUnit.week,
  anchor: DateTime(2026, 11, 13),
);

Budget _budget({
  String id = 'monthly',
  String name = 'Monthly',
  Money? limit,
  BudgetPeriod? period,
  BudgetScope scope = const AllSpending(),
  Appearance appearance = Appearance.none,
}) =>
    Budget(
      id: BudgetId(id),
      name: name,
      limit: limit ?? eur(120000),
      period: period ?? RecurringPeriod(Recurrence.calendarMonths),
      scope: scope,
      appearance: appearance,
    );

void main() {
  late AtomiFiDatabase database;
  late BudgetRepository budgets;

  setUp(() async {
    database = await openSeededDatabase();
    budgets = DriftBudgetRepository(database);
  });

  tearDown(() => database.close());

  group('DriftBudgetRepository', () {
    test('starts without budgets', () async {
      expect(await budgets.all(), isEmpty);
    });

    test('restores a budget as it was saved', () async {
      const looks = Appearance(color: 0xFF607D8B, emoji: '💶');
      await budgets.save(_budget(limit: usd(50000), appearance: looks));

      final restored = (await budgets.all()).single;

      expect(restored.id, const BudgetId('monthly'));
      expect(restored.name, 'Monthly');
      expect(restored.limit, usd(50000));
      expect(restored.appearance, looks);
      expect(restored.scope, isA<AllSpending>());
    });

    test('restores how often a recurring budget starts over', () async {
      await budgets.save(_budget(period: RecurringPeriod(_fortnightly)));

      final period = (await budgets.all()).single.period as RecurringPeriod;

      expect(period.recurrence, _fortnightly);
    });

    test('restores the dates of a budget that does not repeat', () async {
      final holidays = DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 16));
      await budgets.save(_budget(period: FixedPeriod(holidays)));

      final period = (await budgets.all()).single.period as FixedPeriod;

      expect(period.range, holidays);
    });

    test('restores the categories a budget is for', () async {
      await budgets.save(
        _budget(scope: CategorySpending({leisure.id, food.id})),
      );

      final scope = (await budgets.all()).single.scope as CategorySpending;

      expect(scope.categoryIds, {leisure.id, food.id});
    });

    test('restores the items put in a budget', () async {
      await budgets.save(
        _budget(scope: const ChosenItems({ItemId('hotel'), ItemId('dinner')})),
      );

      final scope = (await budgets.all()).single.scope as ChosenItems;

      expect(scope.itemIds, const {ItemId('hotel'), ItemId('dinner')});
    });

    test('saving a budget again replaces it and what it covers', () async {
      await budgets.save(
        _budget(scope: const ChosenItems({ItemId('hotel'), ItemId('dinner')})),
      );
      await budgets.save(
        _budget(name: 'Holidays', scope: const ChosenItems({ItemId('hotel')})),
      );

      final restored = (await budgets.all()).single;

      expect(restored.name, 'Holidays');
      expect((restored.scope as ChosenItems).itemIds, const {ItemId('hotel')});
    });

    test('returns the budgets ordered by name', () async {
      await budgets.save(_budget(id: 'monthly', name: 'Monthly'));
      await budgets.save(_budget(id: 'alcohol', name: 'Alcohol'));

      final restored = await budgets.all();

      expect(restored.map((budget) => budget.name), ['Alcohol', 'Monthly']);
    });

    test('removes a budget with what it covers', () async {
      await budgets.save(
        _budget(scope: CategorySpending({leisure.id})),
      );

      await budgets.remove(const BudgetId('monthly'));

      expect(await budgets.all(), isEmpty);
      expect(await database.select(database.budgetCategories).get(), isEmpty);
    });
  });
}
