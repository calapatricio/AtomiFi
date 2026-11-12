import '../ids.dart';
import '../money/money.dart';
import 'balance_change.dart';
import 'ledger_record.dart';

/// What an account was worth at one moment, as stated by the user.
///
/// The difference with the balance until then is what the market did. It is
/// neither spending nor income, so it never enters the statistics.
final class Revaluation implements LedgerRecord {
  const Revaluation({
    required this.id,
    required this.accountId,
    required this.dateTime,
    required this.value,
  });

  final RevaluationId id;
  final AccountId accountId;
  final DateTime dateTime;
  final Money value;

  @override
  List<BalanceChange> get balanceChanges =>
      [Valuation(accountId, dateTime, value)];
}
