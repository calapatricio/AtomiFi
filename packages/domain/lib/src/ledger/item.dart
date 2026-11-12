import '../ids.dart';
import '../money/money.dart';
import 'party.dart';
import 'share.dart';

/// One line of a transaction: a price in a single category, divided into
/// the shares each party bears.
final class Item {
  Item({
    required this.id,
    required this.name,
    required this.categoryId,
    required Iterable<Share> shares,
    this.offsets,
  })  : shares = List.unmodifiable(shares),
        price = _priceOf(shares) {
    _requireValidShares();
  }

  /// An item borne entirely by the user.
  factory Item.mine({
    required ItemId id,
    required String name,
    required CategoryId categoryId,
    required Money price,
    ItemId? offsets,
  }) =>
      Item(
        id: id,
        name: name,
        categoryId: categoryId,
        shares: [Share(const Me(), price)],
        offsets: offsets,
      );

  /// An item divided evenly [among] parties.
  ///
  /// Units that cannot be divided evenly are borne by the user when the user
  /// takes part, otherwise by the first person.
  factory Item.split({
    required ItemId id,
    required String name,
    required CategoryId categoryId,
    required Money price,
    required Iterable<Party> among,
    ItemId? offsets,
  }) {
    final parties = [...among.whereType<Me>(), ...among.whereType<Person>()];
    final amounts = price.allocate(List.filled(parties.length, 1));
    return Item(
      id: id,
      name: name,
      categoryId: categoryId,
      shares: [
        for (var index = 0; index < parties.length; index++)
          if (!amounts[index].isZero) Share(parties[index], amounts[index]),
      ],
      offsets: offsets,
    );
  }

  final ItemId id;
  final String name;
  final CategoryId categoryId;
  final List<Share> shares;

  /// The sum of all [shares].
  final Money price;

  /// The earlier item this one pays back, refunds or settles, if any.
  final ItemId? offsets;

  Money amountFor(Party party) => shares
      .where((share) => share.party == party)
      .fold(Money.zero(price.currency), (sum, share) => sum + share.amount);

  /// The part of the price that is the user's own spending or income.
  Money get ownAmount => amountFor(const Me());

  /// The part of the price borne by other people.
  Money get othersAmount => price - ownAmount;

  void _requireValidShares() {
    if (shares.any((share) => share.amount.isZero)) {
      throw ArgumentError('A share cannot be zero.');
    }
    final parties = {for (final share in shares) share.party};
    if (parties.length != shares.length) {
      throw ArgumentError('A party can hold only one share of an item.');
    }
    final outflows = shares.where((share) => share.amount.isNegative).length;
    if (outflows != 0 && outflows != shares.length) {
      throw ArgumentError('All shares of an item must have the same sign.');
    }
  }

  static Money _priceOf(Iterable<Share> shares) {
    if (shares.isEmpty) {
      throw ArgumentError('An item needs at least one share.');
    }
    return shares.map((share) => share.amount).reduce((sum, amount) => sum + amount);
  }
}
