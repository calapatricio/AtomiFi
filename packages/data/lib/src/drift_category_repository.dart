import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart';

import 'database.dart';

/// Keeps categories in the SQLite database.
final class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Category category) => _database
      .into(_database.categories)
      .insertOnConflictUpdate(_toRow(category));

  @override
  Future<List<Category>> all() async {
    final query = _database.select(_database.categories)
      ..orderBy([(categories) => OrderingTerm(expression: categories.name)]);
    final rows = await query.get();
    return rows.map(_toCategory).toList();
  }

  static CategoriesCompanion _toRow(Category category) =>
      CategoriesCompanion.insert(
        id: category.id.value,
        name: category.name,
        side: category.side,
        parentId: Value(category.parentId?.value),
        color: Value(category.appearance.color),
        iconName: Value(category.appearance.iconName),
        emoji: Value(category.appearance.emoji),
      );

  static Category _toCategory(CategoryRow row) {
    final parentId = row.parentId;
    return Category(
      id: CategoryId(row.id),
      name: row.name,
      side: row.side,
      parentId: parentId == null ? null : CategoryId(parentId),
      appearance: Appearance(
        color: row.color,
        iconName: row.iconName,
        emoji: row.emoji,
      ),
    );
  }
}
