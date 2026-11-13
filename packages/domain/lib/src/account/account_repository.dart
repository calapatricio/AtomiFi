import '../ids.dart';
import 'account.dart';

/// Where accounts are kept.
abstract interface class AccountRepository {
  /// Stores [account], replacing the one with the same id if there is one.
  Future<void> save(Account account);

  /// Removes the account and every record of it: its transactions, its
  /// revaluations and the transfers it sent or received, both sides of them.
  Future<void> remove(AccountId id);

  /// Every stored account, archived ones included, ordered by name.
  Future<List<Account>> all();
}
