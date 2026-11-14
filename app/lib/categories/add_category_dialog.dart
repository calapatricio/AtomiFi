import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// What the user typed to describe a new category.
typedef NewCategory = ({String name, CategorySide side, String? emoji});

/// Asks for the name and the emoji of a new category, and for its side
/// unless it is a subcategory, which takes the side of its category.
///
/// Completes with nothing when the user cancels.
Future<NewCategory?> showAddCategoryDialog(
  BuildContext context, {
  required bool isSubcategory,
}) => showDialog<NewCategory>(
  context: context,
  builder: (context) => _AddCategoryDialog(isSubcategory: isSubcategory),
);

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.isSubcategory});

  final bool isSubcategory;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _emoji = TextEditingController();
  var _side = CategorySide.expense;

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final emoji = _emoji.text.trim();
    Navigator.of(context).pop<NewCategory>((
      name: _name.text,
      side: _side,
      emoji: emoji.isEmpty ? null : emoji,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(texts.addCategory),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: texts.categoryName),
              textCapitalization: TextCapitalization.sentences,
              validator: (name) => name == null || name.trim().isEmpty
                  ? texts.categoryNameRequired
                  : null,
            ),
            TextFormField(
              controller: _emoji,
              decoration: InputDecoration(labelText: texts.emoji),
            ),
            if (!widget.isSubcategory)
              SegmentedButton<CategorySide>(
                segments: [
                  ButtonSegment(
                    value: CategorySide.expense,
                    label: Text(texts.expense),
                  ),
                  ButtonSegment(
                    value: CategorySide.income,
                    label: Text(texts.income),
                  ),
                ],
                selected: {_side},
                onSelectionChanged: (selected) =>
                    setState(() => _side = selected.single),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(texts.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(texts.save)),
      ],
    );
  }
}
