import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/sample.dart';

final class _Accounts implements AccountRepository {
  final saved = <Account>[];

  @override
  Future<void> save(Account account) async => saved.add(account);

  @override
  Future<List<Account>> all() async => saved;
}

final class _Categories implements CategoryRepository {
  final saved = <Category>[];

  @override
  Future<void> save(Category category) async => saved.add(category);

  @override
  Future<List<Category>> all() async => saved;
}

final class _Transactions implements TransactionRepository {
  final saved = <Transaction>[];

  @override
  Future<void> save(Transaction transaction) async => saved.add(transaction);

  @override
  Future<void> remove(TransactionId id) async =>
      saved.removeWhere((transaction) => transaction.id == id);

  @override
  Future<List<Transaction>> all() async => saved;
}

void main() {
  group('CashewImporter', () {
    late _Accounts accounts;
    late _Categories categories;
    late _Transactions transactions;
    late CashewImporter importer;

    setUp(() {
      accounts = _Accounts();
      categories = _Categories();
      transactions = _Transactions();
      importer = CashewImporter(
        converter: CashewConverter(newId: sequentialIds()),
        accounts: accounts,
        categories: categories,
        transactions: transactions,
      );
    });

    test('stores the accounts, categories and transactions it reads', () async {
      await importer.import(export);

      expect(accounts.saved.map((account) => account.name), ['Imagin', 'Cash']);
      expect(categories.saved, hasLength(5));
      expect(transactions.saved, hasLength(4));
    });

    test('stores a category before its subcategories', () async {
      await importer.import(export);

      final names = categories.saved.map((category) => category.name).toList();

      expect(names.indexOf('Ocio'), lessThan(names.indexOf('Alcohol')));
    });

    test('tells what it imported', () async {
      final ledger = await importer.import(export);

      expect(ledger.transactions, transactions.saved);
      expect(ledger.skippedRows, 0);
    });
  });
}
