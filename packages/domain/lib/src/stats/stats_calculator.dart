import 'dart:collection';

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
import 'trend_point.dart';

/// The date on which an item that offsets an earlier one enters the stats.
enum OffsetDating {
  /// On the date of the item it offsets, so both net out in one period.
  originalItemDate,

  /// On the date of its own transaction.
  ownDate,
}

typedef _OwnAmount = ({DateTime date, CategoryId categoryId, Money amount});

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

  /// The stats of [period], counting only the items that [where] accepts
  /// when it is given.
  PeriodStats statsFor(
    DateRange period,
    List<Transaction> ledger, {
    bool Function(Item item)? where,
  }) {
    final netByCategory = <CategoryId, Money>{};
    for (final own in _ownAmounts(period, ledger, where)) {
      netByCategory.update(
        own.categoryId,
        (net) => net + own.amount,
        ifAbsent: () => own.amount,
      );
    }
    return PeriodStats(
      currency: currency,
      netByCategory: netByCategory,
      sideOfCategory: _sideOfCategory,
    );
  }

  /// How the total of [side] built up over [period]: the total so far on
  /// each day that changed it, earliest first. Only the items that [where]
  /// accepts count when it is given.
  List<TrendPoint> trendFor(
    DateRange period,
    List<Transaction> ledger,
    CategorySide side, {
    bool Function(Item item)? where,
  }) {
    final changeByDay = SplayTreeMap<DateTime, Money>();
    for (final own in _ownAmounts(period, ledger, where)) {
      if (_sideOfCategory[own.categoryId] != side) continue;
      final change = side == CategorySide.expense ? -own.amount : own.amount;
      changeByDay.update(
        DateTime(own.date.year, own.date.month, own.date.day),
        (sum) => sum + change,
        ifAbsent: () => change,
      );
    }
    var total = Money.zero(currency);
    return [
      for (final MapEntry(key: day, value: change) in changeByDay.entries)
        TrendPoint(day, total += change),
    ];
  }

  /// My share of each item that counts in [period], in [currency], with
  /// the date it counts on.
  Iterable<_OwnAmount> _ownAmounts(
    DateRange period,
    List<Transaction> ledger,
    bool Function(Item item)? where,
  ) sync* {
    final dateOfItem = _datesByItem(ledger);
    for (final transaction in ledger) {
      for (final item in transaction.items) {
        final date = _statsDate(item, transaction.dateTime, dateOfItem);
        if (item.ownAmount.isZero || !period.contains(date)) continue;
        if (where != null && !where(item)) continue;
        _requireKnownCategory(item.categoryId);
        yield (
          date: date,
          categoryId: item.categoryId,
          amount: _converter.convert(item.ownAmount, currency),
        );
      }
    }
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
