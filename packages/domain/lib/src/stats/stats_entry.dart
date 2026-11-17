import '../ledger/transaction.dart';
import '../money/money.dart';

/// A transaction that counts in the statistics of a period, with what it
/// counts for.
final class StatsEntry {
  const StatsEntry({
    required this.transaction,
    required this.date,
    required this.amount,
  });

  final Transaction transaction;

  /// The moment it counts on. It is the date of an earlier transaction
  /// when its items offset items of that one.
  final DateTime date;

  /// My share of its items that count: negative for money spent.
  final Money amount;

  /// This entry counting for [more] on top of its amount.
  StatsEntry plus(Money more) =>
      StatsEntry(transaction: transaction, date: date, amount: amount + more);
}
