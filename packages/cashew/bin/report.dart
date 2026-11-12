import 'dart:convert';
import 'dart:io';

import 'package:atomifi_cashew/atomifi_cashew.dart';

/// Prints what a Cashew export turns into, to compare it with Cashew.
///
///     dart run bin/report.dart path/to/cashew-export.csv
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run bin/report.dart <cashew-export.csv>');
    exitCode = 64;
    return;
  }
  final csv = File(arguments.single).readAsStringSync(encoding: utf8);
  var nextId = 0;
  final ledger = CashewConverter(newId: () => 'id-${nextId++}')
      .convert(const CashewExportParser().parse(csv));
  final summary = LedgerSummary(ledger);

  stdout
    ..writeln('Transactions: ${ledger.transactions.length}')
    ..writeln('Accounts: ${ledger.accounts.length}')
    ..writeln('Categories: ${ledger.categories.length}')
    ..writeln('Rows skipped for having no amount: ${ledger.skippedRows}')
    ..writeln()
    ..writeln('Balances');
  summary.balances.forEach((account, balance) {
    stdout.writeln(
      '  ${account.name}: ${balance.toDecimalString()} ${balance.currency}',
    );
  });
  for (final currency in {for (final a in ledger.accounts) a.currency}) {
    stdout
      ..writeln()
      ..writeln('Monthly totals in $currency');
    for (final totals in summary.monthlyTotals(currency)) {
      final month = totals.month.toString().padLeft(2, '0');
      stdout.writeln(
        '  ${totals.year}-$month'
        '  income ${totals.income.toDecimalString()}'
        '  expenses ${totals.expenses.toDecimalString()}',
      );
    }
  }
}
