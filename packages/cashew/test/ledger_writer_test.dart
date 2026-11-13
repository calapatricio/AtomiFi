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

final class _Transfers implements TransferRepository {
  final saved = <Transfer>[];

  @override
  Future<void> save(Transfer transfer) async => saved.add(transfer);

  @override
  Future<void> remove(TransferId id) async =>
      saved.removeWhere((transfer) => transfer.id == id);

  @override
  Future<List<Transfer>> all() async => saved;
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

ImportedLedger _ledger() => CashewConverter(newId: sequentialIds())
    .convert(const CashewExportParser().parse(sampleExport));

void main() {
  group('LedgerWriter', () {
    late _Accounts accounts;
    late _Categories categories;
    late _Transactions transactions;
    late _Transfers transfers;
    late LedgerWriter writer;

    setUp(() {
      accounts = _Accounts();
      categories = _Categories();
      transactions = _Transactions();
      transfers = _Transfers();
      writer = LedgerWriter(
        accounts: accounts,
        categories: categories,
        transactions: transactions,
        transfers: transfers,
      );
    });

    test('stores the accounts, categories and transactions', () async {
      await writer.write(_ledger());

      expect(accounts.saved.map((account) => account.name), ['Imagin', 'Cash']);
      expect(categories.saved, hasLength(5));
      expect(transactions.saved, hasLength(4));
    });

    test('stores a category before its subcategories', () async {
      await writer.write(_ledger());

      final names = categories.saved.map((category) => category.name).toList();

      expect(names.indexOf('Ocio'), lessThan(names.indexOf('Alcohol')));
    });

    test('stores the transfers', () async {
      final transfer = Transfer(
        id: const TransferId('dca'),
        outgoing: TransferLeg(
          accountId: const AccountId('bank'),
          dateTime: DateTime(2026, 11, 1),
          amount: const Money(2000, Currency.eur),
        ),
        incoming: TransferLeg(
          accountId: const AccountId('broker'),
          dateTime: DateTime(2026, 11, 1),
          amount: const Money(2000, Currency.eur),
        ),
      );

      await writer.write(
        ImportedLedger(
          accounts: const [],
          categories: const [],
          transactions: const [],
          transfers: [transfer],
          skippedRows: 0,
        ),
      );

      expect(transfers.saved, [transfer]);
    });
  });
}
