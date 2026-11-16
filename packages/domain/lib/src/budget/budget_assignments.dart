import '../ids.dart';
import '../ledger/item_assignments.dart';
import 'budget.dart';
import 'budget_repository.dart';
import 'budget_scope.dart';

/// Puts items in the budgets that take them one by one, and takes them out.
final class BudgetAssignments {
  BudgetAssignments(BudgetRepository budgets)
      : _assignments = ItemAssignments(_BudgetsForChosenItems(budgets));

  final ItemAssignments<Budget, BudgetId> _assignments;

  /// The budgets that take items one by one, ordered by name.
  Future<List<Budget>> budgetsForChosenItems() => _assignments.holders();

  /// The budget that each of [itemIds] is in. Items in none are left out.
  Future<Map<ItemId, BudgetId>> budgetOfEach(Iterable<ItemId> itemIds) =>
      _assignments.holderOfEach(itemIds);

  /// Leaves each item in the budget given for it and in no other. An item
  /// given no budget is taken out of the one it was in.
  Future<void> assign(Map<ItemId, BudgetId?> budgetByItem) =>
      _assignments.assign(budgetByItem);
}

final class _BudgetsForChosenItems implements ItemHolders<Budget, BudgetId> {
  _BudgetsForChosenItems(this._budgets);

  final BudgetRepository _budgets;

  @override
  Future<List<Budget>> all() async => [
        for (final budget in await _budgets.all())
          if (budget.scope is ChosenItems) budget,
      ];

  @override
  BudgetId idOf(Budget holder) => holder.id;

  @override
  Set<ItemId> itemsOf(Budget holder) => switch (holder.scope) {
        ChosenItems(:final itemIds) => itemIds,
        AllSpending() || CategorySpending() => const {},
      };

  @override
  Future<void> saveWithItems(Budget holder, Set<ItemId> itemIds) =>
      _budgets.save(holder.withItems(itemIds));
}
