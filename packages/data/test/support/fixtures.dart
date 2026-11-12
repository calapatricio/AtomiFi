import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/native.dart';

const bank = Account(
  id: AccountId('bank'),
  name: 'Bank',
  currency: Currency.eur,
);
const savings = Account(
  id: AccountId('savings'),
  name: 'Savings',
  currency: Currency.eur,
);
const broker = Account(
  id: AccountId('broker'),
  name: 'Broker',
  currency: Currency.usd,
);

const leisure = Category(
  id: CategoryId('leisure'),
  name: 'Leisure',
  side: CategorySide.expense,
);
const alcohol = Category(
  id: CategoryId('alcohol'),
  name: 'Alcohol',
  side: CategorySide.expense,
  parentId: CategoryId('leisure'),
);
const food = Category(
  id: CategoryId('food'),
  name: 'Food',
  side: CategorySide.expense,
);
const salary = Category(
  id: CategoryId('salary'),
  name: 'Salary',
  side: CategorySide.income,
);

const moy = Person('Moy');

Money eur(int cents) => Money(cents, Currency.eur);

Money usd(int cents) => Money(cents, Currency.usd);

AtomiFiDatabase openDatabase() => AtomiFiDatabase(NativeDatabase.memory());

/// A database that already holds the accounts and categories above.
Future<AtomiFiDatabase> openSeededDatabase() async {
  final database = openDatabase();
  final accounts = DriftAccountRepository(database);
  final categories = DriftCategoryRepository(database);
  for (final account in [bank, savings, broker]) {
    await accounts.save(account);
  }
  for (final category in [leisure, alcohol, food, salary]) {
    await categories.save(category);
  }
  return database;
}
