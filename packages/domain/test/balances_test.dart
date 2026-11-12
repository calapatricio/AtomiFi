import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

Transfer _transfer(
  DateTime dateTime,
  Account from,
  Account to,
  Money sent, {
  Money? received,
}) =>
    Transfer(
      id: const TransferId('transfer'),
      dateTime: dateTime,
      fromAccountId: from.id,
      toAccountId: to.id,
      sent: sent,
      received: received,
    );

Revaluation _worth(DateTime dateTime, Account account, Money value) =>
    Revaluation(
      id: const RevaluationId('revaluation'),
      accountId: account.id,
      dateTime: dateTime,
      value: value,
    );

void main() {
  group('Balances', () {
    test('an account without records is empty', () {
      expect(Balances([]).balanceOf(bank), eur(0));
    });

    test('counts every transaction in full, shares of others included', () {
      final balances = Balances([
        on(DateTime(2026, 11, 1), [mine(150000, category: 'salary')]),
        on(DateTime(2026, 11, 7), [
          shared({me: -1250, moy: -1400}),
        ]),
      ]);

      expect(balances.balanceOf(bank), eur(147350));
    });

    test('keeps the records of each account apart', () {
      final balances = Balances([
        on(DateTime(2026, 11, 1), [mine(-500)]),
        on(DateTime(2026, 11, 1), [mine(-300)], account: savings),
      ]);

      expect(balances.balanceOf(savings), eur(-300));
    });

    test('can tell the balance at an earlier moment', () {
      final balances = Balances([
        on(DateTime(2026, 11, 1), [mine(-500)]),
        on(DateTime(2026, 11, 9), [mine(-300)]),
      ]);

      expect(balances.balanceOf(bank, at: DateTime(2026, 11, 1)), eur(-500));
    });

    test('a transfer moves money from one account to another', () {
      final balances = Balances([
        _transfer(DateTime(2026, 11, 1), bank, savings, eur(30000)),
      ]);

      expect(balances.balanceOf(bank), eur(-30000));
      expect(balances.balanceOf(savings), eur(30000));
    });

    test('a transfer can arrive in another currency', () {
      final balances = Balances([
        _transfer(
          DateTime(2026, 11, 1),
          bank,
          broker,
          eur(30000),
          received: usd(32400),
        ),
      ]);

      expect(balances.balanceOf(bank), eur(-30000));
      expect(balances.balanceOf(broker), usd(32400));
    });

    test('rejects a record in a currency the account does not hold', () {
      final balances = Balances([
        _transfer(DateTime(2026, 11, 1), bank, broker, eur(30000)),
      ]);

      expect(
        () => balances.balanceOf(broker),
        throwsA(isA<CurrencyMismatch>()),
      );
    });
  });

  group('Balances of a revalued account', () {
    final contributions = [
      _transfer(DateTime(2026, 10, 1), bank, savings, eur(10000)),
      _transfer(DateTime(2026, 10, 15), bank, savings, eur(10000)),
    ];
    final revaluation = _worth(DateTime(2026, 10, 20), savings, eur(21500));

    test('a revaluation sets the balance to the stated value', () {
      final balances = Balances([...contributions, revaluation]);

      expect(balances.balanceOf(savings), eur(21500));
    });

    test('later movements build on the stated value', () {
      final balances = Balances([
        ...contributions,
        revaluation,
        _transfer(DateTime(2026, 11, 1), bank, savings, eur(10000)),
      ]);

      expect(balances.balanceOf(savings), eur(31500));
    });

    test('separates what was contributed from what the market did', () {
      final balances = Balances([...contributions, revaluation]);

      expect(balances.contributedTo(savings), eur(20000));
      expect(balances.marketGainOf(savings), eur(1500));
    });

    test('applies records in date order, however they were entered', () {
      final balances = Balances([revaluation, ...contributions]);

      expect(balances.balanceOf(savings), eur(21500));
    });

    test('applies records of the same moment in the order entered', () {
      final moment = DateTime(2026, 10, 20);
      final contribution = _transfer(moment, bank, savings, eur(10000));
      final worth = _worth(moment, savings, eur(21500));

      expect(Balances([contribution, worth]).balanceOf(savings), eur(21500));
      expect(Balances([worth, contribution]).balanceOf(savings), eur(31500));
    });
  });

  group('Balances.netWorth', () {
    test('adds up all accounts in one currency', () {
      const rates = RateTable(
        base: Currency.eur,
        unitsPerBase: {Currency.usd: 1.08},
      );
      final balances = Balances([
        on(DateTime(2026, 11, 1), [mine(100000, category: 'salary')]),
        _transfer(
          DateTime(2026, 11, 2),
          bank,
          broker,
          eur(10000),
          received: usd(10800),
        ),
      ]);

      expect(
        balances.netWorth([bank, broker], Currency.eur, rates),
        eur(100000),
      );
    });
  });
}
