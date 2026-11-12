import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import 'account_currencies.dart';
import 'database.dart';

/// Keeps revaluations in the SQLite database.
final class DriftRevaluationRepository implements RevaluationRepository {
  DriftRevaluationRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Revaluation revaluation) => _database
      .into(_database.revaluations)
      .insertOnConflictUpdate(_toRow(revaluation));

  @override
  Future<void> remove(RevaluationId id) async {
    final statement = _database.delete(_database.revaluations)
      ..where((revaluations) => revaluations.id.equals(id.value));
    await statement.go();
  }

  @override
  Future<List<Revaluation>> all() async {
    final currencies = await currencyByAccountId(_database);
    final query = _database.select(_database.revaluations)
      ..orderBy([
        (revaluations) => OrderingTerm(expression: revaluations.statedAt),
      ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        Revaluation(
          id: RevaluationId(row.id),
          accountId: AccountId(row.accountId),
          dateTime: row.statedAt,
          value: Money(row.statedValue, currencies[row.accountId]!),
        ),
    ];
  }

  static RevaluationsCompanion _toRow(Revaluation revaluation) =>
      RevaluationsCompanion.insert(
        id: revaluation.id.value,
        accountId: revaluation.accountId.value,
        statedAt: revaluation.dateTime,
        statedValue: revaluation.value.minorUnits,
      );
}
