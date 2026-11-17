import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'period_form_view_model.dart';

/// The state and the actions of the statistics: what I spent and earned
/// over a period, category by category, day by day and transaction by
/// transaction.
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
  CategoryId? _selectedCategoryId;

  List<Transaction> _transactions = const [];
  List<Category> _allCategories = const [];
  late PeriodStats _summary = PeriodStats(
    currency: currency,
    netByCategory: const {},
    sideOfCategory: const {},
  );
  List<CategoryAmount> _mainAmounts = const [];
  List<TrendPoint> _trend = const [];
  List<StatsEntry> _entries = const [];

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

  /// The side the categories are about: expenses or income.
  CategorySide get side => _side;

  set side(CategorySide side) {
    _side = side;
    _selectedCategoryId = null;
    _refresh();
  }

  /// The income, the expenses and what is left over the period.
  PeriodStats get summary => _summary;

  /// The main categories of [side] with something in them, the largest
  /// first.
  List<CategoryAmount> get amounts => _mainAmounts;

  /// What [amounts] add up to.
  Money get total => switch (_side) {
    CategorySide.expense => _summary.expenses,
    CategorySide.income => _summary.income,
    CategorySide.neutral => _summary.corrections,
  };

  /// The category that [trend] and [entries] are narrowed to, if any.
  CategoryAmount? get selected => _mainAmounts
      .where((amount) => amount.category.id == _selectedCategoryId)
      .firstOrNull;

  /// How the money built up day by day: what was earned minus what was
  /// spent so far, or what is in the selected category alone.
  List<TrendPoint> get trend => _trend;

  /// The transactions that count in the period, or those with something
  /// in the selected category, the latest first.
  List<StatsEntry> get entries => _entries;

  /// Narrows the trend and the transactions to the category of [amount],
  /// or stops doing so when it is the one already selected.
  void select(CategoryAmount amount) {
    final id = amount.category.id;
    _selectedCategoryId = id == _selectedCategoryId ? null : id;
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
    _selectedCategoryId = selected?.category.id;
    final isCounted = _isInSelectedCategory;
    _trend = _fromStartOf(
      range,
      calculator.trendFor(range, _transactions, where: isCounted),
    );
    _entries = calculator.entriesFor(range, _transactions, where: isCounted);
    notifyListeners();
  }

  /// Tells whether an item is in the selected category. Nothing when no
  /// category is selected, so that every item counts.
  bool Function(Item item)? get _isInSelectedCategory {
    final selectedId = _selectedCategoryId;
    if (selectedId == null) return null;
    final tree = CategoryTree(_allCategories);
    return (item) => tree.isWithin(item.categoryId, selectedId);
  }

  /// [trend] starting from nothing on the first day of [range], unless the
  /// period is everything, which starts with the first thing recorded.
  List<TrendPoint> _fromStartOf(DateRange range, List<TrendPoint> trend) {
    final startsLater =
        trend.isNotEmpty && trend.first.day.isAfter(range.start);
    if (_period is AllTime || !startsLater) return trend;
    return [TrendPoint(range.start, Money.zero(currency)), ...trend];
  }
}
