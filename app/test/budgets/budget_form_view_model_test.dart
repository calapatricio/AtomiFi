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
}
