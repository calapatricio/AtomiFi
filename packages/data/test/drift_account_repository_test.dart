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
}
