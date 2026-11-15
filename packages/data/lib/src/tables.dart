import 'package:atomifi_domain/atomifi_domain.dart'
    show CategorySide, RecurrenceUnit;
import 'package:drift/drift.dart';

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text()();
  IntColumn get currencyDecimals => integer()();
  IntColumn get color => integer().nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emoji => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get side => textEnum<CategorySide>()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  IntColumn get color => integer().nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emoji => text().nullable()();

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

/// What a budget covers: everything, some categories or chosen items.
enum BudgetScopeKind { allSpending, categories, chosenItems }

/// A budget. It either recurs, and then has the three recurrence columns,
/// or covers one fixed stretch of time, and then has the two fixed ones.
@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get limitAmount => integer()();
  TextColumn get currencyCode => text()();
  IntColumn get currencyDecimals => integer()();
  IntColumn get color => integer().nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emoji => text().nullable()();
  TextColumn get scopeKind => textEnum<BudgetScopeKind>()();
  IntColumn get recurrenceEvery => integer().nullable()();
  TextColumn get recurrenceUnit => textEnum<RecurrenceUnit>().nullable()();
  DateTimeColumn get recurrenceAnchor => dateTime().nullable()();
  DateTimeColumn get fixedStart => dateTime().nullable()();
  DateTimeColumn get fixedEnd => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The categories a budget for some categories covers.
@DataClassName('BudgetCategoryRow')
class BudgetCategories extends Table {
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {budgetId, categoryId};
}

/// The items put in a budget for chosen items.
///
/// [itemId] is deliberately not a foreign key: an item is deleted and
/// inserted again whenever its transaction is saved.
@DataClassName('BudgetItemRow')
class BudgetItems extends Table {
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get itemId => text()();

  @override
  Set<Column> get primaryKey => {budgetId, itemId};
}
