import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// What a budget counts, as the form offers it.
enum BudgetCoverage { allSpending, categories, chosenItems }

/// The state and the actions of the form that adds or edits a budget.
final class BudgetFormViewModel extends ChangeNotifier {
  BudgetFormViewModel({
    required this._budgets,
    required this._categories,
    required Currency currency,
    required this._newId,
    required DateTime Function() now,
    Budget? existing,
  }) : _existing = existing,
       currency = existing?.limit.currency ?? currency,
       _name = existing?.name ?? '',
       _limit = existing?.limit.toDecimalString() ?? '',
       _start = _firstDayOfMonth(now()) {
    _end = DateTime(_start.year, _start.month + 1, 0);
    if (existing != null) {
      _takePeriodOf(existing);
      _takeScopeOf(existing);
    }
  }

  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final String Function() _newId;
  final Budget? _existing;

  /// The currency the limit is typed in.
  final Currency currency;

  String _name;
  String _limit;
  bool _repeats = true;
  String _every = '1';
  RecurrenceUnit _unit = RecurrenceUnit.month;
  DateTime _start;
  late DateTime _end;
  BudgetCoverage _coverage = BudgetCoverage.allSpending;
  final _categoryIds = <CategoryId>{};
  List<Category> _mainCategories = const [];

  /// Whether the form changes a budget instead of adding one.
  bool get isEditing => _existing != null;

  String get name => _name;

  set name(String name) => _change(() => _name = name);

  /// The limit as typed.
  String get limit => _limit;

  set limit(String limit) => _change(() => _limit = limit);

  /// Whether the budget starts over, or is one stretch of time.
  bool get repeats => _repeats;

  set repeats(bool repeats) => _change(() => _repeats = repeats);

  /// How many [unit]s each period lasts, as typed.
  String get every => _every;

  set every(String every) => _change(() => _every = every);

  RecurrenceUnit get unit => _unit;

  set unit(RecurrenceUnit unit) => _change(() => _unit = unit);

  /// The first day of a period, or of the only one when it does not repeat.
  DateTime get start => _start;

  set start(DateTime start) => _change(() => _start = start);

  /// The last day of a budget that does not repeat.
  DateTime get end => _end;

  set end(DateTime end) => _change(() => _end = end);

  BudgetCoverage get coverage => _coverage;

  set coverage(BudgetCoverage coverage) => _change(() => _coverage = coverage);

  /// The categories to choose from. A budget for a category also counts
  /// its subcategories.
  List<Category> get mainCategories => _mainCategories;

  bool isCovered(CategoryId id) => _categoryIds.contains(id);

  void toggleCategory(CategoryId id) => _change(() {
    if (!_categoryIds.remove(id)) _categoryIds.add(id);
  });

  Future<void> load() async {
    final categories = await _categories.all();
    _mainCategories = [
      for (final category in categories)
        if (category.parentId == null) category,
    ];
    notifyListeners();
  }

  bool get canSave =>
      _name.trim().isNotEmpty &&
      (_typedLimit?.isPositive ?? false) &&
      _period != null &&
      (_coverage != BudgetCoverage.categories || _categoryIds.isNotEmpty);

  Future<void> save() async {
    final limit = _typedLimit;
    final period = _period;
    if (!canSave || limit == null || period == null) {
      throw StateError('The budget is not complete yet.');
    }
    await _budgets.save(
      Budget(
        id: _existing?.id ?? BudgetId(_newId()),
        name: _name.trim(),
        limit: limit,
        period: period,
        scope: _scope,
        appearance: _existing?.appearance ?? Appearance.none,
      ),
    );
  }

  Money? get _typedLimit => Money.tryParse(_limit, currency);

  /// The period as filled in, when it makes sense.
  BudgetPeriod? get _period {
    if (!_repeats) {
      final dayAfterEnd = DateTime(_end.year, _end.month, _end.day + 1);
      return dayAfterEnd.isAfter(_start)
          ? FixedPeriod(DateRange(_start, dayAfterEnd))
          : null;
    }
    final every = int.tryParse(_every.trim());
    return every == null || every < 1
        ? null
        : RecurringPeriod(
            Recurrence(every: every, unit: _unit, anchor: _start),
          );
  }

  /// What the budget covers as filled in. What the form does not show,
  /// such as the items put in the budget being edited, stays as it was.
  BudgetScope get _scope {
    final before = _existing?.scope;
    return switch (_coverage) {
      BudgetCoverage.allSpending =>
        before is AllSpending ? before : const AllSpending(),
      BudgetCoverage.categories => CategorySpending({..._categoryIds}),
      BudgetCoverage.chosenItems =>
        before is ChosenItems ? before : const ChosenItems({}),
    };
  }

  void _takePeriodOf(Budget budget) {
    switch (budget.period) {
      case RecurringPeriod(:final recurrence):
        _every = '${recurrence.every}';
        _unit = recurrence.unit;
        _start = recurrence.anchor;
      case FixedPeriod(:final range):
        _repeats = false;
        _start = range.start;
        _end = DateTime(range.end.year, range.end.month, range.end.day - 1);
    }
  }

  void _takeScopeOf(Budget budget) {
    switch (budget.scope) {
      case AllSpending():
        _coverage = BudgetCoverage.allSpending;
      case CategorySpending(:final categoryIds):
        _coverage = BudgetCoverage.categories;
        _categoryIds.addAll(categoryIds);
      case ChosenItems():
        _coverage = BudgetCoverage.chosenItems;
    }
  }

  void _change(void Function() change) {
    change();
    notifyListeners();
  }

  static DateTime _firstDayOfMonth(DateTime moment) =>
      DateTime(moment.year, moment.month);
}
