import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/backup.dart';

Money _eur(int cents) => Money(cents, Currency.eur);

ImportedLedger _convert(CashewBackup backup) =>
    const CashewBackupConverter(defaultCurrencyCode: 'EUR').convert(backup);

void main() {
  group('CashewBackupConverter accounts', () {
    test('keeps the id and name of each wallet', () {
      final account = _convert(backup()).accounts.single;

      expect(account.id, const AccountId('imagin'));
      expect(account.name, 'Imagin');
    });

    test('takes the currency and its decimals from the wallet', () {
      final ledger = _convert(
        backup(
          wallets: [
            wallet(currencyCode: 'eur'),
            wallet(id: 'crypto', currencyCode: 'btc', decimals: 8),
          ],
        ),
      );

      expect(ledger.accounts.map((account) => account.currency), const [
        Currency.eur,
        Currency('BTC', decimals: 8),
      ]);
    });

    test('uses the default currency for a wallet that names none', () {
      final ledger = _convert(backup(wallets: [wallet(currencyCode: null)]));

      expect(ledger.accounts.single.currency, Currency.eur);
    });

    test('keeps the color and icon of a wallet', () {
      final ledger = _convert(
        backup(
          wallets: [wallet(colour: '0xff607d8b', iconName: 'bank.png')],
        ),
      );

      expect(
        ledger.accounts.single.appearance,
        const Appearance(color: 0xFF607D8B, iconName: 'bank'),
      );
    });
  });

  group('CashewBackupConverter categories', () {
    test('takes the side of a category from the backup', () {
      final ledger = _convert(
        backup(
          categories: [
            category(id: 'food', income: false),
            category(id: 'work', name: 'Trabajo', income: true),
          ],
        ),
      );

      expect(ledger.categories.map((category) => category.side), [
        CategorySide.expense,
        CategorySide.income,
      ]);
    });

    test('lists a category before its subcategories', () {
      final ledger = _convert(
        backup(
          categories: [
            category(id: 'alcohol', name: 'Alcohol', parentId: 'leisure'),
            category(id: 'leisure', name: 'Ocio'),
          ],
        ),
      );

      final [leisure, alcohol] = ledger.categories;

      expect(leisure.id, const CategoryId('leisure'));
      expect(alcohol.parentId, leisure.id);
    });

    test('keeps the color, icon and emoji of a category', () {
      final ledger = _convert(
        backup(
          categories: [
            category(colour: '0xffffeb3b', iconName: 'tram.png', emoji: '🚋'),
          ],
        ),
      );

      expect(
        ledger.categories.single.appearance,
        const Appearance(color: 0xFFFFEB3B, iconName: 'tram', emoji: '🚋'),
      );
    });

    test('ignores a color it cannot read', () {
      final ledger = _convert(
        backup(categories: [category(colour: 'sky blue')]),
      );

      expect(ledger.categories.single.appearance, Appearance.none);
    });
  });

  group('CashewBackupConverter transactions', () {
    test('turns a paid transaction into one of ours, keeping its id', () {
      final ledger = _convert(
        backup(transactions: [transaction(note: 'Moy - 14')]),
      );

      final imported = ledger.transactions.single;

      expect(imported.id, const TransactionId('tacos'));
      expect(imported.name, 'Tacos');
      expect(imported.note, 'Moy - 14');
      expect(imported.dateTime, DateTime(2026, 11, 7, 22, 1, 26));
      expect(imported.accountId, const AccountId('imagin'));
      expect(imported.total, _eur(-2650));
    });

    test('gives it one item that is entirely mine', () {
      final item = _convert(backup(transactions: [transaction()]))
          .transactions
          .single
          .items
          .single;

      expect(item.name, 'Tacos');
      expect(item.ownAmount, _eur(-2650));
      expect(item.categoryId, const CategoryId('food'));
    });

    test('puts the item in the subcategory when there is one', () {
      final ledger = _convert(
        backup(
          categories: [
            category(),
            category(id: 'dinner', name: 'Cenas', parentId: 'food'),
          ],
          transactions: [transaction(subcategoryId: 'dinner')],
        ),
      );

      expect(
        ledger.transactions.single.items.single.categoryId,
        const CategoryId('dinner'),
      );
    });

    test('imports the same backup twice into the same ids', () {
      final source = backup(transactions: [transaction()]);

      final first = _convert(source).transactions.single;
      final second = _convert(source).transactions.single;

      expect(second.id, first.id);
      expect(second.items.single.id, first.items.single.id);
    });

    test('skips what was never paid or has no amount, and counts it', () {
      final ledger = _convert(
        backup(
          transactions: [
            transaction(id: 'gym', paid: false),
            transaction(id: 'nothing', amount: 0),
            transaction(id: 'dust', amount: 0.001),
            transaction(),
          ],
        ),
      );

      expect(ledger.transactions.single.id, const TransactionId('tacos'));
      expect(ledger.skippedRows, 3);
    });

    test('rejects a transaction of a wallet that is not in the backup', () {
      expect(
        () => _convert(backup(transactions: [transaction(walletId: 'gone')])),
        throwsFormatException,
      );
    });

    test('rejects a transaction of a category that is not in the backup', () {
      expect(
        () => _convert(backup(transactions: [transaction(categoryId: 'gone')])),
        throwsFormatException,
      );
    });
  });

  group('CashewBackupConverter transfers', () {
    final wallets = [wallet(), wallet(id: 'broker', name: 'Broker')];
    final sent = transaction(
      id: 'sent',
      name: 'Fund',
      note: 'Saldo transferido',
      amount: -20,
      date: DateTime(2026, 11, 13, 1, 35, 30),
      pairedId: 'received',
    );
    final received = transaction(
      id: 'received',
      name: 'Fund',
      amount: 20,
      date: DateTime(2026, 11, 13, 1, 35, 31),
      walletId: 'broker',
      pairedId: 'sent',
    );

    test('joins two paired transactions into one transfer', () {
      final ledger = _convert(
        backup(wallets: wallets, transactions: [sent, received]),
      );

      final transfer = ledger.transfers.single;

      expect(ledger.transactions, isEmpty);
      expect(transfer.id, const TransferId('sent'));
      expect(transfer.note, 'Saldo transferido');
      expect(transfer.outgoing.accountId, const AccountId('imagin'));
      expect(transfer.outgoing.dateTime, DateTime(2026, 11, 13, 1, 35, 30));
      expect(transfer.outgoing.amount, _eur(2000));
      expect(transfer.incoming.accountId, const AccountId('broker'));
      expect(transfer.incoming.dateTime, DateTime(2026, 11, 13, 1, 35, 31));
      expect(transfer.incoming.amount, _eur(2000));
    });

    test('joins them whichever comes first in the backup', () {
      final ledger = _convert(
        backup(wallets: wallets, transactions: [received, sent]),
      );

      expect(ledger.transfers.single.id, const TransferId('sent'));
      expect(ledger.transactions, isEmpty);
    });

    test('joins them when only one names the other', () {
      final ledger = _convert(
        backup(
          wallets: wallets,
          transactions: [
            sent,
            transaction(id: 'received', amount: 20, walletId: 'broker'),
          ],
        ),
      );

      expect(ledger.transfers, hasLength(1));
      expect(ledger.transactions, isEmpty);
    });

    test('leaves a transaction alone when its pair was never paid', () {
      final ledger = _convert(
        backup(
          wallets: wallets,
          transactions: [
            sent,
            transaction(
              id: 'received',
              amount: 20,
              walletId: 'broker',
              paid: false,
            ),
          ],
        ),
      );

      expect(ledger.transfers, isEmpty);
      expect(ledger.transactions.single.id, const TransactionId('sent'));
    });

    test('does not take two movements of one wallet for a transfer', () {
      final ledger = _convert(
        backup(
          wallets: wallets,
          transactions: [
            sent,
            transaction(id: 'received', amount: 20, pairedId: 'sent'),
          ],
        ),
      );

      expect(ledger.transfers, isEmpty);
      expect(ledger.transactions, hasLength(2));
    });

    test('does not take two movements of the same sign for a transfer', () {
      final ledger = _convert(
        backup(
          wallets: wallets,
          transactions: [
            sent,
            transaction(
              id: 'received',
              amount: -20,
              walletId: 'broker',
              pairedId: 'sent',
            ),
          ],
        ),
      );

      expect(ledger.transfers, isEmpty);
      expect(ledger.transactions, hasLength(2));
    });
  });
}
