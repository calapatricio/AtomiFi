import 'package:atomifi_domain/atomifi_domain.dart';

import 'imported_ledger.dart';

/// Stores what an import produced.
final class LedgerWriter {
  LedgerWriter({
    required AccountRepository accounts,
    required CategoryRepository categories,
    required TransactionRepository transactions,
    required TransferRepository transfers,
  })  : _accounts = accounts,
        _categories = categories,
        _transactions = transactions,
        _transfers = transfers;

  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final TransferRepository _transfers;

  Future<void> write(ImportedLedger ledger) async {
    for (final account in ledger.accounts) {
      await _accounts.save(account);
    }
    for (final category in ledger.categories) {
      await _categories.save(category);
    }
    for (final transaction in ledger.transactions) {
      await _transactions.save(transaction);
    }
    for (final transfer in ledger.transfers) {
      await _transfers.save(transfer);
    }
  }
}
