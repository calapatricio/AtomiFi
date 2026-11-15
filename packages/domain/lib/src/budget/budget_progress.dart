import '../category/category.dart';
import '../category/category_tree.dart';
import '../ledger/transaction.dart';
import '../money/currency_converter.dart';
import '../money/money.dart';
import '../stats/date_range.dart';
import '../stats/stats_calculator.dart';
import 'budget.dart';

/// How a budget stands in one of its periods.
final class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.range,
    required this.spent,
  });

  final Budget budget;

  /// The period this progress is about.
  final DateRange range;

  /// What was spent, as a positive amount. Only my own share of each item
  /// counts, and refunds are taken off.
  final Money spent;

  Money get remaining => budget.limit - spent;

  bool get isOverspent => remaining.isNegative;
}

/// Works out how budgets stand.
final class BudgetProgressCalculator {
  BudgetProgressCalculator({
    required Iterable<Category> categories,
    CurrencyConverter? converter,
  })  : _categories = categories.toList(),
        _converter = converter;

  final List<Category> _categories;
  final CurrencyConverter? _converter;

  /// How [budget] stands in the period that [at] falls in.
  BudgetProgress progressOf(
    Budget budget,
    List<Transaction> ledger, {
    required DateTime at,
  }) {
    final range = budget.period.rangeAt(at);
    final tree = CategoryTree(_categories);
    final stats = StatsCalculator(
      categories: _categories,
      currency: budget.limit.currency,
      converter: _converter,
    ).statsFor(
      range,
      ledger,
      where: (item) => budget.scope.covers(item, tree),
    );
    return BudgetProgress(budget: budget, range: range, spent: stats.expenses);
  }
}
