import 'database.dart';

/// Deletes the items of the transactions with these ids, and their shares.
///
/// The rows are deleted one table at a time, children first, because the
/// database refuses to delete a row that others still point to.
Future<void> deleteItemsOfTransactions(
  AtomiFiDatabase database,
  Iterable<String> transactionIds,
) async {
  final itemsOfTransactions = database.select(database.items)
    ..where((items) => items.transactionId.isIn(transactionIds));
  final itemIds = await itemsOfTransactions.map((item) => item.id).get();
  final shares = database.delete(database.shares)
    ..where((shares) => shares.itemId.isIn(itemIds));
  await shares.go();
  final items = database.delete(database.items)
    ..where((items) => items.transactionId.isIn(transactionIds));
  await items.go();
}
