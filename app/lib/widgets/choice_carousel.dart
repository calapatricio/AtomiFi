import 'package:material_ui/material_ui.dart';

/// A row of choices to slide through sideways, of which one is selected.
///
/// The selected choice is told apart by its background alone, so choosing
/// never changes the size of anything. The row can end with a button to
/// add a choice: give it both [addLabel], which names the button, and
/// [onAdd].
class ChoiceCarousel<T> extends StatelessWidget {
  const ChoiceCarousel({
    super.key,
    required this.choices,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.avatarOf,
    this.colorOf,
    this.addLabel,
    this.onAdd,
  });

  final List<T> choices;
  final T? selected;
  final String Function(T choice) labelOf;
  final ValueChanged<T> onSelected;

  /// What to show before the label of a choice, if anything.
  final Widget Function(T choice)? avatarOf;

  /// The color that tells a choice apart, if it has one. It outlines the
  /// choice and tints it when it is selected.
  final Color? Function(T choice)? colorOf;
  final String? addLabel;
  final VoidCallback? onAdd;

  Widget _chipFor(T choice) {
    final color = colorOf?.call(choice);
    return ChoiceChip(
      avatar: avatarOf?.call(choice),
      label: Text(labelOf(choice)),
      selected: choice == selected,
      showCheckmark: false,
      side: color == null ? null : BorderSide(color: color, width: 2),
      selectedColor: color?.withValues(alpha: 0.25),
      onSelected: (_) => onSelected(choice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addLabel = this.addLabel;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          for (final choice in choices) _chipFor(choice),
          if (addLabel != null && onAdd != null)
            ActionChip(
              label: const Icon(Icons.add, size: 18),
              tooltip: addLabel,
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}
