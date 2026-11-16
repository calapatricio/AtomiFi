import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

Budget _budget(String id, BudgetScope scope) => Budget(
      id: BudgetId(id),
      name: id,
      limit: eur(100000),
      period: RecurringPeriod(Recurrence.calendarMonths),
      scope: scope,
    );

void main() {
  group('BudgetAssignments', () {
    const hotel = ItemId('hotel');
    const dinner = ItemId('dinner');
    const trip = BudgetId('trip');
    const party = BudgetId('party');

    late InMemoryStore store;
    late BudgetAssignments assignments;

    Future<Set<ItemId>> itemsOf(BudgetId id) async {
      final budget =
          (await store.budgets.all()).firstWhere((budget) => budget.id == id);
      return (budget.scope as ChosenItems).itemIds;
    }

    setUp(() async {
      store = InMemoryStore();
      assignments = BudgetAssignments(store.budgets);
      await store.budgets.save(_budget('trip', const ChosenItems({dinner})));
      await store.budgets.save(_budget('party', const ChosenItems({})));
      await store.budgets.save(_budget('monthly', const AllSpending()));
    });

    test('offers the budgets that take items one by one', () async {
      final budgets = await assignments.budgetsForChosenItems();

      expect(budgets.map((budget) => budget.id), [party, trip]);
    });

    test('tells which budget each item is in', () async {
      expect(await assignments.budgetOfEach([hotel, dinner]), {dinner: trip});
    });

    test('puts an item in the budget chosen for it', () async {
      await assignments.assign({hotel: trip});

      expect(await itemsOf(trip), {dinner, hotel});
    });

    test('takes an item out when no budget is chosen for it', () async {
      await assignments.assign({dinner: null});

      expect(await itemsOf(trip), isEmpty);
    });

    test('moves an item from one budget to another', () async {
      await assignments.assign({dinner: party});

      expect(await itemsOf(trip), isEmpty);
      expect(await itemsOf(party), {dinner});
    });

    test('leaves alone the items it is not told about', () async {
      await assignments.assign({hotel: party});

      expect(await itemsOf(trip), {dinner});
    });

    test('puts nothing in a budget that does not take items', () async {
      await assignments.assign({hotel: const BudgetId('monthly')});

      final monthly = (await store.budgets.all())
          .firstWhere((budget) => budget.id == const BudgetId('monthly'));
      expect(monthly.scope, isA<AllSpending>());
      expect(await assignments.budgetOfEach([hotel]), isEmpty);
    });
  });

  group('Budget.withItems', () {
    test('replaces the items of a budget for chosen items', () {
      final budget = _budget('trip', const ChosenItems({ItemId('dinner')}))
          .withItems(const {ItemId('hotel')});

      expect((budget.scope as ChosenItems).itemIds, const {ItemId('hotel')});
    });

    test('is refused by a budget that does not take items', () {
      expect(
        () => _budget('monthly', const AllSpending()).withItems(const {}),
        throwsStateError,
      );
    });
  });
}
