import '../ids.dart';
import 'transfer.dart';

/// Where transfers are kept.
abstract interface class TransferRepository {
  /// Stores [transfer], replacing the one with the same id if there is one.
  Future<void> save(Transfer transfer);

  Future<void> remove(TransferId id);

  /// Every stored transfer, ordered by the date the money left.
  Future<List<Transfer>> all();
}
