import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'database.dart';

TransactionsCompanion transactionRowOf(Transaction transaction) =>
    TransactionsCompanion.insert(
      id: transaction.id.value,
      name: transaction.name,
      note: transaction.note,
      happenedAt: transaction.dateTime,
      accountId: transaction.accountId.value,
    );

List<ItemsCompanion> itemRowsOf(Transaction transaction) => [
      for (final (position, item) in transaction.items.indexed)
        ItemsCompanion.insert(
          id: item.id.value,
          transactionId: transaction.id.value,
          position: position,
          name: item.name,
          categoryId: item.categoryId.value,
          offsetsItemId: Value(item.offsets?.value),
        ),
    ];

List<SharesCompanion> shareRowsOf(Transaction transaction) => [
      for (final item in transaction.items)
        for (final (position, share) in item.shares.indexed)
          SharesCompanion.insert(
            itemId: item.id.value,
            position: position,
            person: Value(_personOf(share.party)),
            amount: share.amount.minorUnits,
          ),
    ];

/// Rebuilds a transaction from its row and the rows of its items and shares.
Transaction transactionOf(
  TransactionRow row, {
  required List<ItemRow> items,
  required Map<String, List<ShareRow>> sharesByItemId,
  required Currency currency,
}) =>
    Transaction(
      id: TransactionId(row.id),
      name: row.name,
      note: row.note,
      dateTime: row.happenedAt,
      accountId: AccountId(row.accountId),
      items: [
        for (final item in items)
          _itemOf(item, sharesByItemId[item.id] ?? const [], currency),
      ],
    );

Item _itemOf(ItemRow row, List<ShareRow> shares, Currency currency) {
  final offsets = row.offsetsItemId;
  return Item(
    id: ItemId(row.id),
    name: row.name,
    categoryId: CategoryId(row.categoryId),
    shares: [
      for (final share in shares)
        Share(_partyOf(share.person), Money(share.amount, currency)),
    ],
    offsets: offsets == null ? null : ItemId(offsets),
  );
}

String? _personOf(Party party) => switch (party) {
      Me() => null,
      Person(:final name) => name,
    };

Party _partyOf(String? person) => person == null ? const Me() : Person(person);
