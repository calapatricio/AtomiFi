import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

Transfer _toBroker() => Transfer(
      id: const TransferId('dca'),
      note: 'Fortnightly',
      outgoing: TransferLeg(
        accountId: bank.id,
        dateTime: DateTime(2026, 11, 1, 9),
        amount: eur(30000),
      ),
      incoming: TransferLeg(
        accountId: broker.id,
        dateTime: DateTime(2026, 11, 3, 14),
        amount: usd(32400),
      ),
    );

void main() {
  late AtomiFiDatabase database;
  late TransferRepository transfers;

  setUp(() async {
    database = await openSeededDatabase();
    transfers = DriftTransferRepository(database);
  });

  tearDown(() => database.close());

  group('DriftTransferRepository', () {
    test('starts without transfers', () async {
      expect(await transfers.all(), isEmpty);
    });

    test('restores the record of each account', () async {
      await transfers.save(_toBroker());

      final restored = (await transfers.all()).single;

      expect(restored.id, const TransferId('dca'));
      expect(restored.note, 'Fortnightly');
      expect(restored.outgoing.accountId, bank.id);
      expect(restored.outgoing.dateTime, DateTime(2026, 11, 1, 9));
      expect(restored.outgoing.amount, eur(30000));
      expect(restored.incoming.accountId, broker.id);
      expect(restored.incoming.dateTime, DateTime(2026, 11, 3, 14));
      expect(restored.incoming.amount, usd(32400));
    });

    test('saving a transfer again replaces it', () async {
      await transfers.save(_toBroker());
      await transfers.save(
        Transfer(
          id: const TransferId('dca'),
          outgoing: TransferLeg(
            accountId: bank.id,
            dateTime: DateTime(2026, 11, 1),
            amount: eur(10000),
          ),
          incoming: TransferLeg(
            accountId: savings.id,
            dateTime: DateTime(2026, 11, 1),
            amount: eur(10000),
          ),
        ),
      );

      final restored = (await transfers.all()).single;

      expect(restored.incoming.accountId, savings.id);
      expect(restored.incoming.amount, eur(10000));
    });

    test('removes a transfer', () async {
      await transfers.save(_toBroker());

      await transfers.remove(const TransferId('dca'));

      expect(await transfers.all(), isEmpty);
    });
  });
}
