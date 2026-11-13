import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('AccountRemoval', () {
    final deposit = moved(
      eur(30000),
      from: bank,
      to: savings,
      on: DateTime(2026, 6, 1),
    );
    final withdrawal = moved(
      eur(5000),
      from: savings,
      to: bank,
      on: DateTime(2026, 7, 1),
    );
    final bonus = on(
      DateTime(2026, 6, 20),
      [mine(2000, category: 'salary')],
      account: savings,
    );
    final groceries = on(DateTime(2026, 6, 21), [mine(-1500)]);
    final worth = Revaluation(
      id: const RevaluationId('worth'),
      accountId: savings.id,
      dateTime: DateTime(2026, 6, 30),
      value: eur(32500),
    );

    AccountRemoval removalOf(Account account) => AccountRemoval(
          account: account,
          transactions: [bonus, groceries],
          transfers: [deposit, withdrawal],
          revaluations: [worth],
        );

    test('removes the transactions and revaluations of the account', () {
      final removal = removalOf(savings);

      expect(removal.transactions, [bonus]);
      expect(removal.revaluations, [worth]);
    });

    test('removes the transfers the account sent or received', () {
      expect(removalOf(savings).transfers, [deposit, withdrawal]);
    });

    test('counts every record that goes', () {
      expect(removalOf(savings).recordCount, 4);
    });

    test('tells how the balance of another account changes', () {
      expect(removalOf(savings).balanceChangeOf(bank), eur(25000));
    });

    test('changes nothing in an account it shares no transfer with', () {
      expect(removalOf(savings).balanceChangeOf(broker), usd(0));
    });
  });
}
