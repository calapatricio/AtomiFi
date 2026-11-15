import '../appearance.dart';
import '../ids.dart';
import '../money/money.dart';
import 'budget_period.dart';
import 'budget_scope.dart';

/// A limit on what I spend over a period, on everything or on a part of it.
final class Budget {
  Budget({
    required this.id,
    required this.name,
    required this.limit,
    required this.period,
    required this.scope,
    this.appearance = Appearance.none,
  }) {
    if (!limit.isPositive) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }
  }

  final BudgetId id;
  final String name;

  /// The most that should be spent in one period.
  final Money limit;
  final BudgetPeriod period;
  final BudgetScope scope;
  final Appearance appearance;

  /// This budget with one more item put in it.
  ///
  /// Only a budget for chosen items takes items one by one.
  Budget withItem(ItemId itemId) => switch (scope) {
        ChosenItems(:final itemIds) => Budget(
            id: id,
            name: name,
            limit: limit,
            period: period,
            scope: ChosenItems({...itemIds, itemId}),
            appearance: appearance,
          ),
        AllSpending() || CategorySpending() => throw StateError(
            'The budget "$name" does not take items one by one.',
          ),
      };
}
