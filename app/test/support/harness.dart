import 'package:atomifi/accounts/accounts_view_model.dart';
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

Money eur(int cents) => Money(cents, Currency.eur);

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
