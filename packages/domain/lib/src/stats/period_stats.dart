import '../category/category.dart';
import '../ids.dart';
import '../money/currency.dart';
import '../money/money.dart';

/// The user's own spending and income over a period.
final class PeriodStats {
  PeriodStats({
    required this.currency,
    required Map<CategoryId, Money> netByCategory,
    required Map<CategoryId, CategorySide> sideOfCategory,
  })  : _netByCategory = Map.unmodifiable(netByCategory),
        _sideOfCategory = Map.unmodifiable(sideOfCategory);

  final Currency currency;
  final Map<CategoryId, Money> _netByCategory;
  final Map<CategoryId, CategorySide> _sideOfCategory;

  /// Net spending in expense categories, as a positive amount.
  Money get expenses => -_netOn(CategorySide.expense);

  /// Net earnings in income categories.
  Money get income => _netOn(CategorySide.income);

  /// The signed net amount of one category; negative means money spent.
  Money netFor(CategoryId categoryId) =>
      _netByCategory[categoryId] ?? Money.zero(currency);

  Money _netOn(CategorySide side) => _netByCategory.entries
      .where((entry) => _sideOfCategory[entry.key] == side)
      .fold(Money.zero(currency), (sum, entry) => sum + entry.value);
}
