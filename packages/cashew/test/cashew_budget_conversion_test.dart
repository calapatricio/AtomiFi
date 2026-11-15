import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/backup.dart';

Money _eur(int cents) => Money(cents, Currency.eur);

List<Budget> _budgetsOf(CashewBackup backup) =>
    const CashewBackupConverter(defaultCurrencyCode: 'EUR')
        .convert(backup)
        .budgets;

void main() {
  group('The budgets of a Cashew backup', () {
    test('keep their id, name, limit and color', () {
      final imported = _budgetsOf(
        backup(budgets: [budget(colour: '0xff4caf50')]),
      ).single;

      expect(imported.id, const BudgetId('monthly'));
      expect(imported.name, 'Mensual');
      expect(imported.limit, _eur(120000));
      expect(imported.appearance, const Appearance(color: 0xFF4CAF50));
    });

    test('count in the currency of their wallet', () {
      final imported = _budgetsOf(
        backup(
          wallets: [wallet(), wallet(id: 'broker', currencyCode: 'usd')],
          budgets: [budget(walletId: 'broker')],
        ),
      ).single;

      expect(imported.limit, const Money(120000, Currency.usd));
    });

    test('count in the default currency when their wallet is gone', () {
      final imported = _budgetsOf(
        backup(budgets: [budget(walletId: '0')]),
      ).single;

      expect(imported.limit, _eur(120000));
    });

    test('start over as often as they did, from their first day', () {
      final imported = _budgetsOf(
        backup(
          budgets: [
            budget(
              periodLength: 2,
              reoccurrence: BackupReoccurrence.weekly,
              start: DateTime(2026, 11, 13, 9, 30),
            ),
          ],
        ),
      ).single;

      expect(
        (imported.period as RecurringPeriod).recurrence,
        Recurrence(
          every: 2,
          unit: RecurrenceUnit.week,
          anchor: DateTime(2026, 11, 13),
        ),
      );
    });

    test('cover one stretch of time when they did not repeat', () {
      final imported = _budgetsOf(
        backup(
          budgets: [
            budget(
              reoccurrence: BackupReoccurrence.custom,
              start: DateTime(2026, 8, 1),
              end: DateTime(2026, 8, 16),
            ),
          ],
        ),
      ).single;

      expect(
        (imported.period as FixedPeriod).range,
        DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 16)),
      );
    });

    test('count all spending when they name no categories', () {
      final imported = _budgetsOf(backup(budgets: [budget()])).single;

      expect((imported.scope as AllSpending).except, isEmpty);
    });

    test('leave out the categories they excluded', () {
      final imported = _budgetsOf(
        backup(
          categories: [category(), category(id: 'casino', name: 'Casinos')],
          budgets: [
            budget(excludedCategoryIds: ['casino', 'gone']),
          ],
        ),
      ).single;

      expect((imported.scope as AllSpending).except, {
        const CategoryId('casino'),
      });
    });

    test('count the categories they name, when those still exist', () {
      final imported = _budgetsOf(
        backup(
          budgets: [
            budget(categoryIds: ['food', 'gone']),
          ],
        ),
      ).single;

      expect((imported.scope as CategorySpending).categoryIds, {
        const CategoryId('food'),
      });
    });

    test('hold the items of the transactions added to them by hand', () {
      final imported = _budgetsOf(
        backup(
          transactions: [
            transaction(id: 'hotel', budgetId: 'trip'),
            transaction(id: 'gym'),
            transaction(id: 'unpaid', budgetId: 'trip', paid: false),
          ],
          budgets: [budget(id: 'trip', addedTransactionsOnly: true)],
        ),
      ).single;

      expect((imported.scope as ChosenItems).itemIds, {
        const ItemId('hotel-item'),
      });
    });

    test('are left out when archived, for saving or without a limit', () {
      final imported = _budgetsOf(
        backup(
          budgets: [
            budget(id: 'old', archived: true),
            budget(id: 'savings', income: true),
            budget(id: 'empty', amount: 0),
            budget(id: 'kept'),
          ],
        ),
      );

      expect(imported.map((budget) => budget.id), [const BudgetId('kept')]);
    });
  });

  group('The wallets of a Cashew backup', () {
    test('keep their emoji and whether they were archived', () {
      final account = const CashewBackupConverter(defaultCurrencyCode: 'EUR')
          .convert(backup(wallets: [wallet(emoji: '🏦', archived: true)]))
          .accounts
          .single;

      expect(account.appearance.emoji, '🏦');
      expect(account.isArchived, isTrue);
    });
  });
}
