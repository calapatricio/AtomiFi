import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/sample.dart';

Money _eur(int cents) => Money(cents, Currency.eur);

LedgerSummary _summaryOf(List<CashewRow> rows) =>
    LedgerSummary(CashewConverter(newId: sequentialIds()).convert(rows));

void main() {
  group('LedgerSummary', () {
    test('tells the balance of each account', () {
      final summary = _summaryOf([
        row(account: 'Imagin', category: 'Salario', amount: 1500),
        row(account: 'Imagin', amount: -26.5),
        row(account: 'Cash', amount: -4),
      ]);

      final balances = {
        for (final entry in summary.balances.entries)
          entry.key.name: entry.value,
      };

      expect(balances, {'Imagin': _eur(147350), 'Cash': _eur(-400)});
    });

    test('tells the income and expenses of each month', () {
      final summary = _summaryOf([
        row(category: 'Salario', amount: 1500, date: DateTime(2026, 10, 28)),
        row(amount: -26.5, date: DateTime(2026, 10, 30)),
        row(amount: -5, date: DateTime(2026, 11, 2)),
      ]);

      final [october, november] = summary.monthlyTotals(Currency.eur);

      expect((october.year, october.month), (2026, 10));
      expect(october.income, _eur(150000));
      expect(october.expenses, _eur(2650));
      expect((november.year, november.month), (2026, 11));
      expect(november.income, _eur(0));
      expect(november.expenses, _eur(500));
    });

    test('includes the months in which nothing happened', () {
      final summary = _summaryOf([
        row(date: DateTime(2026, 9, 30)),
        row(date: DateTime(2026, 11, 1)),
      ]);

      final months = summary.monthlyTotals(Currency.eur);

      expect(months.map((totals) => totals.month), [9, 10, 11]);
      expect(months[1].expenses, _eur(0));
    });

    test('counts only the accounts held in the currency asked for', () {
      final summary = _summaryOf([
        row(account: 'Imagin', amount: -5),
        row(account: 'Broker', currencyCode: 'USD', amount: -99),
      ]);

      expect(summary.monthlyTotals(Currency.eur).single.expenses, _eur(500));
    });

    test('has no months for a currency nobody holds', () {
      expect(_summaryOf([row()]).monthlyTotals(Currency.usd), isEmpty);
    });
  });
}
