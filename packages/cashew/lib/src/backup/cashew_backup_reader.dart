import 'package:sqlite3/common.dart';

import 'cashew_backup.dart';

/// Reads a Cashew backup, which is the SQLite database of the app.
final class CashewBackupReader {
  const CashewBackupReader();

  CashewBackup read(CommonDatabase database) {
    try {
      return CashewBackup(
        wallets: _wallets(database),
        categories: _categories(database),
        transactions: _transactions(database),
      );
    } on SqliteException catch (error) {
      throw FormatException(
        'This is not a Cashew backup that can be read: ${error.message}',
      );
    }
  }

  static List<BackupWallet> _wallets(CommonDatabase database) => [
        for (final row in database.select(
          'SELECT wallet_pk, name, colour, icon_name, currency, decimals '
          'FROM wallets',
        ))
          BackupWallet(
            id: row['wallet_pk'] as String,
            name: row['name'] as String,
            colour: row['colour'] as String?,
            iconName: row['icon_name'] as String?,
            currencyCode: row['currency'] as String?,
            decimals: row['decimals'] as int,
          ),
      ];

  static List<BackupCategory> _categories(CommonDatabase database) => [
        for (final row in database.select(
          'SELECT category_pk, name, colour, icon_name, emoji_icon_name, '
          'income, main_category_pk FROM categories',
        ))
          BackupCategory(
            id: row['category_pk'] as String,
            name: row['name'] as String,
            colour: row['colour'] as String?,
            iconName: row['icon_name'] as String?,
            emoji: row['emoji_icon_name'] as String?,
            income: row['income'] == 1,
            parentId: row['main_category_pk'] as String?,
          ),
      ];

  static List<BackupTransaction> _transactions(CommonDatabase database) => [
        for (final row in database.select(
          'SELECT transaction_pk, paired_transaction_fk, name, amount, note, '
          'category_fk, sub_category_fk, wallet_fk, date_created, paid '
          'FROM transactions',
        ))
          BackupTransaction(
            id: row['transaction_pk'] as String,
            pairedId: row['paired_transaction_fk'] as String?,
            name: row['name'] as String,
            amount: (row['amount'] as num).toDouble(),
            note: row['note'] as String,
            categoryId: row['category_fk'] as String,
            subcategoryId: row['sub_category_fk'] as String?,
            walletId: row['wallet_fk'] as String,
            date: _dateOf(row['date_created'] as int),
            paid: row['paid'] == 1,
          ),
      ];

  static DateTime _dateOf(int secondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
}
