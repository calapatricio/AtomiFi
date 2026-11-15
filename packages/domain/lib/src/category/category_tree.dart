import '../ids.dart';
import 'category.dart';

/// Knows which category each subcategory belongs to.
final class CategoryTree {
  CategoryTree(Iterable<Category> categories)
      : _parentById = {
          for (final category in categories) category.id: category.parentId,
        };

  final Map<CategoryId, CategoryId?> _parentById;

  /// Whether the category with [id] is [ancestorId] or one of its
  /// subcategories.
  bool isWithin(CategoryId id, CategoryId ancestorId) =>
      id == ancestorId || _parentById[id] == ancestorId;
}
