import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Ledger', () {
    late InMemoryStore store;
    late Ledger ledger;

    setUp(() {
      store = InMemoryStore();
      ledger = Ledger(
        transactions: store.transactions,
        transfers: store.transfers,
        revaluations: store.revaluations,
      );
    });

    test('is empty when nothing was recorded', () async {
      expect((await ledger.snapshot()).records, isEmpty);
    });

    test('gathers the transactions, transfers and revaluations', () async {
      final groceries = on(DateTime(2026, 6, 21), [mine(-1500)]);
      final deposit = moved(
        eur(30000),
        from: bank,
        to: savings,
        on: DateTime(2026, 6, 1),
      );
      final worth = Revaluation(
        id: const RevaluationId('worth'),
        accountId: savings.id,
        dateTime: DateTime(2026, 6, 30),
        value: eur(32500),
      );
      await store.transactions.save(groceries);
      await store.transfers.save(deposit);
      await store.revaluations.save(worth);

      final snapshot = await ledger.snapshot();

      expect(snapshot.transactions, [groceries]);
      expect(snapshot.transfers, [deposit]);
      expect(snapshot.revaluations, [worth]);
      expect(snapshot.records, [groceries, deposit, worth]);
    });
  });

  group('InMemoryStore', () {
    test('removing an account removes its records, as a database does',
        () async {
      final store = InMemoryStore();
      await store.accounts.save(bank);
      await store.accounts.save(savings);
      await store.transactions.save(on(DateTime(2026, 6, 21), [mine(-1500)]));
      await store.transfers.save(
        moved(eur(30000), from: bank, to: savings, on: DateTime(2026, 6, 1)),
      );

      await store.accounts.remove(bank.id);

      expect((await store.accounts.all()).single.id, savings.id);
      expect(await store.transactions.all(), isEmpty);
      expect(await store.transfers.all(), isEmpty);
    });
  });
}
