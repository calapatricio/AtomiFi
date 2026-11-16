import '../appearance.dart';
import '../ids.dart';
import '../money/money.dart';

/// What a goal is reached by: putting money aside or spending it.
enum GoalKind { saving, spending }

/// An amount I want to reach, with the items that count towards it.
final class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.kind,
    this.deadline,
    this.appearance = Appearance.none,
    Set<ItemId> itemIds = const {},
  }) : itemIds = Set.unmodifiable(itemIds) {
    if (!target.isPositive) {
      throw ArgumentError.value(target, 'target', 'must be positive');
    }
  }

  final GoalId id;
  final String name;

  /// The amount to reach.
  final Money target;
  final GoalKind kind;

  /// The day I want to have reached it by, if I set one.
  final DateTime? deadline;
  final Appearance appearance;

  /// The items that count towards the goal, put in it one by one.
  final Set<ItemId> itemIds;

  /// This goal holding [itemIds] and no other items.
  Goal withItems(Set<ItemId> itemIds) => Goal(
        id: id,
        name: name,
        target: target,
        kind: kind,
        deadline: deadline,
        appearance: appearance,
        itemIds: itemIds,
      );
}
