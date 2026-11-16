import 'package:atomifi_domain/atomifi_domain.dart';

import 'cashew_backup.dart';
import 'cashew_budget_converter.dart' show appearanceOf;
import 'wallet_amounts.dart';

/// Turns the goals of a Cashew backup into ours.
///
/// Archived goals, loans and goals without a target are left out.
final class CashewGoalConverter {
  CashewGoalConverter(this._amounts);

  final WalletAmounts _amounts;

  /// The [goals] as ours. [goalByItem] tells which goal each imported item
  /// counted towards.
  List<Goal> convert(List<BackupGoal> goals, Map<ItemId, String> goalByItem) =>
      [
        for (final goal in goals)
          if (_isKept(goal)) _goalOf(goal, goalByItem),
      ];

  bool _isKept(BackupGoal goal) =>
      !goal.archived && !goal.isLoan && !_targetOf(goal).isZero;

  Goal _goalOf(BackupGoal goal, Map<ItemId, String> goalByItem) => Goal(
        id: GoalId(goal.id),
        name: goal.name,
        target: _targetOf(goal),
        kind: goal.income ? GoalKind.saving : GoalKind.spending,
        deadline: goal.end,
        appearance: appearanceOf(goal.colour, goal.iconName, goal.emoji),
        itemIds: {
          for (final MapEntry(key: itemId, value: goalId) in goalByItem.entries)
            if (goalId == goal.id) itemId,
        },
      );

  Money _targetOf(BackupGoal goal) => _amounts.of(goal.walletId, goal.amount);
}
