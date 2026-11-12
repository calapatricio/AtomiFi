import '../ids.dart';
import 'transaction.dart';

/// Where transactions are kept, together with their items and shares.
abstract interface class TransactionRepository {
  /// Stores [transaction], replacing the one with the same id if there is one.
  Future<void> save(Transaction transaction);

  Future<void> remove(TransactionId id);

  /// Every stored transaction, oldest first.
  Future<List<Transaction>> all();
}
