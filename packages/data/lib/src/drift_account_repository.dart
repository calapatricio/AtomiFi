import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart';

import 'account_currencies.dart';
import 'database.dart';
import 'transaction_rows.dart';

/// Keeps accounts in the SQLite database.
final class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Account account) => _database
      .into(_database.accounts)
      .insertOnConflictUpdate(_toRow(account));

  @override
  Future<void> remove(AccountId id) => _database.transaction(() async {
        await _removeTransactionsOf(id);
        await _removeRevaluationsOf(id);
        await _removeTransfersOf(id);
        final account = _database.delete(_database.accounts)
          ..where((accounts) => accounts.id.equals(id.value));
        await account.go();
      });

  @override
  Future<List<Account>> all() async {
    final query = _database.select(_database.accounts)
      ..orderBy([(accounts) => OrderingTerm(expression: accounts.name)]);
    final rows = await query.get();
    return rows.map(_toAccount).toList();
  }

  Future<void> _removeTransactionsOf(AccountId id) async {
    final transactionsOfAccount = _database.select(_database.transactions)
      ..where((transactions) => transactions.accountId.equals(id.value));
    final transactionIds =
        await transactionsOfAccount.map((transaction) => transaction.id).get();
    await deleteItemsOfTransactions(_database, transactionIds);
    final transactions = _database.delete(_database.transactions)
      ..where((transactions) => transactions.accountId.equals(id.value));
    await transactions.go();
  }

  Future<void> _removeRevaluationsOf(AccountId id) async {
    final revaluations = _database.delete(_database.revaluations)
      ..where((revaluations) => revaluations.accountId.equals(id.value));
    await revaluations.go();
  }

  Future<void> _removeTransfersOf(AccountId id) async {
    final sent = _database.delete(_database.transfers)
      ..where((transfers) => transfers.fromAccountId.equals(id.value));
    await sent.go();
    final received = _database.delete(_database.transfers)
      ..where((transfers) => transfers.toAccountId.equals(id.value));
    await received.go();
  }

  static AccountsCompanion _toRow(Account account) => AccountsCompanion.insert(
        id: account.id.value,
        name: account.name,
        currencyCode: account.currency.code,
        currencyDecimals: account.currency.decimals,
        color: Value(account.appearance.color),
        iconName: Value(account.appearance.iconName),
        emoji: Value(account.appearance.emoji),
        archived: Value(account.isArchived),
      );

  static Account _toAccount(AccountRow row) => Account(
        id: AccountId(row.id),
        name: row.name,
        currency: row.currency,
        appearance: Appearance(
          color: row.color,
          iconName: row.iconName,
          emoji: row.emoji,
        ),
        isArchived: row.archived,
      );
}
