import 'dart:collection';

import 'package:collection/collection.dart';

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
import 'stats_entry.dart';
import 'trend_point.dart';

/// The date on which an item that offsets an earlier one enters the stats.
enum OffsetDating {
  /// On the date of the item it offsets, so both net out in one period.
  originalItemDate,

  /// On the date of its own transaction.
  ownDate,
}

typedef _OwnAmount = ({
  Transaction transaction,
  DateTime date,
  CategoryId categoryId,
  Money amount,
});

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

  /// How my money built up over [period]: what was earned minus what was
  /// spent so far on each day that changed it, earliest first. Only the
  /// items that [where] accepts count when it is given.
  List<TrendPoint> trendFor(
    DateRange period,
    List<Transaction> ledger, {
    bool Function(Item item)? where,
  }) {
    final changeByDay = SplayTreeMap<DateTime, Money>();
    for (final own in _earnedOrSpent(period, ledger, where)) {
      changeByDay.update(
        DateTime(own.date.year, own.date.month, own.date.day),
        (sum) => sum + own.amount,
        ifAbsent: () => own.amount,
      );
    }
    var total = Money.zero(currency);
    return [
      for (final MapEntry(key: day, value: change) in changeByDay.entries)
        TrendPoint(day, total += change),
    ];
  }

  /// The transactions that count as income or spending in [period], the
  /// latest first, each with my share of its items. Only the items that
  /// [where] accepts count when it is given.
  List<StatsEntry> entriesFor(
    DateRange period,
    List<Transaction> ledger, {
    bool Function(Item item)? where,
  }) {
    final entryByKey = <(TransactionId, DateTime), StatsEntry>{};
    for (final own in _earnedOrSpent(period, ledger, where)) {
      entryByKey.update(
        (own.transaction.id, own.date),
        (entry) => entry.plus(own.amount),
        ifAbsent: () => StatsEntry(
          transaction: own.transaction,
          date: own.date,
          amount: own.amount,
        ),
      );
    }
    final entries = entryByKey.values.toList();
    mergeSort(entries, compare: (a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// My share of the items that are income or spending in [period].
  Iterable<_OwnAmount> _earnedOrSpent(
    DateRange period,
    List<Transaction> ledger,
    bool Function(Item item)? where,
  ) =>
      _ownAmounts(period, ledger, where).where(
        (own) => _sideOfCategory[own.categoryId] != CategorySide.neutral,
      );

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
          transaction: transaction,
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
