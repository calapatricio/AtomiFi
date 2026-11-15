import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'support/backup.dart';

void main() {
  group('CashewBackupReader', () {
    const reader = CashewBackupReader();
    late Database database;

    setUp(() => database = openEmptyBackup());

    tearDown(() => database.close());

    test('reads the wallets', () {
      database.execute(
        'INSERT INTO wallets (wallet_pk, name, colour, icon_name, '
        'emoji_icon_name, currency, decimals, archived) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        ['imagin', 'Imagin', '0xff607d8b', 'bank.png', '🏦', 'eur', 2, 1],
      );

      final wallet = reader.read(database).wallets.single;

      expect(wallet.id, 'imagin');
      expect(wallet.name, 'Imagin');
      expect(wallet.colour, '0xff607d8b');
      expect(wallet.iconName, 'bank.png');
      expect(wallet.emoji, '🏦');
      expect(wallet.currencyCode, 'eur');
      expect(wallet.decimals, 2);
      expect(wallet.archived, isTrue);
    });

    test('reads the categories', () {
      const insert = 'INSERT INTO categories (category_pk, name, colour, '
          'icon_name, emoji_icon_name, income, main_category_pk) '
          'VALUES (?, ?, ?, ?, ?, ?, ?)';
      database
        ..execute(
          insert,
          ['leisure', 'Ocio', '0xffff7043', 'smiley.png', null, 0, null],
        )
        ..execute(
            insert, ['alcohol', 'Alcohol', null, null, '🍺', 0, 'leisure'])
        ..execute(insert, ['work', 'Trabajo', null, null, null, 1, null]);

      final [leisure, alcohol, work] = reader.read(database).categories;

      expect(leisure.id, 'leisure');
      expect(leisure.name, 'Ocio');
      expect(leisure.colour, '0xffff7043');
      expect(leisure.iconName, 'smiley.png');
      expect(leisure.income, isFalse);
      expect(leisure.parentId, isNull);
      expect(alcohol.emoji, '🍺');
      expect(alcohol.parentId, 'leisure');
      expect(work.income, isTrue);
    });

    test('reads the transactions', () {
      final date = DateTime(2026, 11, 7, 22, 1, 26);
      database.execute(
        'INSERT INTO transactions (transaction_pk, paired_transaction_fk, '
        'name, amount, note, category_fk, sub_category_fk, wallet_fk, '
        'date_created, paid, shared_reference_budget_pk) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'tacos',
          'bizum',
          'Tacos',
          -26.5,
          'Moy - 14',
          'food',
          'dinner',
          'imagin',
          secondsOf(date),
          1,
          'holidays',
        ],
      );

      final transaction = reader.read(database).transactions.single;

      expect(transaction.id, 'tacos');
      expect(transaction.pairedId, 'bizum');
      expect(transaction.name, 'Tacos');
      expect(transaction.amount, -26.5);
      expect(transaction.note, 'Moy - 14');
      expect(transaction.categoryId, 'food');
      expect(transaction.subcategoryId, 'dinner');
      expect(transaction.walletId, 'imagin');
      expect(transaction.date, date);
      expect(transaction.paid, isTrue);
      expect(transaction.budgetId, 'holidays');
    });

    test('reads a transaction without the optional fields', () {
      database.execute(
        'INSERT INTO transactions (transaction_pk, name, amount, note, '
        'category_fk, wallet_fk, date_created) VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['gym', 'Gym', -39, '', 'sport', 'imagin', 0],
      );

      final transaction = reader.read(database).transactions.single;

      expect(transaction.pairedId, isNull);
      expect(transaction.subcategoryId, isNull);
      expect(transaction.budgetId, isNull);
      expect(transaction.paid, isFalse);
    });

    test('reads the budgets', () {
      database.execute(
        'INSERT INTO budgets (budget_pk, name, colour, amount, start_date, '
        'end_date, period_length, reoccurrence, category_fks, '
        'category_fks_exclude, added_transactions_only, income, archived, '
        'wallet_fk) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'dca',
          'Inversiones',
          '0xff4caf50',
          100,
          secondsOf(DateTime(2026, 11, 13)),
          secondsOf(DateTime(2026, 11, 27)),
          2,
          2,
          '["funds","etf"]',
          '["casino"]',
          1,
          0,
          1,
          'broker',
        ],
      );

      final budget = reader.read(database).budgets.single;

      expect(budget.id, 'dca');
      expect(budget.name, 'Inversiones');
      expect(budget.colour, '0xff4caf50');
      expect(budget.amount, 100);
      expect(budget.start, DateTime(2026, 11, 13));
      expect(budget.end, DateTime(2026, 11, 27));
      expect(budget.periodLength, 2);
      expect(budget.reoccurrence, BackupReoccurrence.weekly);
      expect(budget.categoryIds, ['funds', 'etf']);
      expect(budget.excludedCategoryIds, ['casino']);
      expect(budget.addedTransactionsOnly, isTrue);
      expect(budget.income, isFalse);
      expect(budget.archived, isTrue);
      expect(budget.walletId, 'broker');
    });

    test('reads a budget that names no categories and does not repeat', () {
      database.execute(
        'INSERT INTO budgets (budget_pk, name, amount, start_date, end_date, '
        'period_length) VALUES (?, ?, ?, ?, ?, ?)',
        ['trip', 'Viaje', 500, 0, 0, 1],
      );

      final budget = reader.read(database).budgets.single;

      expect(budget.reoccurrence, BackupReoccurrence.custom);
      expect(budget.categoryIds, isEmpty);
      expect(budget.excludedCategoryIds, isEmpty);
    });

    test('rejects a database that is not laid out like a backup', () {
      final other = sqlite3.openInMemory()
        ..execute('CREATE TABLE wallets (id TEXT)');
      addTearDown(other.close);

      expect(() => reader.read(other), throwsFormatException);
    });
  });
}
