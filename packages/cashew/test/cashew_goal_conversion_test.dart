import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/backup.dart';

List<Goal> _goalsOf(CashewBackup backup) =>
    const CashewBackupConverter(defaultCurrencyCode: 'EUR')
        .convert(backup)
        .goals;

void main() {
  group('The goals of a Cashew backup', () {
    test('keep their id, name, target, deadline and looks', () {
      final imported = _goalsOf(
        backup(
          goals: [
            goal(
              end: DateTime(2026, 12, 31),
              colour: '0xff4caf50',
              iconName: 'pizza.png',
              emoji: '🍕',
            ),
          ],
        ),
      ).single;

      expect(imported.id, const GoalId('pizza'));
      expect(imported.name, 'Objetivo Pizza');
      expect(imported.target, const Money(50000, Currency.eur));
      expect(imported.deadline, DateTime(2026, 12, 31));
      expect(
        imported.appearance,
        const Appearance(color: 0xFF4CAF50, iconName: 'pizza', emoji: '🍕'),
      );
    });

    test('are for saving or for spending, as they were', () {
      final imported = _goalsOf(
        backup(
          goals: [
            goal(id: 'save', income: true),
            goal(id: 'spend', income: false),
          ],
        ),
      );

      expect(imported.map((goal) => goal.kind), [
        GoalKind.saving,
        GoalKind.spending,
      ]);
    });

    test('count in the currency of their wallet', () {
      final imported = _goalsOf(
        backup(
          wallets: [wallet(), wallet(id: 'broker', currencyCode: 'usd')],
          goals: [goal(walletId: 'broker')],
        ),
      ).single;

      expect(imported.target, const Money(50000, Currency.usd));
    });

    test('hold the items of the transactions that counted towards them', () {
      final imported = _goalsOf(
        backup(
          transactions: [
            transaction(id: 'bonus', amount: 200, goalId: 'pizza'),
            transaction(id: 'gym'),
            transaction(id: 'later', goalId: 'pizza', paid: false),
          ],
          goals: [goal()],
        ),
      ).single;

      expect(imported.itemIds, {const ItemId('bonus-item')});
    });

    test('are left out when archived, when loans or without a target', () {
      final imported = _goalsOf(
        backup(
          goals: [
            goal(id: 'old', archived: true),
            goal(id: 'loan', isLoan: true),
            goal(id: 'empty', amount: 0),
            goal(id: 'kept'),
          ],
        ),
      );

      expect(imported.map((goal) => goal.id), [const GoalId('kept')]);
    });
  });
}
