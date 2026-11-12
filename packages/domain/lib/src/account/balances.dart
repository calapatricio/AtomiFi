import 'package:collection/collection.dart';

import '../ledger/balance_change.dart';
import '../ledger/ledger_record.dart';
import '../money/currency.dart';
import '../money/currency_converter.dart';
import '../money/money.dart';
import 'account.dart';

/// Works out what each account holds from the records of the ledger.
final class Balances {
  Balances(Iterable<LedgerRecord> records) : _changes = _chronological(records);

  final List<BalanceChange> _changes;

  /// What [account] holds now, or held [at] an earlier moment.
  Money balanceOf(Account account, {DateTime? at}) =>
      _changesOf(account, at).fold(
        Money.zero(account.currency),
        (balance, change) => change.applyTo(balance),
      );

  /// The money moved into [account] minus the money moved out of it.
  Money contributedTo(Account account, {DateTime? at}) =>
      _changesOf(account, at).whereType<Movement>().fold(
            Money.zero(account.currency),
            (sum, movement) => sum + movement.amount,
          );

  /// What revaluations added to or took from [account].
  Money marketGainOf(Account account, {DateTime? at}) =>
      balanceOf(account, at: at) - contributedTo(account, at: at);

  /// The balances of all [accounts] added up in one [currency].
  Money netWorth(
    Iterable<Account> accounts,
    Currency currency,
    CurrencyConverter converter,
  ) =>
      accounts.fold(
        Money.zero(currency),
        (sum, account) => sum + converter.convert(balanceOf(account), currency),
      );

  Iterable<BalanceChange> _changesOf(Account account, DateTime? until) =>
      _changes.where(
        (change) =>
            change.accountId == account.id &&
            (until == null || !change.dateTime.isAfter(until)),
      );

  static List<BalanceChange> _chronological(Iterable<LedgerRecord> records) {
    final changes = [for (final record in records) ...record.balanceChanges];
    mergeSort(
      changes,
      compare: (BalanceChange a, BalanceChange b) =>
          a.dateTime.compareTo(b.dateTime),
    );
    return changes;
  }
}
