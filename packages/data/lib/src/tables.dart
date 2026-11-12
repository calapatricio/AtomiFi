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
