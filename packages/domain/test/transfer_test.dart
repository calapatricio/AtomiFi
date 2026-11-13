import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Transfer', () {
    Transfer transfer({
      Account to = savings,
      int sentCents = 30000,
      Money? received,
    }) =>
        moved(
          eur(sentCents),
          from: bank,
          to: to,
          on: DateTime(2026, 11, 1),
          arriving: DateTime(2026, 11, 2),
          received: received,
        );

    test('keeps one record for each account, with its own date', () {
      final toSavings = transfer();

      expect(toSavings.outgoing.accountId, bank.id);
      expect(toSavings.outgoing.dateTime, DateTime(2026, 11, 1));
      expect(toSavings.incoming.accountId, savings.id);
      expect(toSavings.incoming.dateTime, DateTime(2026, 11, 2));
    });

    test('can receive a different amount in another currency', () {
      final toBroker = transfer(to: broker, received: usd(32400));

      expect(toBroker.outgoing.amount, eur(30000));
      expect(toBroker.incoming.amount, usd(32400));
    });

    test('involves the two accounts it moves money between', () {
      final toSavings = transfer();

      expect(toSavings.involves(bank.id), isTrue);
      expect(toSavings.involves(savings.id), isTrue);
      expect(toSavings.involves(broker.id), isFalse);
    });

    test('rejects a transfer from an account to itself', () {
      expect(() => transfer(to: bank), throwsArgumentError);
    });

    test('rejects amounts that are not positive', () {
      expect(() => transfer(sentCents: 0), throwsArgumentError);
      expect(() => transfer(received: eur(-1)), throwsArgumentError);
    });
  });
}
