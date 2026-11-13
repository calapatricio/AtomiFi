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
      currency TEXT,
      decimals INTEGER NOT NULL DEFAULT 2
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
      paid INTEGER NOT NULL DEFAULT 0
    )''');

BackupWallet wallet({
  String id = 'imagin',
  String name = 'Imagin',
  String? currencyCode = 'eur',
  int decimals = 2,
  String? colour,
  String? iconName,
}) =>
    BackupWallet(
      id: id,
      name: name,
      currencyCode: currencyCode,
      decimals: decimals,
      colour: colour,
      iconName: iconName,
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
    );

CashewBackup backup({
  List<BackupWallet>? wallets,
  List<BackupCategory>? categories,
  List<BackupTransaction> transactions = const [],
}) =>
    CashewBackup(
      wallets: wallets ?? [wallet()],
      categories: categories ?? [category()],
      transactions: transactions,
    );
