import 'package:atomifi/accounts/accounts_view_model.dart';
import 'package:atomifi/transactions/transaction_form_view_model.dart';
import 'package:atomifi/transactions/transactions_view_model.dart';
import 'package:atomifi/l10n/app_localizations.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

const food = Category(
  id: CategoryId('food'),
  name: 'Food',
  side: CategorySide.expense,
  appearance: Appearance(emoji: '🍔'),
);
const alcohol = Category(
  id: CategoryId('alcohol'),
  name: 'Alcohol',
  side: CategorySide.expense,
);
const salary = Category(
  id: CategoryId('salary'),
  name: 'Salary',
  side: CategorySide.income,
);

Money eur(int cents) => Money(cents, Currency.eur);

/// A store that already holds the accounts and categories above.
Future<InMemoryStore> seededStore() async {
  final store = InMemoryStore();
  for (final account in [bank, savings]) {
    await store.accounts.save(account);
  }
  for (final category in [food, alcohol, salary]) {
    await store.categories.save(category);
  }
  return store;
}

Transaction spending(
  String id, {
  String name = 'Supermarket',
  Account account = bank,
  DateTime? dateTime,
  Map<Category, int> centsByCategory = const {food: -1500},
}) => Transaction(
  id: TransactionId(id),
  name: name,
  dateTime: dateTime ?? DateTime(2026, 11, 6, 20, 30),
  accountId: account.id,
  items: [
    for (final MapEntry(key: category, value: cents) in centsByCategory.entries)
      Item.mine(
        id: ItemId('$id-${category.id.value}'),
        name: category.name,
        categoryId: category.id,
        price: eur(cents),
      ),
  ],
);

Ledger ledgerOn(InMemoryStore store) => Ledger(
  transactions: store.transactions,
  transfers: store.transfers,
  revaluations: store.revaluations,
);

TransactionsViewModel transactionsViewModelOn(InMemoryStore store) =>
    TransactionsViewModel(
      ledger: ledgerOn(store),
      accounts: store.accounts,
      categories: store.categories,
    );

Transaction income(String id, Account account, int cents) => Transaction(
  id: TransactionId(id),
  name: 'Payroll',
  dateTime: DateTime(2026, 11, 1),
  accountId: account.id,
  items: [
    Item.mine(
      id: ItemId('$id-item'),
      name: 'Payroll',
      categoryId: const CategoryId('salary'),
      price: eur(cents),
    ),
  ],
);

Transfer transfer(String id, Account from, Account to, int cents) => Transfer(
  id: TransferId(id),
  outgoing: TransferLeg(
    accountId: from.id,
    dateTime: DateTime(2026, 11, 2),
    amount: eur(cents),
  ),
  incoming: TransferLeg(
    accountId: to.id,
    dateTime: DateTime(2026, 11, 2),
    amount: eur(cents),
  ),
);

AccountsViewModel accountsViewModelOn(InMemoryStore store) {
  var nextId = 0;
  return AccountsViewModel(
    accounts: store.accounts,
    ledger: Ledger(
      transactions: store.transactions,
      transfers: store.transfers,
      revaluations: store.revaluations,
    ),
    newId: () => 'new-${nextId++}',
  );
}

/// Shows [screen] the way the app does, in English.
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

/// The moment the tests take for now.
final now = DateTime(2026, 11, 13, 16, 50);

TransactionFormViewModel transactionFormOn(
  InMemoryStore store, {
  Transaction? existing,
}) {
  var nextId = 0;
  return TransactionFormViewModel(
    transactions: store.transactions,
    accounts: store.accounts,
    categories: store.categories,
    newId: () => 'new-${nextId++}',
    now: () => now,
    existing: existing,
  );
}
