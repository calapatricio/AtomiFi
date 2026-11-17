import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'period_form_view_model.dart';

/// The state and the actions of the statistics: what I spent and earned
/// over a period, category by category and day by day.
final class StatsViewModel extends ChangeNotifier {
  StatsViewModel({
    required this._ledger,
    required this._categories,
    required this.currency,
    required this._now,
  });

  final Ledger _ledger;
  final CategoryRepository _categories;
  final DateTime Function() _now;

  /// The currency every figure is given in.
  final Currency currency;

  StatsPeriod _period = RepeatingPeriod(Recurrence.calendarMonths);
  late DateTime _moment = _now();
  CategorySide _side = CategorySide.expense;
  CategoryId? _openCategoryId;

  List<Transaction> _transactions = const [];
  List<Category> _allCategories = const [];
  late PeriodStats _summary = PeriodStats(
    currency: currency,
    netByCategory: const {},
    sideOfCategory: const {},
  );
  List<CategoryAmount> _mainAmounts = const [];
  List<TrendPoint> _trend = const [];

  StatsPeriod get period => _period;

  /// Choosing a period shows the one today falls in.
  set period(StatsPeriod period) {
    _period = period;
    _moment = _now();
    _refresh();
  }

  /// The dates the figures cover.
  DateRange get range => _period.rangeAt(_moment);

  /// Whether there is a period before and after the one shown.
  bool get canStep => _period is RepeatingPeriod;

  void showPrevious() {
    final start = range.start;
    _moment = DateTime(start.year, start.month, start.day - 1);
    _refresh();
  }

  void showNext() {
    _moment = range.end;
    _refresh();
  }

  /// The side the categories and the trend are about: expenses or income.
  CategorySide get side => _side;

  set side(CategorySide side) {
    _side = side;
    _openCategoryId = null;
    _refresh();
  }

  /// The income, the expenses and what is left over the period.
  PeriodStats get summary => _summary;

  /// The category being looked into, if any.
  CategoryAmount? get openCategory => _mainAmounts
      .where(
        (amount) =>
            amount.category.id == _openCategoryId && amount.parts.isNotEmpty,
      )
      .firstOrNull;

  /// The parts of the category being looked into, or else the main
  /// categories, the largest first.
  List<CategoryAmount> get amounts => openCategory?.parts ?? _mainAmounts;

  /// What [amounts] add up to.
  Money get total =>
      openCategory?.amount ??
      switch (_side) {
        CategorySide.expense => _summary.expenses,
        CategorySide.income => _summary.income,
        CategorySide.neutral => _summary.corrections,
      };

  /// How [total] built up day by day.
  List<TrendPoint> get trend => _trend;

  /// Looks into the category of [amount], when it has subcategories with
  /// something in them.
  void open(CategoryAmount amount) {
    if (amount.parts.isEmpty) return;
    _openCategoryId = amount.category.id;
    _refresh();
  }

  /// Goes back to the main categories.
  void close() {
    _openCategoryId = null;
    _refresh();
  }

  /// A form to choose another period, starting from the one shown.
  PeriodFormViewModel periodForm() =>
      PeriodFormViewModel(current: _period, now: _now);

  Future<void> load() async {
    _transactions = (await _ledger.snapshot()).transactions;
    _allCategories = await _categories.all();
    _refresh();
  }

  void _refresh() {
    final calculator = StatsCalculator(
      categories: _allCategories,
      currency: currency,
    );
    final range = this.range;
    _summary = calculator.statsFor(range, _transactions);
    _mainAmounts = CategoryBreakdown(_allCategories).of(_summary, _side);
    _openCategoryId = openCategory?.category.id;
    _trend = _fromStartOf(
      range,
      calculator.trendFor(
        range,
        _transactions,
        _side,
        where: _isInOpenCategory,
      ),
    );
    notifyListeners();
  }

  /// Tells whether an item is in the category being looked into. Nothing
  /// when no category is, so that every item counts.
  bool Function(Item item)? get _isInOpenCategory {
    final openCategoryId = _openCategoryId;
    if (openCategoryId == null) return null;
    final tree = CategoryTree(_allCategories);
    return (item) => tree.isWithin(item.categoryId, openCategoryId);
  }

  /// [trend] starting from nothing on the first day of [range], unless the
  /// period is everything, which starts with the first thing recorded.
  List<TrendPoint> _fromStartOf(DateRange range, List<TrendPoint> trend) {
    final startsLater = trend.isNotEmpty && trend.first.day.isAfter(range.start);
    if (_period is AllTime || !startsLater) return trend;
    return [TrendPoint(range.start, Money.zero(currency)), ...trend];
  }
}
