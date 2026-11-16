import 'package:atomifi/goals/goals_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('GoalsViewModel', () {
    late InMemoryStore store;
    late GoalsViewModel viewModel;

    setUp(() async {
      store = await seededStore();
      viewModel = goalsViewModelOn(store);
    });

    test('has nothing to show until there is a goal', () async {
      await viewModel.load();

      expect(viewModel.progress, isEmpty);
    });

    test('tells how far each goal has come', () async {
      await store.goals.save(
        pizzaGoal(itemIds: {const ItemId('payroll-item')}),
      );
      await store.transactions.save(income('payroll', bank, 20000));
      await store.transactions.save(income('other', bank, 99900));

      await viewModel.load();
      final progress = viewModel.progress.single;

      expect(progress.goal.name, 'Pizza oven');
      expect(progress.reached, eur(20000));
      expect(progress.remaining, eur(30000));
    });

    test('removes a goal', () async {
      final goal = pizzaGoal();
      await store.goals.save(goal);
      await viewModel.load();

      await viewModel.remove(goal);

      expect(viewModel.progress, isEmpty);
      expect(await store.goals.all(), isEmpty);
    });

    test('tells its listeners when it has loaded', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(notifications, 1);
    });
  });
}
