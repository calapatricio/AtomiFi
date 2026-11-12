import '../ids.dart';
import '../money/money.dart';
import 'balance_change.dart';
import 'item.dart';
import 'ledger_record.dart';

/// One record of a bank or cash account, made of one or more items.
final class Transaction implements LedgerRecord {
  Transaction({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.accountId,
    required Iterable<Item> items,
    this.note = '',
  })  : items = List.unmodifiable(items),
        total = _totalOf(items);

  final TransactionId id;
  final String name;
  final String note;
  final DateTime dateTime;
  final AccountId accountId;
  final List<Item> items;

  /// The amount that left or entered the account: the sum of all [items].
  final Money total;

  @override
  List<BalanceChange> get balanceChanges =>
      [Movement(accountId, dateTime, total)];

  static Money _totalOf(Iterable<Item> items) {
    if (items.isEmpty) {
      throw ArgumentError('A transaction needs at least one item.');
    }
    return items.map((item) => item.price).reduce((sum, price) => sum + price);
  }
}
