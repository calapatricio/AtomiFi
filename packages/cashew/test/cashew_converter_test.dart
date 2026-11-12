import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/sample.dart';

ImportedLedger _convert(List<CashewRow> rows) =>
    CashewConverter(newId: sequentialIds()).convert(rows);

void main() {
  group('CashewConverter', () {
    test('creates one account for each account name', () {
      final ledger = _convert([
        row(account: 'Imagin'),
        row(account: 'Broker', currencyCode: 'USD'),
        row(account: 'Imagin'),
      ]);

      expect(ledger.accounts.map((account) => account.name), [
        'Imagin',
        'Broker',
      ]);
      expect(ledger.accounts.map((account) => account.currency), [
        Currency.eur,
        Currency.usd,
      ]);
    });

    test('turns each row into a transaction of its account', () {
      final ledger = _convert([
        row(
          title: 'Tacos',
          note: 'Moy - 14€',
          amount: -26.5,
          date: DateTime(2026, 11, 7, 22, 1, 26),
        ),
      ]);

      final transaction = ledger.transactions.single;

      expect(transaction.name, 'Tacos');
      expect(transaction.note, 'Moy - 14€');
      expect(transaction.dateTime, DateTime(2026, 11, 7, 22, 1, 26));
      expect(transaction.accountId, ledger.accounts.single.id);
      expect(transaction.total, const Money(-2650, Currency.eur));
    });

    test('gives each transaction one item that is entirely mine', () {
      final item = _convert([row(title: 'Tacos', amount: -26.5)])
          .transactions
          .single
          .items
          .single;

      expect(item.name, 'Tacos');
      expect(item.ownAmount, const Money(-2650, Currency.eur));
      expect(item.offsets, isNull);
    });

    test('rounds away the noise of amounts stored as fractions', () {
      final ledger = _convert([row(amount: 21.200000000000003)]);

      expect(
        ledger.transactions.single.total,
        const Money(2120, Currency.eur),
      );
    });

    test('keeps amounts whole in currencies without decimals', () {
      final ledger = _convert([row(amount: -1620, currencyCode: 'JPY')]);

      expect(
        ledger.transactions.single.total,
        const Money(-1620, Currency.jpy),
      );
    });

    test('creates each category once', () {
      final ledger = _convert([
        row(category: 'Comida'),
        row(category: 'Transporte'),
        row(category: 'Comida'),
      ]);

      expect(ledger.categories.map((category) => category.name), [
        'Comida',
        'Transporte',
      ]);
    });

    test('puts a subcategory under its category and the item in it', () {
      final ledger = _convert([row(category: 'Ocio', subcategory: 'Alcohol')]);

      final [leisure, alcohol] = ledger.categories;

      expect(leisure.name, 'Ocio');
      expect(leisure.parentId, isNull);
      expect(alcohol.name, 'Alcohol');
      expect(alcohol.parentId, leisure.id);
      expect(ledger.transactions.single.items.single.categoryId, alcohol.id);
    });

    test('keeps subcategories of the same name apart', () {
      final ledger = _convert([
        row(category: 'Ocio', subcategory: 'Otros'),
        row(category: 'Comida', subcategory: 'Otros'),
      ]);

      expect(ledger.categories, hasLength(4));
    });

    test('treats a category with any spending as an expense category', () {
      final ledger = _convert([
        row(category: 'Comida', amount: 21.2),
        row(category: 'Comida', amount: -5),
      ]);

      expect(ledger.categories.single.side, CategorySide.expense);
    });

    test('treats a category that only receives money as income', () {
      final ledger = _convert([
        row(category: 'Salario', amount: 1500),
        row(category: 'Salario', subcategory: 'Extra', amount: 200),
      ]);

      expect(
        ledger.categories.map((category) => category.side),
        everyElement(CategorySide.income),
      );
    });

    test('skips rows without an amount and counts them', () {
      final ledger = _convert([row(amount: 0), row(amount: -5)]);

      expect(ledger.transactions, hasLength(1));
      expect(ledger.skippedRows, 1);
    });

    test('gives everything it creates a different id', () {
      final ledger = _convert([row(), row(subcategory: 'Tacos')]);

      final ids = {
        for (final account in ledger.accounts) account.id.value,
        for (final category in ledger.categories) category.id.value,
        for (final transaction in ledger.transactions) ...[
          transaction.id.value,
          for (final item in transaction.items) item.id.value,
        ],
      };

      expect(ids, hasLength(7));
    });
  });
}
