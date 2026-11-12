import '../category/category.dart';
import '../ids.dart';
import '../ledger/item.dart';
import '../ledger/transaction.dart';
import '../money/currency.dart';
import '../money/currency_converter.dart';
import '../money/money.dart';
import '../money/rate_table.dart';
import 'date_range.dart';
import 'period_stats.dart';

/// The date on which an item that offsets an earlier one enters the stats.
enum OffsetDating {
  /// On the date of the item it offsets, so both net out in one period.
  originalItemDate,

  /// On the date of its own transaction.
  ownDate,
}

/// Works out the user's own spending and income.
///
/// Shares borne by other people never count. Amounts are netted per category
/// after converting them to [currency].
final class StatsCalculator {
  StatsCalculator({
    required Iterable<Category> categories,
    required this.currency,
    this.offsetDating = OffsetDating.originalItemDate,
    CurrencyConverter? converter,
  })  : _converter = converter ?? RateTable(base: currency),
        _sideOfCategory = {
          for (final category in categories) category.id: category.side,
        };

  final Currency currency;
  final OffsetDating offsetDating;
  final CurrencyConverter _converter;
  final Map<CategoryId, CategorySide> _sideOfCategory;

  PeriodStats statsFor(DateRange period, List<Transaction> ledger) {
    final dateOfItem = _datesByItem(ledger);
    final netByCategory = <CategoryId, Money>{};
    for (final transaction in ledger) {
      for (final item in transaction.items) {
        final date = _statsDate(item, transaction.dateTime, dateOfItem);
        if (item.ownAmount.isZero || !period.contains(date)) continue;
        _requireKnownCategory(item.categoryId);
        final own = _converter.convert(item.ownAmount, currency);
        netByCategory.update(
          item.categoryId,
          (net) => net + own,
          ifAbsent: () => own,
        );
      }
    }
    return PeriodStats(
      currency: currency,
      netByCategory: netByCategory,
      sideOfCategory: _sideOfCategory,
    );
  }

  DateTime _statsDate(
    Item item,
    DateTime ownDate,
    Map<ItemId, DateTime> dateOfItem,
  ) {
    if (offsetDating == OffsetDating.ownDate) return ownDate;
    return dateOfItem[item.offsets] ?? ownDate;
  }

  void _requireKnownCategory(CategoryId categoryId) {
    if (!_sideOfCategory.containsKey(categoryId)) {
      throw ArgumentError.value(categoryId, 'categoryId', 'unknown category');
    }
  }

  static Map<ItemId, DateTime> _datesByItem(List<Transaction> ledger) => {
        for (final transaction in ledger)
          for (final item in transaction.items) item.id: transaction.dateTime,
      };
}
