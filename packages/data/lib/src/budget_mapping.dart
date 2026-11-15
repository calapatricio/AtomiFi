import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'database.dart';
import 'tables.dart';

BudgetsCompanion budgetRowOf(Budget budget) {
  final period = budget.period;
  final recurrence = period is RecurringPeriod ? period.recurrence : null;
  final range = period is FixedPeriod ? period.range : null;
  return BudgetsCompanion.insert(
    id: budget.id.value,
    name: budget.name,
    limitAmount: budget.limit.minorUnits,
    currencyCode: budget.limit.currency.code,
    currencyDecimals: budget.limit.currency.decimals,
    color: Value(budget.appearance.color),
    iconName: Value(budget.appearance.iconName),
    emoji: Value(budget.appearance.emoji),
    scopeKind: _kindOf(budget.scope),
    recurrenceEvery: Value(recurrence?.every),
    recurrenceUnit: Value(recurrence?.unit),
    recurrenceAnchor: Value(recurrence?.anchor),
    fixedStart: Value(range?.start),
    fixedEnd: Value(range?.end),
  );
}

List<BudgetCategoriesCompanion> budgetCategoryRowsOf(Budget budget) {
  final scope = budget.scope;
  return [
    if (scope is CategorySpending)
      for (final categoryId in scope.categoryIds)
        BudgetCategoriesCompanion.insert(
          budgetId: budget.id.value,
          categoryId: categoryId.value,
        ),
  ];
}

List<BudgetItemsCompanion> budgetItemRowsOf(Budget budget) {
  final scope = budget.scope;
  return [
    if (scope is ChosenItems)
      for (final itemId in scope.itemIds)
        BudgetItemsCompanion.insert(
          budgetId: budget.id.value,
          itemId: itemId.value,
        ),
  ];
}

/// Rebuilds a budget from its row and the rows of what it covers.
Budget budgetOf(
  BudgetRow row, {
  required List<BudgetCategoryRow> categories,
  required List<BudgetItemRow> items,
}) =>
    Budget(
      id: BudgetId(row.id),
      name: row.name,
      limit: Money(
        row.limitAmount,
        Currency(row.currencyCode, decimals: row.currencyDecimals),
      ),
      period: _periodOf(row),
      scope: switch (row.scopeKind) {
        BudgetScopeKind.allSpending => const AllSpending(),
        BudgetScopeKind.categories => CategorySpending({
            for (final category in categories) CategoryId(category.categoryId),
          }),
        BudgetScopeKind.chosenItems => ChosenItems({
            for (final item in items) ItemId(item.itemId),
          }),
      },
      appearance: Appearance(
        color: row.color,
        iconName: row.iconName,
        emoji: row.emoji,
      ),
    );

BudgetScopeKind _kindOf(BudgetScope scope) => switch (scope) {
      AllSpending() => BudgetScopeKind.allSpending,
      CategorySpending() => BudgetScopeKind.categories,
      ChosenItems() => BudgetScopeKind.chosenItems,
    };

BudgetPeriod _periodOf(BudgetRow row) {
  final every = row.recurrenceEvery;
  final unit = row.recurrenceUnit;
  final anchor = row.recurrenceAnchor;
  if (every != null && unit != null && anchor != null) {
    return RecurringPeriod(Recurrence(every: every, unit: unit, anchor: anchor));
  }
  return FixedPeriod(DateRange(row.fixedStart!, row.fixedEnd!));
}
