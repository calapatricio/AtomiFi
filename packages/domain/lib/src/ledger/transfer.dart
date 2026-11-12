import '../ids.dart';
import '../money/money.dart';
import 'balance_change.dart';
import 'ledger_record.dart';

/// Money moved between two of the user's own accounts.
///
/// It is neither spending nor income, so it never enters the statistics.
final class Transfer implements LedgerRecord {
  Transfer({
    required this.id,
    required this.dateTime,
    required this.fromAccountId,
    required this.toAccountId,
    required this.sent,
    Money? received,
    this.note = '',
  }) : received = received ?? sent {
    if (fromAccountId == toAccountId) {
      throw ArgumentError('A transfer needs two different accounts.');
    }
    if (!sent.isPositive || !this.received.isPositive) {
      throw ArgumentError('Transferred amounts must be positive.');
    }
  }

  final TransferId id;
  final DateTime dateTime;
  final AccountId fromAccountId;
  final AccountId toAccountId;
  final String note;

  /// What left the source account, in its currency.
  final Money sent;

  /// What reached the destination account, in its currency.
  final Money received;

  @override
  List<BalanceChange> get balanceChanges => [
        Movement(fromAccountId, dateTime, -sent),
        Movement(toAccountId, dateTime, received),
      ];
}
