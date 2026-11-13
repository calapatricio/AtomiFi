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
        'INSERT INTO wallets VALUES (?, ?, ?, ?, ?, ?)',
        ['imagin', 'Imagin', '0xff607d8b', 'bank.png', 'eur', 2],
      );

      final wallet = reader.read(database).wallets.single;

      expect(wallet.id, 'imagin');
      expect(wallet.name, 'Imagin');
      expect(wallet.colour, '0xff607d8b');
      expect(wallet.iconName, 'bank.png');
      expect(wallet.currencyCode, 'eur');
      expect(wallet.decimals, 2);
    });

    test('reads the categories', () {
      database
        ..execute(
          'INSERT INTO categories VALUES (?, ?, ?, ?, ?, ?, ?)',
          ['leisure', 'Ocio', '0xffff7043', 'smiley.png', null, 0, null],
        )
        ..execute(
          'INSERT INTO categories VALUES (?, ?, ?, ?, ?, ?, ?)',
          ['alcohol', 'Alcohol', null, null, '🍺', 0, 'leisure'],
        )
        ..execute(
          'INSERT INTO categories VALUES (?, ?, ?, ?, ?, ?, ?)',
          ['work', 'Trabajo', null, null, null, 1, null],
        );

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
        'INSERT INTO transactions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'tacos',
          'bizum',
          'Tacos',
          -26.5,
          'Moy - 14',
          'food',
          'dinner',
          'imagin',
          date.millisecondsSinceEpoch ~/ 1000,
          1,
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
    });

    test('reads a transaction without the optional fields', () {
      database.execute(
        'INSERT INTO transactions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ['gym', null, 'Gym', -39, '', 'sport', null, 'imagin', 0, 0],
      );

      final transaction = reader.read(database).transactions.single;

      expect(transaction.pairedId, isNull);
      expect(transaction.subcategoryId, isNull);
      expect(transaction.paid, isFalse);
    });

    test('rejects a database that is not laid out like a backup', () {
      final other = sqlite3.openInMemory()
        ..execute('CREATE TABLE wallets (id TEXT)');
      addTearDown(other.close);

      expect(() => reader.read(other), throwsFormatException);
    });
  });
}
