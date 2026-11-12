import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

Transaction _shopping({List<Item>? items}) => Transaction(
      id: const TransactionId('shopping'),
      name: 'Supermarket',
      note: 'For the party',
      dateTime: DateTime(2026, 11, 6, 23, 31),
      accountId: bank.id,
      items: items ??
          [
            Item(
              id: const ItemId('rum'),
              name: 'Rum',
              categoryId: alcohol.id,
              shares: [
                Share(const Me(), eur(-400)),
                Share(moy, eur(-800)),
              ],
            ),
            Item.mine(
              id: const ItemId('bananas'),
              name: 'Bananas',
              categoryId: food.id,
              price: eur(-180),
            ),
          ],
    );

Transaction _repayment() => Transaction(
      id: const TransactionId('bizum'),
      name: 'Bizum Moy',
      dateTime: DateTime(2026, 11, 8, 11, 56),
      accountId: bank.id,
      items: [
        Item(
          id: const ItemId('rum-back'),
          name: 'Rum',
          categoryId: alcohol.id,
          shares: [Share(moy, eur(800))],
          offsets: const ItemId('rum'),
        ),
      ],
    );

void main() {
  late AtomiFiDatabase database;
  late TransactionRepository transactions;

  setUp(() async {
    database = await openSeededDatabase();
    transactions = DriftTransactionRepository(database);
  });

  tearDown(() => database.close());

  group('DriftTransactionRepository', () {
    test('starts without transactions', () async {
      expect(await transactions.all(), isEmpty);
    });

    test('restores a transaction as it was saved', () async {
      await transactions.save(_shopping());

      final restored = (await transactions.all()).single;

      expect(restored.id, const TransactionId('shopping'));
      expect(restored.name, 'Supermarket');
      expect(restored.note, 'For the party');
      expect(restored.dateTime, DateTime(2026, 11, 6, 23, 31));
      expect(restored.accountId, bank.id);
      expect(restored.total, eur(-1380));
    });

    test('restores the items in their order, each with its category', () async {
      await transactions.save(_shopping());

      final items = (await transactions.all()).single.items;

      expect(items.map((item) => item.id), const [
        ItemId('rum'),
        ItemId('bananas'),
      ]);
      expect(items.map((item) => item.name), ['Rum', 'Bananas']);
      expect(items.map((item) => item.categoryId), [alcohol.id, food.id]);
    });

    test('restores who bears each share of an item', () async {
      await transactions.save(_shopping());

      final rum = (await transactions.all()).single.items.first;

      expect(rum.shares, [
        Share(const Me(), eur(-400)),
        Share(moy, eur(-800)),
      ]);
    });

    test('restores the item a repayment offsets', () async {
      await transactions.save(_shopping());
      await transactions.save(_repayment());

      final restored = await transactions.all();

      expect(restored.last.items.single.offsets, const ItemId('rum'));
      expect(restored.first.items.first.offsets, isNull);
    });

    test('restores amounts in the currency of the account', () async {
      await transactions.save(
        Transaction(
          id: const TransactionId('dividend'),
          name: 'Dividend',
          dateTime: DateTime(2026, 11, 2),
          accountId: broker.id,
          items: [
            Item.mine(
              id: const ItemId('dividend'),
              name: 'Dividend',
              categoryId: salary.id,
              price: usd(1250),
            ),
          ],
        ),
      );

      expect((await transactions.all()).single.total, usd(1250));
    });

    test('returns the transactions oldest first', () async {
      await transactions.save(_repayment());
      await transactions.save(_shopping());

      final restored = await transactions.all();

      expect(restored.map((transaction) => transaction.id), const [
        TransactionId('shopping'),
        TransactionId('bizum'),
      ]);
    });

    test('saving a transaction again replaces its items', () async {
      await transactions.save(_shopping());
      await transactions.save(
        _shopping(
          items: [
            Item.mine(
              id: const ItemId('rum'),
              name: 'Rum',
              categoryId: alcohol.id,
              price: eur(-1200),
            ),
          ],
        ),
      );

      final restored = (await transactions.all()).single;

      expect(restored.items.single.shares, [Share(const Me(), eur(-1200))]);
      expect(await database.select(database.shares).get(), hasLength(1));
    });

    test('removing a transaction removes its items and shares', () async {
      await transactions.save(_shopping());

      await transactions.remove(const TransactionId('shopping'));

      expect(await transactions.all(), isEmpty);
      expect(await database.select(database.items).get(), isEmpty);
      expect(await database.select(database.shares).get(), isEmpty);
    });
  });
}
