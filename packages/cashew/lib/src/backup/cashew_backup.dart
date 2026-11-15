/// An account as Cashew keeps it.
final class BackupWallet {
  const BackupWallet({
    required this.id,
    required this.name,
    required this.decimals,
    this.currencyCode,
    this.colour,
    this.iconName,
    this.emoji,
    this.archived = false,
  });

  final String id;
  final String name;

  /// How many decimals the amounts of this wallet have.
  final int decimals;

  /// The currency code in lower case, or nothing for the app's default.
  final String? currencyCode;
  final String? colour;
  final String? iconName;
  final String? emoji;
  final bool archived;
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
    this.budgetId,
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

  /// The budget this transaction was added to by hand, if any.
  final String? budgetId;
}

/// How often a budget of Cashew starts over, in the order Cashew numbers
/// them. A custom budget does not start over.
enum BackupReoccurrence { custom, daily, weekly, monthly, yearly }

/// A budget as Cashew keeps it.
final class BackupBudget {
  const BackupBudget({
    required this.id,
    required this.name,
    required this.amount,
    required this.start,
    required this.end,
    required this.periodLength,
    required this.reoccurrence,
    required this.walletId,
    this.categoryIds = const [],
    this.excludedCategoryIds = const [],
    this.addedTransactionsOnly = false,
    this.income = false,
    this.archived = false,
    this.colour,
  });

  final String id;
  final String name;

  /// The limit, in the currency of the wallet with [walletId].
  final double amount;

  /// The first day of one of its periods, or of its only one.
  final DateTime start;

  /// The end of a budget that does not start over.
  final DateTime end;

  /// How many days, weeks, months or years each period lasts.
  final int periodLength;
  final BackupReoccurrence reoccurrence;
  final String walletId;

  /// The categories it counts, or none for all of them.
  final List<String> categoryIds;
  final List<String> excludedCategoryIds;

  /// Whether it counts only the transactions added to it by hand.
  final bool addedTransactionsOnly;

  /// Whether it is a budget for saving instead of one for spending.
  final bool income;
  final bool archived;
  final String? colour;
}

/// The part of a Cashew backup database that the import uses.
final class CashewBackup {
  const CashewBackup({
    required this.wallets,
    required this.categories,
    required this.transactions,
    required this.budgets,
  });

  final List<BackupWallet> wallets;
  final List<BackupCategory> categories;
  final List<BackupTransaction> transactions;
  final List<BackupBudget> budgets;
}
