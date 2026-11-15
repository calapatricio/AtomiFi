import 'package:atomifi/budgets/budgets_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('BudgetsViewModel', () {
    late InMemoryStore store;
    late BudgetsViewModel viewModel;

    setUp(() async {
      store = await seededStore();
      viewModel = budgetsViewModelOn(store);
    });

    test('has nothing to show until there is a budget', () async {
      await viewModel.load();

      expect(viewModel.progress, isEmpty);
    });

    test('tells how each budget stands now', () async {
      await store.budgets.save(monthlyBudget());
      await store.transactions.save(
        spending('this-month', dateTime: DateTime(2026, 11, 6)),
      );
      await store.transactions.save(
        spending('last-month', dateTime: DateTime(2026, 10, 6)),
      );

      await viewModel.load();
      final progress = viewModel.progress.single;

      expect(progress.budget.name, 'Monthly');
      expect(progress.spent, eur(1500));
      expect(progress.remaining, eur(98500));
      expect(progress.range.start, DateTime(2026, 11));
    });

    test('removes a budget', () async {
      final budget = monthlyBudget();
      await store.budgets.save(budget);
      await viewModel.load();

      await viewModel.remove(budget);

      expect(viewModel.progress, isEmpty);
      expect(await store.budgets.all(), isEmpty);
    });

    test('tells its listeners when it has loaded', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(notifications, 1);
    });
  });
}
