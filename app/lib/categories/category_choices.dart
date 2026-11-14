import 'package:atomifi_domain/atomifi_domain.dart';

/// The categories a person can choose from, and the way to add one.
abstract interface class CategoryChoices {
  /// The categories that belong to no other, ordered by name.
  List<Category> get mainCategories;

  /// The subcategories of the category with this id, ordered by name.
  List<Category> subcategoriesOf(CategoryId id);

  /// Adds a category, under the one with [parentId] when it is given. A
  /// subcategory takes the side of its category, whatever [side] says.
  Future<Category> addCategory({
    required String name,
    required CategorySide side,
    String? emoji,
    CategoryId? parentId,
  });
}
