import '../ledger/ledger_record.dart';
import '../ledger/revaluation.dart';
import '../ledger/transaction.dart';
import '../ledger/transfer.dart';
import '../money/money.dart';
import 'account.dart';
import 'balances.dart';

/// What removing an account takes with it, to show before it is done.
final class AccountRemoval {
  AccountRemoval({
    required this.account,
    required Iterable<Transaction> transactions,
    required Iterable<Transfer> transfers,
    required Iterable<Revaluation> revaluations,
  })  : _everything = [...transactions, ...transfers, ...revaluations],
        transactions = [
          for (final transaction in transactions)
            if (transaction.accountId == account.id) transaction,
        ],
        transfers = [
          for (final transfer in transfers)
            if (transfer.involves(account.id)) transfer,
        ],
        revaluations = [
          for (final revaluation in revaluations)
            if (revaluation.accountId == account.id) revaluation,
        ];

  final Account account;
  final List<LedgerRecord> _everything;

  /// The transactions that go with the account.
  final List<Transaction> transactions;

  /// The transfers that go with the account, both sides of each.
  final List<Transfer> transfers;

  /// The revaluations that go with the account.
  final List<Revaluation> revaluations;

  int get recordCount =>
      transactions.length + transfers.length + revaluations.length;

  /// How much the balance of [other] changes once the transfers it shared
  /// with the removed account are gone.
  Money balanceChangeOf(Account other) =>
      Balances(_remaining).balanceOf(other) -
      Balances(_everything).balanceOf(other);

  List<LedgerRecord> get _remaining {
    final removed = <LedgerRecord>{
      ...transactions,
      ...transfers,
      ...revaluations,
    };
    return [
      for (final record in _everything)
        if (!removed.contains(record)) record,
    ];
  }
}
