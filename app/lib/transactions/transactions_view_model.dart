import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Something that happened in the ledger, with what is needed to show it.
sealed class LedgerEntry {
  const LedgerEntry();

  DateTime get dateTime;
}

final class TransactionEntry extends LedgerEntry {
  const TransactionEntry(this.transaction, this.account, this.categories);

  final Transaction transaction;
  final Account account;

  /// The categories of its items, each once, in the order of the items.
  final List<Category> categories;

  @override
  DateTime get dateTime => transaction.dateTime;
}

final class TransferEntry extends LedgerEntry {
  const TransferEntry(this.transfer, this.from, this.to);

  final Transfer transfer;
  final Account from;
  final Account to;

  @override
  DateTime get dateTime => transfer.outgoing.dateTime;
}

final class RevaluationEntry extends LedgerEntry {
  const RevaluationEntry(this.revaluation, this.account);

  final Revaluation revaluation;
  final Account account;

  @override
  DateTime get dateTime => revaluation.dateTime;
}

/// The entries of one day, latest first.
final class DayOfEntries {
  const DayOfEntries(this.date, this.entries);

  final DateTime date;
  final List<LedgerEntry> entries;
}

/// The state of the list of everything that happened.
final class TransactionsViewModel extends ChangeNotifier {
  TransactionsViewModel({
    required this._ledger,
    required this._accounts,
    required this._categories,
  });

  final Ledger _ledger;
  final AccountRepository _accounts;
  final CategoryRepository _categories;

  List<DayOfEntries> _days = const [];

  /// The days on which something happened, latest first.
  List<DayOfEntries> get days => _days;

  Future<void> load() async {
    final snapshot = await _ledger.snapshot();
    final entries = _EntryFactory(
      accounts: await _accounts.all(),
      categories: await _categories.all(),
    ).entriesOf(snapshot);
    _days = _byDay(entries);
    notifyListeners();
  }

  static List<DayOfEntries> _byDay(List<LedgerEntry> entries) {
    final latestFirst = [...entries]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final entriesByDay = <DateTime, List<LedgerEntry>>{};
    for (final entry in latestFirst) {
      entriesByDay.putIfAbsent(_dayOf(entry.dateTime), () => []).add(entry);
    }
    return [
      for (final MapEntry(key: day, value: entries) in entriesByDay.entries)
        DayOfEntries(day, entries),
    ];
  }

  static DateTime _dayOf(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);
}

/// Pairs the records of the ledger with their accounts and categories.
final class _EntryFactory {
  _EntryFactory({
    required List<Account> accounts,
    required List<Category> categories,
  }) : _accountById = {for (final account in accounts) account.id: account},
       _categoryById = {
         for (final category in categories) category.id: category,
       };

  final Map<AccountId, Account> _accountById;
  final Map<CategoryId, Category> _categoryById;

  List<LedgerEntry> entriesOf(LedgerSnapshot snapshot) => [
    for (final transaction in snapshot.transactions)
      TransactionEntry(
        transaction,
        _accountById[transaction.accountId]!,
        _categoriesOf(transaction),
      ),
    for (final transfer in snapshot.transfers)
      TransferEntry(
        transfer,
        _accountById[transfer.outgoing.accountId]!,
        _accountById[transfer.incoming.accountId]!,
      ),
    for (final revaluation in snapshot.revaluations)
      RevaluationEntry(revaluation, _accountById[revaluation.accountId]!),
  ];

  List<Category> _categoriesOf(Transaction transaction) =>
      {for (final item in transaction.items) item.categoryId}
          .map((id) => _categoryById[id])
          .nonNulls
          .toList();
}
