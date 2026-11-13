import 'dart:convert';
import 'dart:io';

import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:sqlite3/sqlite3.dart';

/// Prints what a Cashew backup or CSV export turns into, to compare it with
/// Cashew.
///
///     dart run bin/report.dart path/to/cashew-backup.sql
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run bin/report.dart <backup.sql|export.csv>');
    exitCode = 64;
    return;
  }
  final path = arguments.single;
  final ledger = _isSqliteDatabase(path) ? _readBackup(path) : _readCsv(path);
  final summary = LedgerSummary(ledger);

  stdout
    ..writeln('Transactions: ${ledger.transactions.length}')
    ..writeln('Transfers: ${ledger.transfers.length}')
    ..writeln('Accounts: ${ledger.accounts.length}')
    ..writeln('Categories: ${ledger.categories.length}')
    ..writeln('Skipped (no amount or not paid yet): ${ledger.skippedRows}')
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

bool _isSqliteDatabase(String path) {
  const signature = 'SQLite format 3';
  final file = File(path).openSync();
  try {
    final start = file.readSync(signature.length);
    return ascii.decode(start, allowInvalid: true) == signature;
  } finally {
    file.closeSync();
  }
}

ImportedLedger _readBackup(String path) {
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    return const CashewBackupConverter(defaultCurrencyCode: 'EUR')
        .convert(const CashewBackupReader().read(database));
  } finally {
    database.close();
  }
}

ImportedLedger _readCsv(String path) {
  final csv = File(path).readAsStringSync(encoding: utf8);
  var nextId = 0;
  return CashewConverter(newId: () => 'id-${nextId++}')
      .convert(const CashewExportParser().parse(csv));
}
