import 'category.dart';

/// Where categories are kept.
abstract interface class CategoryRepository {
  /// Stores [category], replacing the one with the same id if there is one.
  Future<void> save(Category category);

  /// Every stored category, ordered by name.
  Future<List<Category>> all();
}
