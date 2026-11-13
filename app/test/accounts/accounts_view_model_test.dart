import 'package:atomifi/accounts/accounts_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('AccountsViewModel', () {
    late InMemoryStore store;
    late AccountsViewModel viewModel;

    setUp(() async {
      store = InMemoryStore();
      viewModel = accountsViewModelOn(store);
      await store.accounts.save(bank);
      await store.accounts.save(savings);
      await store.transactions.save(income('payroll', bank, 150000));
      await store.transfers.save(transfer('deposit', bank, savings, 30000));
    });

    test('shows nothing until it has loaded', () {
      expect(viewModel.active, isEmpty);
      expect(viewModel.archived, isEmpty);
    });

    test('lists each account with its balance', () async {
      await viewModel.load();

      expect(viewModel.active.map((summary) => summary.account.name), [
        'Bank',
        'Savings',
      ]);
      expect(viewModel.active.map((summary) => summary.balance), [
        eur(120000),
        eur(30000),
      ]);
    });

    test('tells its listeners when it has loaded', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(notifications, 1);
    });

    test('adds an account in the currency with the given code', () async {
      await viewModel.add(name: '  Broker ', currencyCode: 'usd');

      final broker = viewModel.active.first.account;

      expect(broker.name, 'Broker');
      expect(broker.currency, Currency.usd);
      expect(broker.id, const AccountId('new-0'));
      expect(await store.accounts.all(), hasLength(3));
    });

    test('keeps archived accounts apart from the active ones', () async {
      await viewModel.load();

      await viewModel.archive(savings);

      expect(viewModel.active.single.account.id, bank.id);
      expect(viewModel.archived.single.account.id, savings.id);
      expect(viewModel.archived.single.balance, eur(30000));
    });

    test('restores an archived account', () async {
      await viewModel.archive(savings);

      await viewModel.restore(viewModel.archived.single.account);

      expect(viewModel.archived, isEmpty);
      expect(viewModel.active, hasLength(2));
    });

    test('removes an account and its records', () async {
      await viewModel.load();

      await viewModel.remove(savings);

      expect(viewModel.active.single.account.id, bank.id);
      expect(viewModel.active.single.balance, eur(150000));
      expect(await store.transfers.all(), isEmpty);
    });

    test('tells what removing an account takes with it', () async {
      await viewModel.load();

      final removal = viewModel.removalOf(savings);

      expect(removal.recordCount, 1);
    });

    test('tells which other balances a removal changes', () async {
      await viewModel.load();

      final changes = viewModel.balanceChangesOf(viewModel.removalOf(savings));

      expect(changes.single.account.id, bank.id);
      expect(changes.single.change, eur(30000));
    });

    test('lists no balance change for a removal that affects nobody', () async {
      await store.accounts.save(
        const Account(
          id: AccountId('cash'),
          name: 'Cash',
          currency: Currency.eur,
        ),
      );
      await viewModel.load();
      final cash = viewModel.active.first.account;

      expect(viewModel.balanceChangesOf(viewModel.removalOf(cash)), isEmpty);
    });
  });
}
