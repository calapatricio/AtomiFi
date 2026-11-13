import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  late AtomiFiDatabase database;
  late AccountRepository accounts;

  setUp(() {
    database = openDatabase();
    accounts = DriftAccountRepository(database);
  });

  tearDown(() => database.close());

  group('DriftAccountRepository', () {
    test('starts without accounts', () async {
      expect(await accounts.all(), isEmpty);
    });

    test('returns the accounts it saved, ordered by name', () async {
      await accounts.save(broker);
      await accounts.save(bank);

      final saved = await accounts.all();

      expect(saved.map((account) => account.id), [bank.id, broker.id]);
      expect(saved.map((account) => account.name), ['Bank', 'Broker']);
      expect(
        saved.map((account) => account.currency),
        [Currency.eur, Currency.usd],
      );
    });

    test('restores how an account looks', () async {
      const looks = Appearance(color: 0xFF607D8B, iconName: 'bank');
      await accounts.save(
        const Account(
          id: AccountId('bank'),
          name: 'Bank',
          currency: Currency.eur,
          appearance: looks,
        ),
      );

      expect((await accounts.all()).single.appearance, looks);
    });

    test('restores whether an account is archived', () async {
      await accounts.save(bank.archived());
      await accounts.save(savings);

      final saved = await accounts.all();

      expect(saved.map((account) => account.isArchived), [true, false]);
    });

    test('saving an account again replaces it', () async {
      await accounts.save(bank);
      await accounts.save(
        const Account(
          id: AccountId('bank'),
          name: 'Main bank',
          currency: Currency.eur,
        ),
      );

      expect((await accounts.all()).single.name, 'Main bank');
    });
  });

  group('DriftAccountRepository.remove', () {
    late AtomiFiDatabase database;
    late AccountRepository accounts;
    late TransactionRepository transactions;
    late TransferRepository transfers;
    late RevaluationRepository revaluations;

    Transaction spending(String id, Account account) => Transaction(
          id: TransactionId(id),
          name: 'Spending',
          dateTime: DateTime(2026, 6, 21),
          accountId: account.id,
          items: [
            Item(
              id: ItemId('$id-item'),
              name: 'Dinner',
              categoryId: food.id,
              shares: [
                Share(const Me(), eur(-1000)),
                Share(moy, eur(-500)),
              ],
            ),
          ],
        );

    Transfer transfer(String id, Account from, Account to) => Transfer(
          id: TransferId(id),
          outgoing: TransferLeg(
            accountId: from.id,
            dateTime: DateTime(2026, 6, 1),
            amount: eur(30000),
          ),
          incoming: TransferLeg(
            accountId: to.id,
            dateTime: DateTime(2026, 6, 1),
            amount: eur(30000),
          ),
        );

    setUp(() async {
      database = await openSeededDatabase();
      accounts = DriftAccountRepository(database);
      transactions = DriftTransactionRepository(database);
      transfers = DriftTransferRepository(database);
      revaluations = DriftRevaluationRepository(database);
      await transactions.save(spending('in-savings', savings));
      await transactions.save(spending('in-bank', bank));
      await transfers.save(transfer('deposit', bank, savings));
      await transfers.save(transfer('withdrawal', savings, bank));
      await transfers.save(transfer('elsewhere', bank, broker));
      await revaluations.save(
        Revaluation(
          id: const RevaluationId('worth'),
          accountId: savings.id,
          dateTime: DateTime(2026, 6, 30),
          value: eur(32500),
        ),
      );
    });

    tearDown(() => database.close());

    test('removes the account', () async {
      await accounts.remove(savings.id);

      final left = await accounts.all();

      expect(left.map((account) => account.id), [bank.id, broker.id]);
    });

    test('removes its transactions with their items and shares', () async {
      await accounts.remove(savings.id);

      final left = await transactions.all();

      expect(left.single.id, const TransactionId('in-bank'));
      expect(await database.select(database.items).get(), hasLength(1));
      expect(await database.select(database.shares).get(), hasLength(2));
    });

    test('removes its revaluations', () async {
      await accounts.remove(savings.id);

      expect(await revaluations.all(), isEmpty);
    });

    test('removes the transfers it sent or received, and no others', () async {
      await accounts.remove(savings.id);

      final left = await transfers.all();

      expect(left.single.id, const TransferId('elsewhere'));
    });
  });
}
