import 'package:atomifi_domain/atomifi_domain.dart' show CategorySide;
import 'package:drift/drift.dart';

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text()();
  IntColumn get currencyDecimals => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get side => textEnum<CategorySide>()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get note => text()();
  DateTimeColumn get happenedAt => dateTime()();
  TextColumn get accountId => text().references(Accounts, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// The items of a transaction, in the order given by [position].
///
/// [offsetsItemId] is deliberately not a foreign key: the item it points to
/// is deleted and inserted again whenever its transaction is saved.
@DataClassName('ItemRow')
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get offsetsItemId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The shares of an item. A share without a [person] is the user's own.
@DataClassName('ShareRow')
class Shares extends Table {
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get position => integer()();
  TextColumn get person => text().nullable()();
  IntColumn get amount => integer()();

  @override
  Set<Column> get primaryKey => {itemId, position};
}

@DataClassName('TransferRow')
class Transfers extends Table {
  TextColumn get id => text()();
  TextColumn get note => text()();
  @ReferenceName('outgoingTransfers')
  TextColumn get fromAccountId => text().references(Accounts, #id)();
  DateTimeColumn get sentAt => dateTime()();
  IntColumn get sentAmount => integer()();
  @ReferenceName('incomingTransfers')
  TextColumn get toAccountId => text().references(Accounts, #id)();
  DateTimeColumn get receivedAt => dateTime()();
  IntColumn get receivedAmount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RevaluationRow')
class Revaluations extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  DateTimeColumn get statedAt => dateTime()();
  IntColumn get statedValue => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
