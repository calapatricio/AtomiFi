import 'package:atomifi/budgets/budget_form_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  late InMemoryStore store;
  late BudgetFormViewModel form;

  Future<Budget> saved() async => (await store.budgets.all()).single;

  setUp(() async {
    store = await seededStore();
    form = budgetFormOn(store);
    await form.load();
  });

  group('A new budget', () {
    test('starts as a monthly budget for all spending', () {
      expect(form.repeats, isTrue);
      expect(form.every, '1');
      expect(form.unit, RecurrenceUnit.month);
      expect(form.start, DateTime(2026, 11));
      expect(form.coverage, BudgetCoverage.allSpending);
      expect(form.currency, Currency.eur);
    });

    test('cannot be saved without a name and a limit', () {
      expect(form.canSave, isFalse);

      form.name = 'Monthly';
      expect(form.canSave, isFalse);

      form.limit = '0';
      expect(form.canSave, isFalse);

      form.limit = '1200';
      expect(form.canSave, isTrue);
    });

    test('is saved as it was filled in', () async {
      form
        ..name = ' Monthly '
        ..limit = '1200,50';

      await form.save();
      final budget = await saved();

      expect(budget.id, const BudgetId('new-0'));
      expect(budget.name, 'Monthly');
      expect(budget.limit, eur(120050));
      expect(budget.scope, isA<AllSpending>());
      expect(
        (budget.period as RecurringPeriod).recurrence,
        Recurrence(
          every: 1,
          unit: RecurrenceUnit.month,
          anchor: DateTime(2026, 11),
        ),
      );
    });
  });

  group('The period of a budget', () {
    setUp(() {
      form
        ..name = 'Investments'
        ..limit = '100';
    });

    test('can start over every so many weeks from a chosen day', () async {
      form
        ..every = '2'
        ..unit = RecurrenceUnit.week
        ..start = DateTime(2026, 11, 13);

      await form.save();

      expect(
        ((await saved()).period as RecurringPeriod).recurrence,
        Recurrence(
          every: 2,
          unit: RecurrenceUnit.week,
          anchor: DateTime(2026, 11, 13),
        ),
      );
    });

    test('needs a whole number of at least one to start over', () {
      form.every = '0';
      expect(form.canSave, isFalse);

      form.every = 'two';
      expect(form.canSave, isFalse);
    });

    test('can be one stretch of time that does not repeat', () async {
      form
        ..repeats = false
        ..start = DateTime(2026, 8, 1)
        ..end = DateTime(2026, 8, 15);

      await form.save();
      final period = (await saved()).period as FixedPeriod;

      expect(period.range.start, DateTime(2026, 8, 1));
      expect(period.range.contains(DateTime(2026, 8, 15, 23, 59)), isTrue);
      expect(period.range.contains(DateTime(2026, 8, 16)), isFalse);
    });

    test('cannot end before it starts', () {
      form
        ..repeats = false
        ..start = DateTime(2026, 8, 15)
        ..end = DateTime(2026, 8, 1);

      expect(form.canSave, isFalse);
    });
  });

  group('What a budget covers', () {
    setUp(() {
      form
        ..name = 'Alcohol'
        ..limit = '50';
    });

    test('can be some categories, chosen from the main ones', () async {
      form.coverage = BudgetCoverage.categories;
      expect(form.canSave, isFalse);

      form.toggleCategory(alcohol.id);
      form.toggleCategory(food.id);
      form.toggleCategory(food.id);

      expect(form.mainCategories.map((category) => category.name), [
        'Alcohol',
        'Food',
        'Salary',
      ]);
      expect(form.isCovered(alcohol.id), isTrue);
      expect(form.isCovered(food.id), isFalse);
      await form.save();

      expect(((await saved()).scope as CategorySpending).categoryIds, {
        alcohol.id,
      });
    });

    test('can be the items put in it one by one, none at first', () async {
      form.coverage = BudgetCoverage.chosenItems;

      await form.save();

      expect(((await saved()).scope as ChosenItems).itemIds, isEmpty);
    });
  });

  group('Editing a budget', () {
    Future<void> edit(Budget budget) async {
      await store.budgets.save(budget);
      form = budgetFormOn(store, existing: budget);
      await form.load();
    }

    test('starts from a budget that starts over', () async {
      await edit(
        Budget(
          id: const BudgetId('dca'),
          name: 'Investments',
          limit: const Money(10050, Currency.usd),
          period: RecurringPeriod(
            Recurrence(
              every: 2,
              unit: RecurrenceUnit.week,
              anchor: DateTime(2026, 11, 13),
            ),
          ),
          scope: CategorySpending({alcohol.id}),
        ),
      );

      expect(form.isEditing, isTrue);
      expect(form.name, 'Investments');
      expect(form.limit, '100.50');
      expect(form.currency, Currency.usd);
      expect(form.repeats, isTrue);
      expect(form.every, '2');
      expect(form.unit, RecurrenceUnit.week);
      expect(form.start, DateTime(2026, 11, 13));
      expect(form.coverage, BudgetCoverage.categories);
      expect(form.isCovered(alcohol.id), isTrue);
      expect(form.canSave, isTrue);
    });

    test('starts from a budget for one stretch of time', () async {
      await edit(
        Budget(
          id: const BudgetId('trip'),
          name: 'Trip',
          limit: eur(50000),
          period: FixedPeriod(
            DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 16)),
          ),
          scope: const ChosenItems({}),
        ),
      );

      expect(form.repeats, isFalse);
      expect(form.start, DateTime(2026, 8, 1));
      expect(form.end, DateTime(2026, 8, 15));
      expect(form.coverage, BudgetCoverage.chosenItems);
    });

    test('replaces the budget, keeping its id and its looks', () async {
      await edit(
        Budget(
          id: const BudgetId('monthly'),
          name: 'Monthly',
          limit: eur(100000),
          period: RecurringPeriod(Recurrence.calendarMonths),
          scope: const AllSpending(),
          appearance: const Appearance(color: 0xFF4CAF50),
        ),
      );

      form
        ..name = 'Everything'
        ..limit = '900';
      await form.save();
      final budget = await saved();

      expect(budget.id, const BudgetId('monthly'));
      expect(budget.name, 'Everything');
      expect(budget.limit, eur(90000));
      expect(budget.appearance, const Appearance(color: 0xFF4CAF50));
    });

    test('keeps the items that were put in the budget', () async {
      await edit(tripBudget(itemIds: {const ItemId('hotel')}));

      form.limit = '750';
      await form.save();

      expect(((await saved()).scope as ChosenItems).itemIds, {
        const ItemId('hotel'),
      });
    });

    test('keeps what a budget for all spending leaves out', () async {
      await edit(monthlyBudget(scope: AllSpending(except: {alcohol.id})));

      form.limit = '750';
      await form.save();

      expect(((await saved()).scope as AllSpending).except, {alcohol.id});
    });

    test('keeps the subcategories it covered, which it does not show', () async {
      const beer = CategoryId('beer');
      await edit(monthlyBudget(scope: const CategorySpending({beer})));

      form.toggleCategory(food.id);
      await form.save();

      expect(((await saved()).scope as CategorySpending).categoryIds, {
        beer,
        food.id,
      });
    });
  });
}
