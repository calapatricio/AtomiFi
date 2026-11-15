import 'package:atomifi_domain/atomifi_domain.dart';

/// What an import produced, ready to be stored.
final class ImportedLedger {
  ImportedLedger({
    required Iterable<Account> accounts,
    required Iterable<Category> categories,
    required Iterable<Transaction> transactions,
    Iterable<Transfer> transfers = const [],
    Iterable<Budget> budgets = const [],
    required this.skippedRows,
  })  : accounts = List.unmodifiable(accounts),
        categories = List.unmodifiable(categories),
        transactions = List.unmodifiable(transactions),
        transfers = List.unmodifiable(transfers),
        budgets = List.unmodifiable(budgets);

  final List<Account> accounts;

  /// Every category comes before its subcategories.
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Transfer> transfers;
  final List<Budget> budgets;

  /// How many transactions were left out because they had no amount or
  /// were never paid.
  final int skippedRows;
}
