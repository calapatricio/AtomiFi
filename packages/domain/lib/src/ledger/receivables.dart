import '../ids.dart';
import '../money/money.dart';
import 'item.dart';
import 'party.dart';
import 'transaction.dart';

/// What one [person] still owes for one item.
final class Receivable {
  const Receivable(this.itemId, this.person, this.outstanding);

  final ItemId itemId;
  final Person person;
  final Money outstanding;

  @override
  bool operator ==(Object other) =>
      other is Receivable &&
      other.itemId == itemId &&
      other.person == person &&
      other.outstanding == outstanding;

  @override
  int get hashCode => Object.hash(itemId, person, outstanding);

  @override
  String toString() => '$person owes $outstanding for $itemId';
}

/// Tracks what other people still owe for the items paid on their behalf.
final class Receivables {
  Receivables(Iterable<Transaction> ledger)
      : _items = [for (final transaction in ledger) ...transaction.items];

  final List<Item> _items;

  /// Everything that is still owed, one entry per item and person.
  List<Receivable> get open => [
        for (final item in _items.where(_isLent))
          for (final person in _debtorsOf(item))
            Receivable(item.id, person, _outstanding(item, person)),
      ].where((receivable) => !receivable.outstanding.isZero).toList();

  /// What [person] still owes for the item, as a positive amount.
  Money outstandingFor(ItemId itemId, Person person) {
    final item = _items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw ArgumentError.value(itemId, 'itemId', 'unknown item'),
    );
    return _outstanding(item, person);
  }

  Money _outstanding(Item item, Person person) {
    final repaid =
        _items.where((repayment) => repayment.offsets == item.id).fold(
              Money.zero(item.price.currency),
              (sum, repayment) => sum + repayment.amountFor(person),
            );
    return -(item.amountFor(person) + repaid);
  }

  static bool _isLent(Item item) =>
      item.offsets == null && item.othersAmount.isNegative;

  static Iterable<Person> _debtorsOf(Item item) =>
      item.shares.map((share) => share.party).whereType<Person>();
}
