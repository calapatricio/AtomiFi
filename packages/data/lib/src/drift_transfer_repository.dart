import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import 'account_currencies.dart';
import 'database.dart';

/// Keeps transfers in the SQLite database.
final class DriftTransferRepository implements TransferRepository {
  DriftTransferRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Transfer transfer) => _database
      .into(_database.transfers)
      .insertOnConflictUpdate(_toRow(transfer));

  @override
  Future<void> remove(TransferId id) async {
    final statement = _database.delete(_database.transfers)
      ..where((transfers) => transfers.id.equals(id.value));
    await statement.go();
  }

  @override
  Future<List<Transfer>> all() async {
    final currencies = await currencyByAccountId(_database);
    final query = _database.select(_database.transfers)
      ..orderBy([(transfers) => OrderingTerm(expression: transfers.sentAt)]);
    final rows = await query.get();
    return [for (final row in rows) _toTransfer(row, currencies)];
  }

  static TransfersCompanion _toRow(Transfer transfer) =>
      TransfersCompanion.insert(
        id: transfer.id.value,
        note: transfer.note,
        fromAccountId: transfer.outgoing.accountId.value,
        sentAt: transfer.outgoing.dateTime,
        sentAmount: transfer.outgoing.amount.minorUnits,
        toAccountId: transfer.incoming.accountId.value,
        receivedAt: transfer.incoming.dateTime,
        receivedAmount: transfer.incoming.amount.minorUnits,
      );

  static Transfer _toTransfer(
    TransferRow row,
    Map<String, Currency> currencies,
  ) =>
      Transfer(
        id: TransferId(row.id),
        note: row.note,
        outgoing: TransferLeg(
          accountId: AccountId(row.fromAccountId),
          dateTime: row.sentAt,
          amount: Money(row.sentAmount, currencies[row.fromAccountId]!),
        ),
        incoming: TransferLeg(
          accountId: AccountId(row.toAccountId),
          dateTime: row.receivedAt,
          amount: Money(row.receivedAmount, currencies[row.toAccountId]!),
        ),
      );
}
