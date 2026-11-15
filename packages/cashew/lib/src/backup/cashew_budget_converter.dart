import 'dart:math' as math;

import 'package:atomifi_domain/atomifi_domain.dart';

import 'cashew_backup.dart';

/// How an account, a category or a budget of Cashew looks.
Appearance appearanceOf(String? colour, String? iconName, String? emoji) =>
    Appearance(
      color: colour == null ? null : int.tryParse(colour),
      iconName: iconName?.replaceFirst(RegExp(r'\.png$'), ''),
      emoji: emoji,
    );

/// Turns the budgets of a Cashew backup into ours.
///
/// Archived budgets, budgets for saving and budgets without a limit are
/// left out.
final class CashewBudgetConverter {
  CashewBudgetConverter({
    required List<Account> accounts,
    required List<Category> categories,
    required Currency defaultCurrency,
  })  : _currencyByAccountId = {
          for (final account in accounts) account.id.value: account.currency,
        },
        _categoryIds = {for (final category in categories) category.id},
        _defaultCurrency = defaultCurrency;

  final Map<String, Currency> _currencyByAccountId;
  final Set<CategoryId> _categoryIds;
  final Currency _defaultCurrency;

  /// The [budgets] as ours. [budgetByItem] tells which budget each imported
  /// item was added to by hand.
  List<Budget> convert(
    List<BackupBudget> budgets,
    Map<ItemId, String> budgetByItem,
  ) =>
      [
        for (final budget in budgets)
          if (_isKept(budget)) _budgetOf(budget, budgetByItem),
      ];

  bool _isKept(BackupBudget budget) =>
      !budget.archived && !budget.income && !_limitOf(budget).isZero;

  Budget _budgetOf(BackupBudget budget, Map<ItemId, String> budgetByItem) =>
      Budget(
        id: BudgetId(budget.id),
        name: budget.name,
        limit: _limitOf(budget),
        period: _periodOf(budget),
        scope: _scopeOf(budget, budgetByItem),
        appearance: appearanceOf(budget.colour, null, null),
      );

  Money _limitOf(BackupBudget budget) {
    final currency = _currencyByAccountId[budget.walletId] ?? _defaultCurrency;
    final scale = math.pow(10, currency.decimals);
    return Money((budget.amount.abs() * scale).round(), currency);
  }

  static BudgetPeriod _periodOf(BackupBudget budget) {
    final unit = switch (budget.reoccurrence) {
      BackupReoccurrence.custom => null,
      BackupReoccurrence.daily => RecurrenceUnit.day,
      BackupReoccurrence.weekly => RecurrenceUnit.week,
      BackupReoccurrence.monthly => RecurrenceUnit.month,
      BackupReoccurrence.yearly => RecurrenceUnit.year,
    };
    if (unit == null) return FixedPeriod(_spanOf(budget));
    return RecurringPeriod(
      Recurrence(
        every: math.max(1, budget.periodLength),
        unit: unit,
        anchor: budget.start,
      ),
    );
  }

  /// The stretch of time of a budget that does not start over. One whose
  /// end is not after its start is taken to last a single day.
  static DateRange _spanOf(BackupBudget budget) {
    final start = budget.start;
    final end = budget.end.isAfter(start)
        ? budget.end
        : DateTime(start.year, start.month, start.day + 1);
    return DateRange(start, end);
  }

  BudgetScope _scopeOf(BackupBudget budget, Map<ItemId, String> budgetByItem) {
    if (budget.addedTransactionsOnly) {
      return ChosenItems({
        for (final MapEntry(key: itemId, value: budgetId)
            in budgetByItem.entries)
          if (budgetId == budget.id) itemId,
      });
    }
    final named = _known(budget.categoryIds);
    return named.isEmpty
        ? AllSpending(except: _known(budget.excludedCategoryIds))
        : CategorySpending(named);
  }

  /// The categories with these ids that are in the backup.
  Set<CategoryId> _known(List<String> ids) =>
      {for (final id in ids) CategoryId(id)}.intersection(_categoryIds);
}
