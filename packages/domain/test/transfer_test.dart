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
        Transfer(
          id: const TransferId('transfer'),
          dateTime: DateTime(2026, 11, 1),
          fromAccountId: bank.id,
          toAccountId: to.id,
          sent: eur(sentCents),
          received: received,
        );

    test('receives what was sent unless told otherwise', () {
      expect(transfer().received, eur(30000));
    });

    test('can receive a different amount in another currency', () {
      expect(transfer(to: broker, received: usd(32400)).received, usd(32400));
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
