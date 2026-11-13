import 'dart:math' as math;

import 'package:atomifi_domain/atomifi_domain.dart';

import '../imported_ledger.dart';
import 'cashew_backup.dart';

/// Turns a Cashew backup into accounts, categories, transactions and
/// transfers.
///
/// Everything keeps the id it has in Cashew, so importing a backup again
/// replaces what the first import created.
final class CashewBackupConverter {
  const CashewBackupConverter({required this.defaultCurrencyCode});

  /// The currency of the wallets that do not name one.
  final String defaultCurrencyCode;

  ImportedLedger convert(CashewBackup backup) {
    final accounts = [for (final wallet in backup.wallets) _accountOf(wallet)];
    final categories = _categoriesOf(backup.categories);
    final movements = _Movements(backup.transactions, accounts, categories);
    return ImportedLedger(
      accounts: accounts,
      categories: categories,
      transactions: movements.transactions,
      transfers: movements.transfers,
      skippedRows: backup.transactions.length - movements.count,
    );
  }

  Account _accountOf(BackupWallet wallet) => Account(
        id: AccountId(wallet.id),
        name: wallet.name,
        currency: Currency(
          (wallet.currencyCode ?? defaultCurrencyCode).toUpperCase(),
          decimals: wallet.decimals,
        ),
        appearance: _appearanceOf(wallet.colour, wallet.iconName, null),
      );

  /// Categories first and subcategories after them, as storing them needs.
  static List<Category> _categoriesOf(List<BackupCategory> categories) => [
        for (final category in categories)
          if (category.parentId == null) _categoryOf(category),
        for (final category in categories)
          if (category.parentId != null) _categoryOf(category),
      ];

  static Category _categoryOf(BackupCategory category) {
    final parentId = category.parentId;
    return Category(
      id: CategoryId(category.id),
      name: category.name,
      side: category.income ? CategorySide.income : CategorySide.expense,
      parentId: parentId == null ? null : CategoryId(parentId),
      appearance: _appearanceOf(
        category.colour,
        category.iconName,
        category.emoji,
      ),
    );
  }

  static Appearance _appearanceOf(
    String? colour,
    String? iconName,
    String? emoji,
  ) =>
      Appearance(
        color: colour == null ? null : int.tryParse(colour),
        iconName: iconName?.replaceFirst(RegExp(r'\.png$'), ''),
        emoji: emoji,
      );
}

/// A paid transaction of the backup with its account and its amount.
final class _Movement {
  const _Movement(this.source, this.account, this.amount);

  final BackupTransaction source;
  final Account account;
  final Money amount;
}

/// The paid transactions of a backup, sorted into transfers and
/// transactions.
final class _Movements {
  _Movements(
    List<BackupTransaction> transactions,
    List<Account> accounts,
    List<Category> categories,
  )   : _accountById = {for (final account in accounts) account.id: account},
        _categoryIds = {for (final category in categories) category.id} {
    final movements = [
      for (final transaction in transactions)
        if (transaction.paid) _movementOf(transaction),
    ].where((movement) => !movement.amount.isZero).toList();
    _byId = {for (final movement in movements) movement.source.id: movement};
    _byPairedId = {
      for (final movement in movements)
        if (movement.source.pairedId != null)
          movement.source.pairedId!: movement,
    };
    movements.forEach(_sort);
  }

  final Map<AccountId, Account> _accountById;
  final Set<CategoryId> _categoryIds;
  late final Map<String, _Movement> _byId;
  late final Map<String, _Movement> _byPairedId;

  final transactions = <Transaction>[];
  final transfers = <Transfer>[];

  /// How many transactions of the backup were imported.
  int get count => transactions.length + transfers.length * 2;

  void _sort(_Movement movement) {
    final other = _otherHalfOf(movement);
    if (other == null) {
      transactions.add(_transactionOf(movement));
    } else if (movement.amount.isNegative) {
      transfers.add(_transferOf(outgoing: movement, incoming: other));
    }
  }

  /// The movement that, with [movement], makes a transfer: the one it is
  /// paired with, in another account and in the opposite direction.
  _Movement? _otherHalfOf(_Movement movement) {
    final other =
        _byId[movement.source.pairedId] ?? _byPairedId[movement.source.id];
    if (other == null ||
        other.account.id == movement.account.id ||
        other.amount.isNegative == movement.amount.isNegative) {
      return null;
    }
    return other;
  }

  _Movement _movementOf(BackupTransaction transaction) {
    final account = _accountById[AccountId(transaction.walletId)];
    if (account == null) {
      throw FormatException(
        'The transaction "${transaction.name}" belongs to a wallet that is '
        'not in the backup.',
      );
    }
    final scale = math.pow(10, account.currency.decimals);
    return _Movement(
      transaction,
      account,
      Money((transaction.amount * scale).round(), account.currency),
    );
  }

  Transaction _transactionOf(_Movement movement) {
    final source = movement.source;
    return Transaction(
      id: TransactionId(source.id),
      name: source.name,
      note: source.note,
      dateTime: source.date,
      accountId: movement.account.id,
      items: [
        Item.mine(
          id: ItemId('${source.id}-item'),
          name: source.name,
          categoryId: _categoryIdOf(source),
          price: movement.amount,
        ),
      ],
    );
  }

  CategoryId _categoryIdOf(BackupTransaction transaction) {
    final id = CategoryId(transaction.subcategoryId ?? transaction.categoryId);
    if (!_categoryIds.contains(id)) {
      throw FormatException(
        'The transaction "${transaction.name}" belongs to a category that '
        'is not in the backup.',
      );
    }
    return id;
  }

  static Transfer _transferOf({
    required _Movement outgoing,
    required _Movement incoming,
  }) =>
      Transfer(
        id: TransferId(outgoing.source.id),
        note: outgoing.source.note,
        outgoing: TransferLeg(
          accountId: outgoing.account.id,
          dateTime: outgoing.source.date,
          amount: -outgoing.amount,
        ),
        incoming: TransferLeg(
          accountId: incoming.account.id,
          dateTime: incoming.source.date,
          amount: incoming.amount,
        ),
      );
}
