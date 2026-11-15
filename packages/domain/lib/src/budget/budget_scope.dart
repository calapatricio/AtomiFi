import '../category/category_tree.dart';
import '../ids.dart';
import '../ledger/item.dart';

/// Which items count against a budget.
sealed class BudgetScope {
  const BudgetScope();

  bool covers(Item item, CategoryTree categories);
}

/// Everything that is spent.
final class AllSpending extends BudgetScope {
  const AllSpending();

  @override
  bool covers(Item item, CategoryTree categories) => true;
}

/// What is spent in some categories and in their subcategories.
final class CategorySpending extends BudgetScope {
  const CategorySpending(this.categoryIds);

  final Set<CategoryId> categoryIds;

  @override
  bool covers(Item item, CategoryTree categories) => categoryIds
      .any((categoryId) => categories.isWithin(item.categoryId, categoryId));
}

/// Only the items that were put in the budget one by one.
final class ChosenItems extends BudgetScope {
  const ChosenItems(this.itemIds);

  final Set<ItemId> itemIds;

  @override
  bool covers(Item item, CategoryTree categories) => itemIds.contains(item.id);
}
