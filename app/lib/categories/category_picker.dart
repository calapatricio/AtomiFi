import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../widgets/appearance_avatar.dart';
import 'add_category_dialog.dart';
import 'category_choices.dart';

/// Lets the user choose a category from a sheet at the bottom of the
/// screen, and then one of its subcategories when it has any.
///
/// Completes with the id of the subcategory, or of the category when it has
/// no subcategories or none of them is wanted, or with nothing when the
/// user chooses no category at all.
Future<CategoryId?> pickCategory(
  BuildContext context,
  CategoryChoices choices,
) async {
  final category = await _pickFrom(
    context,
    choices,
    options: choices.mainCategories,
  );
  if (category == null) return null;
  final subcategories = choices.subcategoriesOf(category.id);
  if (subcategories.isEmpty || !context.mounted) return category.id;
  final subcategory = await _pickFrom(
    context,
    choices,
    options: subcategories,
    parent: category,
  );
  return (subcategory ?? category).id;
}

/// Shows [options] and gives the one that is chosen or added. Gives nothing
/// when the sheet is dismissed or, among subcategories, none is wanted.
Future<Category?> _pickFrom(
  BuildContext context,
  CategoryChoices choices, {
  required List<Category> options,
  Category? parent,
}) async {
  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CategoryGrid(options: options, parent: parent),
  );
  return switch (choice) {
    _Chosen(:final category) => category,
    _AddNew() when context.mounted => _add(context, choices, parent),
    _ => null,
  };
}

Future<Category?> _add(
  BuildContext context,
  CategoryChoices choices,
  Category? parent,
) async {
  final typed = await showAddCategoryDialog(
    context,
    isSubcategory: parent != null,
  );
  if (typed == null) return null;
  return choices.addCategory(
    name: typed.name,
    side: typed.side,
    emoji: typed.emoji,
    parentId: parent?.id,
  );
}

/// What the user did in the sheet.
sealed class _Choice {
  const _Choice();
}

final class _Chosen extends _Choice {
  const _Chosen(this.category);

  final Category category;
}

final class _NoSubcategory extends _Choice {
  const _NoSubcategory();
}

final class _AddNew extends _Choice {
  const _AddNew();
}

/// The categories to choose from, four to a row, ending with the way to
/// add one. Among subcategories, it starts with the way to want none.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.options, required this.parent});

  static const _columns = 4;

  final List<Category> options;

  /// The category whose subcategories these are, if they are subcategories.
  final Category? parent;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    void choose(_Choice choice) => Navigator.of(context).pop(choice);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parent?.name ?? texts.chooseCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Flexible(
              child: GridView.count(
                crossAxisCount: _columns,
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                childAspectRatio: 0.85,
                children: [
                  if (parent != null)
                    _Cell(
                      avatar: const CircleAvatar(child: Icon(Icons.block)),
                      label: texts.none,
                      onTap: () => choose(const _NoSubcategory()),
                    ),
                  for (final category in options)
                    _Cell(
                      avatar: AppearanceAvatar(
                        appearance: category.appearance,
                        name: category.name,
                      ),
                      label: category.name,
                      onTap: () => choose(_Chosen(category)),
                    ),
                  _Cell(
                    avatar: const CircleAvatar(child: Icon(Icons.add)),
                    label: texts.addCategory,
                    onTap: () => choose(const _AddNew()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.avatar, required this.label, required this.onTap});

  final Widget avatar;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        avatar,
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}
