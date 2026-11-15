import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import 'budget_mapping.dart';
import 'database.dart';

/// Keeps budgets, with what each covers, in the SQLite database.
final class DriftBudgetRepository implements BudgetRepository {
  DriftBudgetRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Budget budget) => _database.transaction(() async {
        await _database
            .into(_database.budgets)
            .insertOnConflictUpdate(budgetRowOf(budget));
        await _removeCoverageOf(budget.id);
        await _database.batch((batch) {
          batch.insertAll(
            _database.budgetCategories,
            budgetCategoryRowsOf(budget),
          );
          batch.insertAll(_database.budgetItems, budgetItemRowsOf(budget));
        });
      });

  @override
  Future<void> remove(BudgetId id) => _database.transaction(() async {
        await _removeCoverageOf(id);
        final budget = _database.delete(_database.budgets)
          ..where((budgets) => budgets.id.equals(id.value));
        await budget.go();
      });

  @override
  Future<List<Budget>> all() async {
    final categories =
        (await _database.select(_database.budgetCategories).get())
            .groupListsBy((row) => row.budgetId);
    final items = (await _database.select(_database.budgetItems).get())
        .groupListsBy((row) => row.budgetId);
    final query = _database.select(_database.budgets)
      ..orderBy([(budgets) => OrderingTerm(expression: budgets.name)]);
    return [
      for (final row in await query.get())
        budgetOf(
          row,
          categories: categories[row.id] ?? const [],
          items: items[row.id] ?? const [],
        ),
    ];
  }

  /// Deletes the rows that say which categories and items a budget covers.
  Future<void> _removeCoverageOf(BudgetId id) async {
    final categories = _database.delete(_database.budgetCategories)
      ..where((rows) => rows.budgetId.equals(id.value));
    await categories.go();
    final items = _database.delete(_database.budgetItems)
      ..where((rows) => rows.budgetId.equals(id.value));
    await items.go();
  }
}
