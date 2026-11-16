import '../ledger/transaction.dart';
import '../money/currency_converter.dart';
import '../money/money.dart';
import '../money/rate_table.dart';
import 'goal.dart';

/// How far a goal has come.
final class GoalProgress {
  const GoalProgress({required this.goal, required this.reached});

  final Goal goal;

  /// What its items add up to so far: money put aside for a goal to save,
  /// money spent for a goal to spend. Only my own share of each item
  /// counts.
  final Money reached;

  Money get remaining => goal.target - reached;

  bool get isReached => !remaining.isPositive;
}

/// Works out how far goals have come.
final class GoalProgressCalculator {
  GoalProgressCalculator({CurrencyConverter? converter})
      : _converter = converter;

  final CurrencyConverter? _converter;

  GoalProgress progressOf(Goal goal, List<Transaction> ledger) {
    final currency = goal.target.currency;
    final converter = _converter ?? RateTable(base: currency);
    final movedByItems = [
      for (final transaction in ledger)
        for (final item in transaction.items)
          if (goal.itemIds.contains(item.id))
            converter.convert(item.ownAmount, currency),
    ].fold(Money.zero(currency), (sum, amount) => sum + amount);
    return GoalProgress(
      goal: goal,
      reached: goal.kind == GoalKind.saving ? movedByItems : -movedByItems,
    );
  }
}
