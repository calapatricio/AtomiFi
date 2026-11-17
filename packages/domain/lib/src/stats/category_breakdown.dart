import '../category/category.dart';
import '../money/money.dart';
import 'period_stats.dart';

/// What one category amounts to among others.
final class CategoryAmount {
  const CategoryAmount({
    required this.category,
    required this.amount,
    required this.fraction,
    this.parts = const [],
  });

  final Category category;

  /// What was spent in the category, or earned in it, as a positive amount.
  final Money amount;

  /// The part this amount is of the amounts it is listed with, from 0 to 1.
  final double fraction;

  /// The subcategories, and the category itself, that make up the amount.
  /// Empty when nothing is in its subcategories.
  final List<CategoryAmount> parts;
}

/// Tells how the spending or the income of a period is spread over the
/// categories.
final class CategoryBreakdown {
  CategoryBreakdown(Iterable<Category> categories)
      : _categories = List.unmodifiable(categories);

  final List<Category> _categories;

  /// The main categories of [side] with something in them, the largest
  /// first. Each counts its subcategories.
  List<CategoryAmount> of(PeriodStats stats, CategorySide side) {
    final amountOf = _AmountReader(stats, side);
    return _ranked([
      for (final category in _categories)
        if (category.side == side && category.parentId == null)
          _Candidate(
            category,
            _within(category).fold(
              Money.zero(stats.currency),
              (sum, member) => sum + amountOf(member),
            ),
            parts: _partsOf(category, amountOf),
          ),
    ]);
  }

  /// The subcategories of [category] and the category itself, when there
  /// is something in a subcategory.
  List<CategoryAmount> _partsOf(Category category, _AmountReader amountOf) {
    final hasSomethingInSubcategories = _subcategoriesOf(category)
        .any((subcategory) => amountOf(subcategory).isPositive);
    if (!hasSomethingInSubcategories) return const [];
    return _ranked([
      for (final member in _within(category))
        _Candidate(member, amountOf(member)),
    ]);
  }

  Iterable<Category> _within(Category category) =>
      [category, ..._subcategoriesOf(category)];

  Iterable<Category> _subcategoriesOf(Category category) =>
      _categories.where((candidate) => candidate.parentId == category.id);

  /// The [candidates] with something in them, the largest first, each with
  /// the part it is of them all.
  static List<CategoryAmount> _ranked(List<_Candidate> candidates) {
    final kept = [
      for (final candidate in candidates)
        if (candidate.amount.isPositive) candidate,
    ]..sort(_largestFirst);
    final total =
        kept.fold(0, (sum, candidate) => sum + candidate.amount.minorUnits);
    return [
      for (final candidate in kept)
        CategoryAmount(
          category: candidate.category,
          amount: candidate.amount,
          fraction: candidate.amount.minorUnits / total,
          parts: candidate.parts,
        ),
    ];
  }

  static int _largestFirst(_Candidate one, _Candidate other) {
    final byAmount = other.amount.minorUnits.compareTo(one.amount.minorUnits);
    return byAmount != 0
        ? byAmount
        : one.category.name.compareTo(other.category.name);
  }
}

/// A category with its amount, before knowing which part of the whole it is.
final class _Candidate {
  const _Candidate(this.category, this.amount, {this.parts = const []});

  final Category category;
  final Money amount;
  final List<CategoryAmount> parts;
}

/// Reads from the stats what is in a category itself, positive when it is
/// what its side expects: money spent for expenses, money earned for income.
final class _AmountReader {
  const _AmountReader(this._stats, this._side);

  final PeriodStats _stats;
  final CategorySide _side;

  Money call(Category category) {
    final net = _stats.netFor(category.id);
    return _side == CategorySide.expense ? -net : net;
  }
}
