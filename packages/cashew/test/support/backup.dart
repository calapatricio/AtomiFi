import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:sqlite3/sqlite3.dart';

/// An in-memory database laid out like the part of a Cashew backup that the
/// import reads.
Database openEmptyBackup() => sqlite3.openInMemory()
  ..execute('''
    CREATE TABLE wallets (
      wallet_pk TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      colour TEXT,
      icon_name TEXT,
      emoji_icon_name TEXT,
      currency TEXT,
      decimals INTEGER NOT NULL DEFAULT 2,
      archived INTEGER NOT NULL DEFAULT 0
    )''')
  ..execute('''
    CREATE TABLE categories (
      category_pk TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      colour TEXT,
      icon_name TEXT,
      emoji_icon_name TEXT,
      income INTEGER NOT NULL DEFAULT 0,
      main_category_pk TEXT
    )''')
  ..execute('''
    CREATE TABLE transactions (
      transaction_pk TEXT NOT NULL PRIMARY KEY,
      paired_transaction_fk TEXT,
      name TEXT NOT NULL,
      amount REAL NOT NULL,
      note TEXT NOT NULL,
      category_fk TEXT NOT NULL,
      sub_category_fk TEXT,
      wallet_fk TEXT NOT NULL,
      date_created INTEGER NOT NULL,
      paid INTEGER NOT NULL DEFAULT 0,
      shared_reference_budget_pk TEXT,
      objective_fk TEXT
    )''')
  ..execute('''
    CREATE TABLE budgets (
      budget_pk TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      colour TEXT,
      amount REAL NOT NULL,
      start_date INTEGER NOT NULL,
      end_date INTEGER NOT NULL,
      period_length INTEGER NOT NULL,
      reoccurrence INTEGER,
      category_fks TEXT,
      category_fks_exclude TEXT,
      added_transactions_only INTEGER NOT NULL DEFAULT 0,
      income INTEGER NOT NULL DEFAULT 0,
      archived INTEGER NOT NULL DEFAULT 0,
      wallet_fk TEXT NOT NULL DEFAULT '0'
    )''')
  ..execute('''
    CREATE TABLE objectives (
      objective_pk TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      colour TEXT,
      icon_name TEXT,
      emoji_icon_name TEXT,
      type INTEGER NOT NULL DEFAULT 0,
      amount REAL NOT NULL,
      end_date INTEGER,
      income INTEGER NOT NULL DEFAULT 0,
      archived INTEGER NOT NULL DEFAULT 0,
      wallet_fk TEXT NOT NULL DEFAULT '0'
    )''');

/// Seconds since the epoch, the way the backup keeps moments.
int secondsOf(DateTime moment) => moment.millisecondsSinceEpoch ~/ 1000;

BackupWallet wallet({
  String id = 'imagin',
  String name = 'Imagin',
  String? currencyCode = 'eur',
  int decimals = 2,
  String? colour,
  String? iconName,
  String? emoji,
  bool archived = false,
}) =>
    BackupWallet(
      id: id,
      name: name,
      currencyCode: currencyCode,
      decimals: decimals,
      colour: colour,
      iconName: iconName,
      emoji: emoji,
      archived: archived,
    );

BackupCategory category({
  String id = 'food',
  String name = 'Comida',
  bool income = false,
  String? parentId,
  String? colour,
  String? iconName,
  String? emoji,
}) =>
    BackupCategory(
      id: id,
      name: name,
      income: income,
      parentId: parentId,
      colour: colour,
      iconName: iconName,
      emoji: emoji,
    );

BackupTransaction transaction({
  String id = 'tacos',
  String name = 'Tacos',
  String note = '',
  double amount = -26.5,
  DateTime? date,
  String walletId = 'imagin',
  String categoryId = 'food',
  String? subcategoryId,
  bool paid = true,
  String? pairedId,
  String? budgetId,
  String? goalId,
}) =>
    BackupTransaction(
      id: id,
      name: name,
      note: note,
      amount: amount,
      date: date ?? DateTime(2026, 11, 7, 22, 1, 26),
      walletId: walletId,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      paid: paid,
      pairedId: pairedId,
      budgetId: budgetId,
      goalId: goalId,
    );

BackupBudget budget({
  String id = 'monthly',
  String name = 'Mensual',
  double amount = 1200,
  DateTime? start,
  DateTime? end,
  int periodLength = 1,
  BackupReoccurrence reoccurrence = BackupReoccurrence.monthly,
  List<String> categoryIds = const [],
  List<String> excludedCategoryIds = const [],
  bool addedTransactionsOnly = false,
  bool income = false,
  bool archived = false,
  String walletId = 'imagin',
  String? colour,
}) =>
    BackupBudget(
      id: id,
      name: name,
      amount: amount,
      start: start ?? DateTime(2026, 6, 1),
      end: end ?? DateTime(2026, 7, 1),
      periodLength: periodLength,
      reoccurrence: reoccurrence,
      categoryIds: categoryIds,
      excludedCategoryIds: excludedCategoryIds,
      addedTransactionsOnly: addedTransactionsOnly,
      income: income,
      archived: archived,
      walletId: walletId,
      colour: colour,
    );

CashewBackup backup({
  List<BackupWallet>? wallets,
  List<BackupCategory>? categories,
  List<BackupTransaction> transactions = const [],
  List<BackupBudget> budgets = const [],
  List<BackupGoal> goals = const [],
}) =>
    CashewBackup(
      wallets: wallets ?? [wallet()],
      categories: categories ?? [category()],
      transactions: transactions,
      budgets: budgets,
      goals: goals,
    );

BackupGoal goal({
  String id = 'pizza',
  String name = 'Objetivo Pizza',
  double amount = 500,
  bool income = true,
  DateTime? end,
  bool isLoan = false,
  bool archived = false,
  String walletId = 'imagin',
  String? colour,
  String? iconName,
  String? emoji,
}) =>
    BackupGoal(
      id: id,
      name: name,
      amount: amount,
      income: income,
      end: end,
      isLoan: isLoan,
      archived: archived,
      walletId: walletId,
      colour: colour,
      iconName: iconName,
      emoji: emoji,
    );
