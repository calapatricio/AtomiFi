/// An account as Cashew keeps it.
final class BackupWallet {
  const BackupWallet({
    required this.id,
    required this.name,
    required this.decimals,
    this.currencyCode,
    this.colour,
    this.iconName,
  });

  final String id;
  final String name;

  /// How many decimals the amounts of this wallet have.
  final int decimals;

  /// The currency code in lower case, or nothing for the app's default.
  final String? currencyCode;
  final String? colour;
  final String? iconName;
}

/// A category or subcategory as Cashew keeps it.
final class BackupCategory {
  const BackupCategory({
    required this.id,
    required this.name,
    required this.income,
    this.parentId,
    this.colour,
    this.iconName,
    this.emoji,
  });

  final String id;
  final String name;
  final bool income;

  /// The category this one is a subcategory of, if any.
  final String? parentId;
  final String? colour;
  final String? iconName;
  final String? emoji;
}

/// A transaction as Cashew keeps it.
final class BackupTransaction {
  const BackupTransaction({
    required this.id,
    required this.name,
    required this.note,
    required this.amount,
    required this.date,
    required this.walletId,
    required this.categoryId,
    required this.paid,
    this.subcategoryId,
    this.pairedId,
  });

  final String id;
  final String name;
  final String note;

  /// Negative for money leaving the wallet.
  final double amount;
  final DateTime date;
  final String walletId;
  final String categoryId;
  final String? subcategoryId;

  /// Whether the money has moved. Upcoming transactions are not paid yet.
  final bool paid;

  /// The other half when this transaction is one side of a transfer.
  final String? pairedId;
}

/// The part of a Cashew backup database that the import uses.
final class CashewBackup {
  const CashewBackup({
    required this.wallets,
    required this.categories,
    required this.transactions,
  });

  final List<BackupWallet> wallets;
  final List<BackupCategory> categories;
  final List<BackupTransaction> transactions;
}
