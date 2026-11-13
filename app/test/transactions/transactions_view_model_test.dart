import 'package:atomifi/transactions/transactions_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('TransactionsViewModel', () {
    late InMemoryStore store;
    late TransactionsViewModel viewModel;

    setUp(() async {
      store = await seededStore();
      viewModel = transactionsViewModelOn(store);
    });

    test('has no days when nothing was recorded', () async {
      await viewModel.load();

      expect(viewModel.days, isEmpty);
    });

    test('groups what happened by day, latest day first', () async {
      await store.transactions.save(
        spending('old', dateTime: DateTime(2026, 11, 5, 9)),
      );
      await store.transactions.save(
        spending('morning', dateTime: DateTime(2026, 11, 6, 9)),
      );
      await store.transactions.save(
        spending('evening', dateTime: DateTime(2026, 11, 6, 21)),
      );

      await viewModel.load();

      expect(viewModel.days.map((day) => day.date), [
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 5),
      ]);
      expect(viewModel.days.first.entries, hasLength(2));
    });

    test('lists the latest entry of a day first', () async {
      await store.transactions.save(
        spending('morning', dateTime: DateTime(2026, 11, 6, 9)),
      );
      await store.transactions.save(
        spending('evening', dateTime: DateTime(2026, 11, 6, 21)),
      );

      await viewModel.load();

      final entries = viewModel.days.single.entries.cast<TransactionEntry>();

      expect(entries.map((entry) => entry.transaction.id), const [
        TransactionId('evening'),
        TransactionId('morning'),
      ]);
    });

    test('shows a transaction with its account and categories', () async {
      Item item(String id, Category category) => Item.mine(
        id: ItemId(id),
        name: id,
        categoryId: category.id,
        price: eur(-500),
      );
      await store.transactions.save(
        Transaction(
          id: const TransactionId('party'),
          name: 'Party',
          dateTime: DateTime(2026, 11, 6, 20, 30),
          accountId: bank.id,
          items: [
            item('rum', alcohol),
            item('bananas', food),
            item('beer', alcohol),
          ],
        ),
      );

      await viewModel.load();

      final entry = viewModel.days.single.entries.single as TransactionEntry;

      expect(entry.account.id, bank.id);
      expect(entry.categories.map((category) => category.id), [
        alcohol.id,
        food.id,
      ]);
    });

    test('shows a transfer with the accounts it moves money between', () async {
      await store.transfers.save(transfer('deposit', bank, savings, 30000));

      await viewModel.load();

      final entry = viewModel.days.single.entries.single as TransferEntry;

      expect(entry.from.id, bank.id);
      expect(entry.to.id, savings.id);
      expect(viewModel.days.single.date, DateTime(2026, 11, 2));
    });

    test('shows a revaluation with its account', () async {
      await store.revaluations.save(
        Revaluation(
          id: const RevaluationId('worth'),
          accountId: savings.id,
          dateTime: DateTime(2026, 11, 3, 18),
          value: eur(32500),
        ),
      );

      await viewModel.load();

      final entry = viewModel.days.single.entries.single as RevaluationEntry;

      expect(entry.account.id, savings.id);
      expect(entry.revaluation.value, eur(32500));
    });

    test('tells its listeners when it has loaded', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(notifications, 1);
    });
  });
}
