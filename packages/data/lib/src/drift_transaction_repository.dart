import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import 'account_currencies.dart';
import 'database.dart';
import 'transaction_mapping.dart';

/// Keeps transactions, with their items and shares, in the SQLite database.
final class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Transaction transaction) => _database.transaction(() async {
        await _database
            .into(_database.transactions)
            .insertOnConflictUpdate(transactionRowOf(transaction));
        await _removeItemsOf(transaction.id);
        await _database.batch((batch) {
          batch.insertAll(_database.items, itemRowsOf(transaction));
          batch.insertAll(_database.shares, shareRowsOf(transaction));
        });
      });

  @override
  Future<void> remove(TransactionId id) async {
    final statement = _database.delete(_database.transactions)
      ..where((transactions) => transactions.id.equals(id.value));
    await statement.go();
  }

  @override
  Future<List<Transaction>> all() async {
    final currencies = await currencyByAccountId(_database);
    final itemsByTransactionId = (await _itemRows())
        .groupListsBy((item) => item.transactionId);
    final sharesByItemId =
        (await _shareRows()).groupListsBy((share) => share.itemId);
    return [
      for (final row in await _transactionRows())
        transactionOf(
          row,
          items: itemsByTransactionId[row.id] ?? const [],
          sharesByItemId: sharesByItemId,
          currency: currencies[row.accountId]!,
        ),
    ];
  }

  Future<void> _removeItemsOf(TransactionId id) async {
    final statement = _database.delete(_database.items)
      ..where((items) => items.transactionId.equals(id.value));
    await statement.go();
  }

  Future<List<TransactionRow>> _transactionRows() {
    final query = _database.select(_database.transactions)
      ..orderBy([
        (transactions) => OrderingTerm(expression: transactions.happenedAt),
      ]);
    return query.get();
  }

  Future<List<ItemRow>> _itemRows() {
    final query = _database.select(_database.items)
      ..orderBy([(items) => OrderingTerm(expression: items.position)]);
    return query.get();
  }

  Future<List<ShareRow>> _shareRows() {
    final query = _database.select(_database.shares)
      ..orderBy([(shares) => OrderingTerm(expression: shares.position)]);
    return query.get();
  }
}
