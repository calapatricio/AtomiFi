import 'package:atomifi_domain/atomifi_domain.dart';

import 'cashew_converter.dart';
import 'cashew_export_parser.dart';
import 'imported_ledger.dart';

/// Reads a Cashew CSV export and stores what it holds.
final class CashewImporter {
  CashewImporter({
    required CashewConverter converter,
    required AccountRepository accounts,
    required CategoryRepository categories,
    required TransactionRepository transactions,
    CashewExportParser parser = const CashewExportParser(),
  })  : _parser = parser,
        _converter = converter,
        _accounts = accounts,
        _categories = categories,
        _transactions = transactions;

  final CashewExportParser _parser;
  final CashewConverter _converter;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;

  Future<ImportedLedger> importCsv(String csv) async {
    final ledger = _converter.convert(_parser.parse(csv));
    for (final account in ledger.accounts) {
      await _accounts.save(account);
    }
    for (final category in ledger.categories) {
      await _categories.save(category);
    }
    for (final transaction in ledger.transactions) {
      await _transactions.save(transaction);
    }
    return ledger;
  }
}
