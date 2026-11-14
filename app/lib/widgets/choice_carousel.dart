import 'package:material_ui/material_ui.dart';

/// A row of choices to slide through sideways, of which one is selected.
///
/// It can end with a way to add a choice: give it both [addLabel] and
/// [onAdd].
class ChoiceCarousel<T> extends StatelessWidget {
  const ChoiceCarousel({
    super.key,
    required this.choices,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.avatarOf,
    this.addLabel,
    this.onAdd,
  });

  final List<T> choices;
  final T? selected;
  final String Function(T choice) labelOf;
  final ValueChanged<T> onSelected;

  /// What to show before the label of a choice, if anything.
  final Widget Function(T choice)? avatarOf;
  final String? addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final addLabel = this.addLabel;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          for (final choice in choices)
            ChoiceChip(
              avatar: avatarOf?.call(choice),
              label: Text(labelOf(choice)),
              selected: choice == selected,
              onSelected: (_) => onSelected(choice),
            ),
          if (addLabel != null && onAdd != null)
            ActionChip(
              avatar: const Icon(Icons.add),
              label: Text(addLabel),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}
