import 'package:atomifi_domain/atomifi_domain.dart';

/// What an import produced, ready to be stored.
final class ImportedLedger {
  ImportedLedger({
    required Iterable<Account> accounts,
    required Iterable<Category> categories,
    required Iterable<Transaction> transactions,
    required this.skippedRows,
  })  : accounts = List.unmodifiable(accounts),
        categories = List.unmodifiable(categories),
        transactions = List.unmodifiable(transactions);

  final List<Account> accounts;

  /// Every category comes before its subcategories.
  final List<Category> categories;
  final List<Transaction> transactions;

  /// How many rows were left out because they had no amount, such as
  /// upcoming transactions that were never paid.
  final int skippedRows;
}
