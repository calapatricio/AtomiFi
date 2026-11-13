import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// An account together with what it holds.
final class AccountSummary {
  const AccountSummary(this.account, this.balance);

  final Account account;
  final Money balance;
}

/// How the balance of an account changes when another one is removed.
typedef AffectedBalance = ({Account account, Money change});

/// The state and the actions of the accounts screen.
final class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel({
    required this._accounts,
    required this._ledger,
    required this._newId,
  });

  final AccountRepository _accounts;
  final Ledger _ledger;
  final String Function() _newId;

  List<AccountSummary> _summaries = const [];
  LedgerSnapshot _snapshot = LedgerSnapshot.empty;

  /// The accounts in use, ordered by name.
  List<AccountSummary> get active => [
    for (final summary in _summaries)
      if (!summary.account.isArchived) summary,
  ];

  /// The retired accounts, ordered by name.
  List<AccountSummary> get archived => [
    for (final summary in _summaries)
      if (summary.account.isArchived) summary,
  ];

  Future<void> load() async {
    final accounts = await _accounts.all();
    _snapshot = await _ledger.snapshot();
    final balances = Balances(_snapshot.records);
    _summaries = [
      for (final account in accounts)
        AccountSummary(account, balances.balanceOf(account)),
    ];
    notifyListeners();
  }

  Future<void> add({required String name, required String currencyCode}) =>
      _saveAndReload(
        Account(
          id: AccountId(_newId()),
          name: name.trim(),
          currency: Currency.iso(currencyCode.trim().toUpperCase()),
        ),
      );

  Future<void> archive(Account account) => _saveAndReload(account.archived());

  Future<void> restore(Account account) => _saveAndReload(account.restored());

  Future<void> remove(Account account) async {
    await _accounts.remove(account.id);
    await load();
  }

  /// What removing [account] would take with it.
  AccountRemoval removalOf(Account account) => AccountRemoval(
    account: account,
    transactions: _snapshot.transactions,
    transfers: _snapshot.transfers,
    revaluations: _snapshot.revaluations,
  );

  /// The other accounts whose balance [removal] would change, and by how
  /// much.
  List<AffectedBalance> balanceChangesOf(AccountRemoval removal) => [
    for (final summary in _summaries)
      if (summary.account.id != removal.account.id)
        (
          account: summary.account,
          change: removal.balanceChangeOf(summary.account),
        ),
  ].where((entry) => !entry.change.isZero).toList();

  Future<void> _saveAndReload(Account account) async {
    await _accounts.save(account);
    await load();
  }
}
