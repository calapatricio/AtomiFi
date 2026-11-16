import '../appearance.dart';
import '../ids.dart';

/// The side of the statistics a category is reported on.
enum CategorySide {
  expense,
  income,

  /// On neither side. What is in the category changes the balance of its
  /// account, but is not spending, income or part of any budget: a balance
  /// correction, for instance.
  neutral,
}

final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.side,
    this.parentId,
    this.appearance = Appearance.none,
  });

  final CategoryId id;
  final String name;
  final CategorySide side;
  final Appearance appearance;

  /// The main category this one is a subcategory of, if any.
  final CategoryId? parentId;
}
