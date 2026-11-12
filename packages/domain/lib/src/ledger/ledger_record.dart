import 'balance_change.dart';

/// Anything recorded in the ledger that changes the balance of an account.
abstract interface class LedgerRecord {
  List<BalanceChange> get balanceChanges;
}
