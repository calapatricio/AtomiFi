import '../ids.dart';
import '../ledger/item_assignments.dart';
import 'goal.dart';
import 'goal_repository.dart';

/// Makes items count towards goals, and stops them from counting.
final class GoalAssignments {
  GoalAssignments(GoalRepository goals)
      : _assignments = ItemAssignments(_Goals(goals));

  final ItemAssignments<Goal, GoalId> _assignments;

  /// Every goal, ordered by name.
  Future<List<Goal>> goals() => _assignments.holders();

  /// The goal that each of [itemIds] counts towards. Items that count
  /// towards none are left out.
  Future<Map<ItemId, GoalId>> goalOfEach(Iterable<ItemId> itemIds) =>
      _assignments.holderOfEach(itemIds);

  /// Makes each item count towards the goal given for it and no other. An
  /// item given no goal stops counting towards the one it did.
  Future<void> assign(Map<ItemId, GoalId?> goalByItem) =>
      _assignments.assign(goalByItem);
}

final class _Goals implements ItemHolders<Goal, GoalId> {
  _Goals(this._goals);

  final GoalRepository _goals;

  @override
  Future<List<Goal>> all() => _goals.all();

  @override
  GoalId idOf(Goal holder) => holder.id;

  @override
  Set<ItemId> itemsOf(Goal holder) => holder.itemIds;

  @override
  Future<void> saveWithItems(Goal holder, Set<ItemId> itemIds) =>
      _goals.save(holder.withItems(itemIds));
}
