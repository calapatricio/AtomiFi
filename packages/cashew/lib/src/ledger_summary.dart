import 'package:atomifi_domain/atomifi_domain.dart';

import 'imported_ledger.dart';

/// What was earned and spent in one calendar month.
final class MonthTotals {
  const MonthTotals({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
  });

  final int year;
  final int month;
  final Money income;
  final Money expenses;
}

/// Figures of an imported ledger to compare with the ones Cashew shows.
final class LedgerSummary {
  LedgerSummary(this._ledger);

  final ImportedLedger _ledger;

  Map<Account, Money> get balances {
    final balances = Balances(_ledger.transactions);
    return {
      for (final account in _ledger.accounts)
        account: balances.balanceOf(account),
    };
  }

  /// The totals of every month from the first transaction to the last, for
  /// the accounts held in [currency].
  List<MonthTotals> monthlyTotals(Currency currency) {
    final transactions = _transactionsIn(currency);
    if (transactions.isEmpty) return const [];
    final calculator = StatsCalculator(
      categories: _ledger.categories,
      currency: currency,
    );
    final dates = [for (final transaction in transactions) transaction.dateTime]
      ..sort();
    return [
      for (final (year, month) in _monthsBetween(dates.first, dates.last))
        _totalsOf(
          calculator.statsFor(DateRange.month(year, month), transactions),
          year,
          month,
        ),
    ];
  }

  List<Transaction> _transactionsIn(Currency currency) {
    final accountIds = {
      for (final account in _ledger.accounts)
        if (account.currency == currency) account.id,
    };
    return _ledger.transactions
        .where((transaction) => accountIds.contains(transaction.accountId))
        .toList();
  }

  static MonthTotals _totalsOf(PeriodStats stats, int year, int month) =>
      MonthTotals(
        year: year,
        month: month,
        income: stats.income,
        expenses: stats.expenses,
      );

  static Iterable<(int, int)> _monthsBetween(
    DateTime first,
    DateTime last,
  ) sync* {
    var month = DateTime(first.year, first.month);
    while (!month.isAfter(last)) {
      yield (month.year, month.month);
      month = DateTime(month.year, month.month + 1);
    }
  }
}
