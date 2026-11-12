import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  const bank = Account(
    id: AccountId('bank'),
    name: 'Bank',
    currency: Currency.eur,
  );
  const broker = Account(
    id: AccountId('broker'),
    name: 'Broker',
    currency: Currency.jpy,
  );

  late AtomiFiDatabase database;
  late AccountRepository accounts;

  setUp(() {
    database = AtomiFiDatabase(NativeDatabase.memory());
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
        [Currency.eur, Currency.jpy],
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
