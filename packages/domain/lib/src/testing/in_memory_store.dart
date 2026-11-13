import '../account/account.dart';
import '../account/account_repository.dart';
import '../category/category.dart';
import '../category/category_repository.dart';
import '../ids.dart';
import '../ledger/revaluation.dart';
import '../ledger/revaluation_repository.dart';
import '../ledger/transaction.dart';
import '../ledger/transaction_repository.dart';
import '../ledger/transfer.dart';
import '../ledger/transfer_repository.dart';

/// Repositories that keep everything in memory and behave like the real
/// ones, for tests that need storage but not a database.
final class InMemoryStore {
  final _accounts = <AccountId, Account>{};
  final _categories = <CategoryId, Category>{};
  final _transactions = <TransactionId, Transaction>{};
  final _transfers = <TransferId, Transfer>{};
  final _revaluations = <RevaluationId, Revaluation>{};

  late final AccountRepository accounts = _Accounts(this);
  late final CategoryRepository categories = _Categories(this);
  late final TransactionRepository transactions = _Transactions(this);
  late final TransferRepository transfers = _Transfers(this);
  late final RevaluationRepository revaluations = _Revaluations(this);
}

final class _Accounts implements AccountRepository {
  _Accounts(this._store);

  final InMemoryStore _store;

  @override
  Future<void> save(Account account) async =>
      _store._accounts[account.id] = account;

  @override
  Future<void> remove(AccountId id) async {
    _store._accounts.remove(id);
    _store._transactions
        .removeWhere((_, transaction) => transaction.accountId == id);
    _store._transfers.removeWhere((_, transfer) => transfer.involves(id));
    _store._revaluations
        .removeWhere((_, revaluation) => revaluation.accountId == id);
  }

  @override
  Future<List<Account>> all() async => _store._accounts.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

final class _Categories implements CategoryRepository {
  _Categories(this._store);

  final InMemoryStore _store;

  @override
  Future<void> save(Category category) async =>
      _store._categories[category.id] = category;

  @override
  Future<List<Category>> all() async => _store._categories.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

final class _Transactions implements TransactionRepository {
  _Transactions(this._store);

  final InMemoryStore _store;

  @override
  Future<void> save(Transaction transaction) async =>
      _store._transactions[transaction.id] = transaction;

  @override
  Future<void> remove(TransactionId id) async =>
      _store._transactions.remove(id);

  @override
  Future<List<Transaction>> all() async => _store._transactions.values.toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}

final class _Transfers implements TransferRepository {
  _Transfers(this._store);

  final InMemoryStore _store;

  @override
  Future<void> save(Transfer transfer) async =>
      _store._transfers[transfer.id] = transfer;

  @override
  Future<void> remove(TransferId id) async => _store._transfers.remove(id);

  @override
  Future<List<Transfer>> all() async => _store._transfers.values.toList()
    ..sort((a, b) => a.outgoing.dateTime.compareTo(b.outgoing.dateTime));
}

final class _Revaluations implements RevaluationRepository {
  _Revaluations(this._store);

  final InMemoryStore _store;

  @override
  Future<void> save(Revaluation revaluation) async =>
      _store._revaluations[revaluation.id] = revaluation;

  @override
  Future<void> remove(RevaluationId id) async =>
      _store._revaluations.remove(id);

  @override
  Future<List<Revaluation>> all() async => _store._revaluations.values.toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}
