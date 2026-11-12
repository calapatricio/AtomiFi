import '../ids.dart';
import '../money/money.dart';
import 'item.dart';

/// One record of a bank or cash account, made of one or more items.
final class Transaction {
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

  static Money _totalOf(Iterable<Item> items) {
    if (items.isEmpty) {
      throw ArgumentError('A transaction needs at least one item.');
    }
    return items.map((item) => item.price).reduce((sum, price) => sum + price);
  }
}
