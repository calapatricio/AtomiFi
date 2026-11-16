import '../ids.dart';
import 'budget.dart';
import 'budget_repository.dart';
import 'budget_scope.dart';

/// Puts items in the budgets that take them one by one, and takes them out.
final class BudgetAssignments {
  BudgetAssignments(this._budgets);

  final BudgetRepository _budgets;

  /// The budgets that take items one by one, ordered by name.
  Future<List<Budget>> budgetsForChosenItems() async => [
        for (final budget in await _budgets.all())
          if (budget.scope is ChosenItems) budget,
      ];

  /// The budget that each of [itemIds] is in. Items in none are left out.
  Future<Map<ItemId, BudgetId>> budgetOfEach(Iterable<ItemId> itemIds) async {
    final budgets = await budgetsForChosenItems();
    return {
      for (final budget in budgets)
        for (final itemId in itemIds)
          if (_itemsOf(budget).contains(itemId)) itemId: budget.id,
    };
  }

  /// Leaves each item in the budget given for it and in no other. An item
  /// given no budget is taken out of the one it was in.
  Future<void> assign(Map<ItemId, BudgetId?> budgetByItem) async {
    for (final budget in await budgetsForChosenItems()) {
      final before = _itemsOf(budget);
      final after = {
        for (final itemId in before)
          if (!budgetByItem.containsKey(itemId)) itemId,
        for (final MapEntry(key: itemId, value: budgetId)
            in budgetByItem.entries)
          if (budgetId == budget.id) itemId,
      };
      if (!_areSame(before, after))
        await _budgets.save(budget.withItems(after));
    }
  }

  static Set<ItemId> _itemsOf(Budget budget) => switch (budget.scope) {
        ChosenItems(:final itemIds) => itemIds,
        AllSpending() || CategorySpending() => const {},
      };

  static bool _areSame(Set<ItemId> one, Set<ItemId> other) =>
      one.length == other.length && one.containsAll(other);
}
