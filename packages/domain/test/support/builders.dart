import 'package:atomifi_domain/atomifi_domain.dart';

const me = Me();
const moy = Person('Moy');

const bank = Account(
  id: AccountId('bank'),
  name: 'Bank',
  currency: Currency.eur,
);
const savings = Account(
  id: AccountId('savings'),
  name: 'Savings',
  currency: Currency.eur,
);
const broker = Account(
  id: AccountId('broker'),
  name: 'Broker',
  currency: Currency.usd,
);

var _sequence = 0;

Money eur(int cents) => Money(cents, Currency.eur);

Money usd(int cents) => Money(cents, Currency.usd);

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

Transaction on(
  DateTime dateTime,
  List<Item> items, {
  Account account = bank,
}) =>
    Transaction(
      id: TransactionId('transaction-${_sequence++}'),
      name: 'transaction',
      dateTime: dateTime,
      accountId: account.id,
      items: items,
    );

Transfer moved(
  Money sent, {
  required Account from,
  required Account to,
  required DateTime on,
  DateTime? arriving,
  Money? received,
}) =>
    Transfer(
      id: TransferId('transfer-${_sequence++}'),
      outgoing: TransferLeg(accountId: from.id, dateTime: on, amount: sent),
      incoming: TransferLeg(
        accountId: to.id,
        dateTime: arriving ?? on,
        amount: received ?? sent,
      ),
    );
