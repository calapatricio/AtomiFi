import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;

import 'database.dart';

/// Keeps goals, with the items that count towards each, in the SQLite
/// database.
final class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Goal goal) => _database.transaction(() async {
        await _database
            .into(_database.goals)
            .insertOnConflictUpdate(_toRow(goal));
        await _removeItemsOf(goal.id);
        await _database.batch((batch) {
          batch.insertAll(_database.goalItems, [
            for (final itemId in goal.itemIds)
              GoalItemsCompanion.insert(
                goalId: goal.id.value,
                itemId: itemId.value,
              ),
          ]);
        });
      });

  @override
  Future<void> remove(GoalId id) => _database.transaction(() async {
        await _removeItemsOf(id);
        final goal = _database.delete(_database.goals)
          ..where((goals) => goals.id.equals(id.value));
        await goal.go();
      });

  @override
  Future<List<Goal>> all() async {
    final items = (await _database.select(_database.goalItems).get())
        .groupListsBy((row) => row.goalId);
    final query = _database.select(_database.goals)
      ..orderBy([(goals) => OrderingTerm(expression: goals.name)]);
    return [
      for (final row in await query.get())
        _toGoal(row, items[row.id] ?? const []),
    ];
  }

  Future<void> _removeItemsOf(GoalId id) async {
    final items = _database.delete(_database.goalItems)
      ..where((rows) => rows.goalId.equals(id.value));
    await items.go();
  }

  static GoalsCompanion _toRow(Goal goal) => GoalsCompanion.insert(
        id: goal.id.value,
        name: goal.name,
        targetAmount: goal.target.minorUnits,
        currencyCode: goal.target.currency.code,
        currencyDecimals: goal.target.currency.decimals,
        kind: goal.kind,
        deadline: Value(goal.deadline),
        color: Value(goal.appearance.color),
        iconName: Value(goal.appearance.iconName),
        emoji: Value(goal.appearance.emoji),
      );

  static Goal _toGoal(GoalRow row, List<GoalItemRow> items) => Goal(
        id: GoalId(row.id),
        name: row.name,
        target: Money(
          row.targetAmount,
          Currency(row.currencyCode, decimals: row.currencyDecimals),
        ),
        kind: row.kind,
        deadline: row.deadline,
        appearance: Appearance(
          color: row.color,
          iconName: row.iconName,
          emoji: row.emoji,
        ),
        itemIds: {for (final item in items) ItemId(item.itemId)},
      );
}
