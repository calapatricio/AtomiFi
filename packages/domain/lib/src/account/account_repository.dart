import 'account.dart';

/// Where accounts are kept.
abstract interface class AccountRepository {
  /// Stores [account], replacing the one with the same id if there is one.
  Future<void> save(Account account);

  /// Every stored account, ordered by name.
  Future<List<Account>> all();
}
