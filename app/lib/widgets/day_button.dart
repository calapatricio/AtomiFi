import 'package:material_ui/material_ui.dart';

/// A button that shows a day under what it is the day of, and lets it be
/// changed.
class DayButton extends StatelessWidget {
  const DayButton({
    super.key,
    required this.label,
    required this.day,
    required this.onPressed,
  });

  final String label;
  final String day;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(day),
      ],
    ),
  );
}
