import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// The fields that say how often something starts over: every so many
/// days, weeks, months or years.
class RhythmFields extends StatelessWidget {
  const RhythmFields({
    super.key,
    required this.every,
    required this.unit,
    required this.onEveryChanged,
    required this.onUnitChanged,
  });

  /// How many units, as typed.
  final String every;
  final RecurrenceUnit unit;
  final ValueChanged<String> onEveryChanged;
  final ValueChanged<RecurrenceUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SizedBox(
          width: 96,
          child: TextFormField(
            initialValue: every,
            decoration: InputDecoration(labelText: texts.every),
            keyboardType: TextInputType.number,
            onChanged: onEveryChanged,
          ),
        ),
        Expanded(
          child: DropdownMenu<RecurrenceUnit>(
            expandedInsets: EdgeInsets.zero,
            initialSelection: unit,
            dropdownMenuEntries: [
              for (final unit in RecurrenceUnit.values)
                DropdownMenuEntry(value: unit, label: _nameOf(unit, texts)),
            ],
            onSelected: (unit) {
              if (unit != null) onUnitChanged(unit);
            },
          ),
        ),
      ],
    );
  }

  static String _nameOf(RecurrenceUnit unit, AppLocalizations texts) =>
      switch (unit) {
        RecurrenceUnit.day => texts.unitDays,
        RecurrenceUnit.week => texts.unitWeeks,
        RecurrenceUnit.month => texts.unitMonths,
        RecurrenceUnit.year => texts.unitYears,
      };
}
