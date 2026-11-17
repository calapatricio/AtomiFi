import 'package:atomifi/stats/stats_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  late InMemoryStore store;
  late StatsViewModel stats;

  final november = DateRange.month(2026, 11);
  final october = DateRange.month(2026, 10);

  setUp(() async {
    store = await seededStore();
    await store.categories.save(beer);
    for (final transaction in [
      spending('shop', centsByCategory: const {food: -1500}),
      spending('bar', centsByCategory: const {alcohol: -500, beer: -2000}),
      spending(
        'old',
        dateTime: DateTime(2026, 10, 20),
        centsByCategory: const {food: -900},
      ),
      income('payroll', bank, 200000),
    ]) {
      await store.transactions.save(transaction);
    }
    stats = statsViewModelOn(store);
    await stats.load();
  });

  group('The statistics', () {
    test('start on the expenses of the current month', () {
      expect(stats.range, november);
      expect(stats.side, CategorySide.expense);
      expect(stats.canStep, isTrue);
    });

    test('sum up the income, the expenses and what is left', () {
      expect(stats.summary.income, eur(200000));
      expect(stats.summary.expenses, eur(4000));
      expect(stats.summary.balance, eur(196000));
    });

    test('rank the main categories of the expenses', () {
      expect(stats.amounts.map((amount) => amount.category.name), [
        'Alcohol',
        'Food',
      ]);
      expect(stats.total, eur(4000));
    });

    test('show how the expenses built up, from the first day', () {
      expect(stats.trend.map((point) => point.day), [
        DateTime(2026, 11),
        DateTime(2026, 11, 6),
      ]);
      expect(stats.trend.map((point) => point.total), [eur(0), eur(4000)]);
    });

    test('can look at the income instead', () {
      stats.side = CategorySide.income;

      expect(stats.amounts.single.category.name, 'Salary');
      expect(stats.total, eur(200000));
      expect(stats.trend.single.total, eur(200000));
    });

    test('tell their listeners about every change', () {
      var notifications = 0;
      stats
        ..addListener(() => notifications++)
        ..side = CategorySide.income
        ..showPrevious()
        ..period = const AllTime();

      expect(notifications, 3);
    });
  });

  group('Looking into a category', () {
    test('shows its subcategories and itself', () {
      stats.open(stats.amounts.first);

      expect(stats.openCategory?.category.name, 'Alcohol');
      expect(stats.amounts.map((amount) => amount.category.name), [
        'Beer',
        'Alcohol',
      ]);
      expect(stats.total, eur(2500));
    });

    test('shows how that category alone built up', () {
      stats.open(stats.amounts.first);

      expect(stats.trend.last.total, eur(2500));
    });

    test('does nothing for a category without subcategories', () {
      stats.open(stats.amounts.last);

      expect(stats.openCategory, isNull);
    });

    test('can be left again', () {
      stats
        ..open(stats.amounts.first)
        ..close();

      expect(stats.openCategory, isNull);
      expect(stats.total, eur(4000));
    });

    test('is left when the other side is looked at', () {
      stats
        ..open(stats.amounts.first)
        ..side = CategorySide.income;

      expect(stats.openCategory, isNull);
    });

    test('is left when the period has nothing in that category', () {
      stats
        ..open(stats.amounts.first)
        ..showPrevious();

      expect(stats.openCategory, isNull);
      expect(stats.amounts.single.category.name, 'Food');
    });
  });

  group('The period of the statistics', () {
    test('can go to the one before and come back', () {
      stats.showPrevious();

      expect(stats.range, october);
      expect(stats.summary.expenses, eur(900));

      stats.showNext();

      expect(stats.range, november);
    });

    test('can be the last days, which have no one before or after', () {
      stats.period = LastDays(7);

      expect(
        stats.range,
        DateRange(DateTime(2026, 11, 7), DateTime(2026, 11, 14)),
      );
      expect(stats.canStep, isFalse);
      expect(stats.summary.expenses, eur(0));
    });

    test('can be everything, starting at the first thing recorded', () {
      stats.period = const AllTime();

      expect(stats.summary.expenses, eur(4900));
      expect(stats.trend.first.day, DateTime(2026, 10, 20));
    });

    test('starts again from today when another one is chosen', () {
      stats
        ..showPrevious()
        ..period = RepeatingPeriod(Recurrence.calendarMonths);

      expect(stats.range, november);
    });
  });
}
