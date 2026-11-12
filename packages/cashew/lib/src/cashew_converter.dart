import 'dart:math' as math;

import 'package:atomifi_domain/atomifi_domain.dart';

import 'cashew_row.dart';
import 'imported_ledger.dart';

/// Turns the rows of a Cashew export into accounts, categories and
/// transactions.
///
/// Cashew gives a transaction one category, so each row becomes a
/// transaction with a single item borne entirely by the user.
final class CashewConverter {
  CashewConverter({required String Function() newId}) : _newId = newId;

  final String Function() _newId;

  ImportedLedger convert(List<CashewRow> rows) {
    final accounts = <String, Account>{};
    final categories = _Categories(_newId, _categoriesSpentIn(rows));
    final transactions = [
      for (final row in rows.where((row) => row.amount != 0))
        _transactionOf(
          row,
          accounts.putIfAbsent(row.account, () => _accountOf(row)),
          categories.idFor(row),
        ),
    ];
    return ImportedLedger(
      accounts: accounts.values,
      categories: categories.all,
      transactions: transactions,
      skippedRows: rows.length - transactions.length,
    );
  }

  Account _accountOf(CashewRow row) => Account(
        id: AccountId(_newId()),
        name: row.account,
        currency: Currency.iso(row.currencyCode),
      );

  Transaction _transactionOf(
    CashewRow row,
    Account account,
    CategoryId categoryId,
  ) =>
      Transaction(
        id: TransactionId(_newId()),
        name: row.title,
        note: row.note,
        dateTime: row.date,
        accountId: account.id,
        items: [
          Item.mine(
            id: ItemId(_newId()),
            name: row.title,
            categoryId: categoryId,
            price: _moneyOf(row.amount, account.currency),
          ),
        ],
      );

  static Money _moneyOf(double amount, Currency currency) =>
      Money((amount * math.pow(10, currency.decimals)).round(), currency);

  static Set<String> _categoriesSpentIn(List<CashewRow> rows) => {
        for (final row in rows)
          if (row.amount < 0) row.category,
      };
}

/// The categories found so far, each created the first time it is seen.
final class _Categories {
  _Categories(this._newId, this._spentIn);

  final String Function() _newId;

  /// Names of the categories with at least one outflow. Cashew does not
  /// export the side of a category, so one that only receives money is
  /// taken for an income category.
  final Set<String> _spentIn;
  final _byName = <(String, String?), Category>{};

  List<Category> get all => _byName.values.toList();

  CategoryId idFor(CashewRow row) {
    final category = _byName.putIfAbsent(
      (row.category, null),
      () => _create(row.category, within: row.category),
    );
    final subcategory = row.subcategory;
    if (subcategory == null) return category.id;
    return _byName
        .putIfAbsent(
          (row.category, subcategory),
          () => _create(subcategory, within: row.category, parent: category),
        )
        .id;
  }

  Category _create(String name, {required String within, Category? parent}) =>
      Category(
        id: CategoryId(_newId()),
        name: name,
        side: _spentIn.contains(within)
            ? CategorySide.expense
            : CategorySide.income,
        parentId: parent?.id,
      );
}
