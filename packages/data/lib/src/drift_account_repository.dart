import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart';

import 'account_currencies.dart';
import 'database.dart';

/// Keeps accounts in the SQLite database.
final class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._database);

  final AtomiFiDatabase _database;

  @override
  Future<void> save(Account account) => _database
      .into(_database.accounts)
      .insertOnConflictUpdate(_toRow(account));

  @override
  Future<List<Account>> all() async {
    final query = _database.select(_database.accounts)
      ..orderBy([(accounts) => OrderingTerm(expression: accounts.name)]);
    final rows = await query.get();
    return rows.map(_toAccount).toList();
  }

  static AccountsCompanion _toRow(Account account) => AccountsCompanion.insert(
        id: account.id.value,
        name: account.name,
        currencyCode: account.currency.code,
        currencyDecimals: account.currency.decimals,
      );

  static Account _toAccount(AccountRow row) => Account(
        id: AccountId(row.id),
        name: row.name,
        currency: row.currency,
      );
}
