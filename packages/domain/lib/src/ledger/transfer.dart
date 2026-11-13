import '../ids.dart';
import '../money/money.dart';
import 'balance_change.dart';
import 'ledger_record.dart';

/// One side of a transfer: the record it leaves in one account.
final class TransferLeg {
  const TransferLeg({
    required this.accountId,
    required this.dateTime,
    required this.amount,
  });

  final AccountId accountId;
  final DateTime dateTime;

  /// What left or reached the account, as a positive amount in its currency.
  final Money amount;
}

/// Money moved between two of the user's own accounts.
///
/// It leaves one record in each account, each with its own date and amount.
/// It is neither spending nor income, so it never enters the statistics.
final class Transfer implements LedgerRecord {
  Transfer({
    required this.id,
    required this.outgoing,
    required this.incoming,
    this.note = '',
  }) {
    if (outgoing.accountId == incoming.accountId) {
      throw ArgumentError('A transfer needs two different accounts.');
    }
    if (!outgoing.amount.isPositive || !incoming.amount.isPositive) {
      throw ArgumentError('Transferred amounts must be positive.');
    }
  }

  final TransferId id;
  final String note;

  /// The record in the account the money left.
  final TransferLeg outgoing;

  /// The record in the account the money reached.
  final TransferLeg incoming;

  /// Whether the money left or reached the account with this id.
  bool involves(AccountId accountId) =>
      outgoing.accountId == accountId || incoming.accountId == accountId;

  @override
  List<BalanceChange> get balanceChanges => [
        Movement(outgoing.accountId, outgoing.dateTime, -outgoing.amount),
        Movement(incoming.accountId, incoming.dateTime, incoming.amount),
      ];
}
