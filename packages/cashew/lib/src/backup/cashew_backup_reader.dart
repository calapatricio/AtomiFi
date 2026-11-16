import 'dart:convert';

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
        budgets: _budgets(database),
        goals: _goals(database),
      );
    } on SqliteException catch (error) {
      throw FormatException(
        'This is not a Cashew backup that can be read: ${error.message}',
      );
    }
  }

  static List<BackupWallet> _wallets(CommonDatabase database) => [
        for (final row in database.select(
          'SELECT wallet_pk, name, colour, icon_name, emoji_icon_name, '
          'currency, decimals, archived FROM wallets',
        ))
          BackupWallet(
            id: row['wallet_pk'] as String,
            name: row['name'] as String,
            colour: row['colour'] as String?,
            iconName: row['icon_name'] as String?,
            emoji: row['emoji_icon_name'] as String?,
            archived: row['archived'] == 1,
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
          'category_fk, sub_category_fk, wallet_fk, date_created, paid, '
          'shared_reference_budget_pk, objective_fk FROM transactions',
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
            budgetId: row['shared_reference_budget_pk'] as String?,
            goalId: row['objective_fk'] as String?,
          ),
      ];

  static List<BackupBudget> _budgets(CommonDatabase database) => [
        for (final row in database.select(
          'SELECT budget_pk, name, colour, amount, start_date, end_date, '
          'period_length, reoccurrence, category_fks, category_fks_exclude, '
          'added_transactions_only, income, archived, wallet_fk FROM budgets',
        ))
          BackupBudget(
            id: row['budget_pk'] as String,
            name: row['name'] as String,
            colour: row['colour'] as String?,
            amount: (row['amount'] as num).toDouble(),
            start: _dateOf(row['start_date'] as int),
            end: _dateOf(row['end_date'] as int),
            periodLength: row['period_length'] as int,
            reoccurrence: _reoccurrenceOf(row['reoccurrence'] as int?),
            categoryIds: _idsIn(row['category_fks'] as String?),
            excludedCategoryIds: _idsIn(row['category_fks_exclude'] as String?),
            addedTransactionsOnly: row['added_transactions_only'] == 1,
            income: row['income'] == 1,
            archived: row['archived'] == 1,
            walletId: row['wallet_fk'] as String,
          ),
      ];

  static List<BackupGoal> _goals(CommonDatabase database) => [
        for (final row in database.select(
          'SELECT objective_pk, name, colour, icon_name, emoji_icon_name, '
          'type, amount, end_date, income, archived, wallet_fk '
          'FROM objectives',
        ))
          BackupGoal(
            id: row['objective_pk'] as String,
            name: row['name'] as String,
            colour: row['colour'] as String?,
            iconName: row['icon_name'] as String?,
            emoji: row['emoji_icon_name'] as String?,
            isLoan: row['type'] == _loanType,
            amount: (row['amount'] as num).toDouble(),
            end: _optionalDateOf(row['end_date'] as int?),
            income: row['income'] == 1,
            archived: row['archived'] == 1,
            walletId: row['wallet_fk'] as String,
          ),
      ];

  /// The number Cashew gives the goals that are long-term loans.
  static const _loanType = 1;

  static DateTime? _optionalDateOf(int? secondsSinceEpoch) =>
      secondsSinceEpoch == null ? null : _dateOf(secondsSinceEpoch);

  /// A budget without a known way of starting over is taken not to.
  static BackupReoccurrence _reoccurrenceOf(int? index) =>
      index == null || index < 0 || index >= BackupReoccurrence.values.length
          ? BackupReoccurrence.custom
          : BackupReoccurrence.values[index];

  /// The ids in a column that holds a JSON list of them, or holds nothing.
  static List<String> _idsIn(String? column) {
    if (column == null || column.isEmpty) return const [];
    try {
      final ids = jsonDecode(column);
      return ids is List ? ids.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  static DateTime _dateOf(int secondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
}
