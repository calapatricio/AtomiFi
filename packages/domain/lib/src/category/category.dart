import '../ids.dart';

/// The side of the statistics a category is reported on.
enum CategorySide { expense, income }

final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.side,
    this.parentId,
  });

  final CategoryId id;
  final String name;
  final CategorySide side;

  /// The main category this one is a subcategory of, if any.
  final CategoryId? parentId;
}
