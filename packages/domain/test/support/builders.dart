import 'package:atomifi_domain/atomifi_domain.dart';

const me = Me();
const moy = Person('Moy');

var _sequence = 0;

Money eur(int cents) => Money(cents, Currency.eur);

Item mine(int cents, {String category = 'food', String? id, String? offsets}) =>
    shared({me: cents}, category: category, id: id, offsets: offsets);

Item shared(
  Map<Party, int> centsByParty, {
  String category = 'food',
  String? id,
  String? offsets,
}) =>
    Item(
      id: ItemId(id ?? 'item-${_sequence++}'),
      name: 'item',
      categoryId: CategoryId(category),
      shares: [
        for (final entry in centsByParty.entries)
          Share(entry.key, eur(entry.value)),
      ],
      offsets: offsets == null ? null : ItemId(offsets),
    );

Transaction on(DateTime dateTime, List<Item> items) => Transaction(
      id: TransactionId('transaction-${_sequence++}'),
      name: 'transaction',
      dateTime: dateTime,
      accountId: const AccountId('bank'),
      items: items,
    );
