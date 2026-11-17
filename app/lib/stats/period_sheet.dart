import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../widgets/choice_carousel.dart';
import '../widgets/day_button.dart';
import '../widgets/rhythm_fields.dart';
import 'period_form_view_model.dart';

/// Lets the user choose the period of the statistics in a sheet that comes
/// up from the bottom. Completes with the period, or with nothing when the
/// sheet is dismissed.
Future<StatsPeriod?> showPeriodSheet(
  BuildContext context, {
  required PeriodFormViewModel form,
}) => showModalBottomSheet<StatsPeriod>(
  context: context,
  isScrollControlled: true,
  builder: (_) => PeriodSheet(form: form),
).whenComplete(form.dispose);

/// The form to choose a period: one that repeats, the last days, the time
/// between two dates, or everything.
class PeriodSheet extends StatelessWidget {
  const PeriodSheet({super.key, required this.form});

  final PeriodFormViewModel form;

  Future<void> _pick(
    BuildContext context,
    DateTime current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (day != null) onPicked(day);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListenableBuilder(
          listenable: form,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                texts.statsPeriod,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ChoiceCarousel<PeriodKind>(
                choices: PeriodKind.values,
                selected: form.kind,
                labelOf: (kind) => switch (kind) {
                  PeriodKind.repeating => texts.periodRepeating,
                  PeriodKind.lastDays => texts.periodLastDays,
                  PeriodKind.betweenDates => texts.periodBetweenDates,
                  PeriodKind.allTime => texts.periodAllTime,
                },
                onSelected: (kind) => form.kind = kind,
              ),
              ..._fields(context, texts),
              FilledButton(
                onPressed: form.canApply
                    ? () => Navigator.of(context).pop(form.period)
                    : null,
                child: Text(texts.apply),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What is asked for the kind of period that is chosen.
  List<Widget> _fields(BuildContext context, AppLocalizations texts) {
    final days = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return switch (form.kind) {
      PeriodKind.repeating => [
        RhythmFields(
          every: form.every,
          unit: form.unit,
          onEveryChanged: (every) => form.every = every,
          onUnitChanged: (unit) => form.unit = unit,
        ),
        DayButton(
          label: texts.startingOn,
          day: days.format(form.start),
          onPressed: () =>
              _pick(context, form.start, (day) => form.start = day),
        ),
      ],
      PeriodKind.lastDays => [
        TextFormField(
          initialValue: form.days,
          decoration: InputDecoration(labelText: texts.daysCount),
          keyboardType: TextInputType.number,
          onChanged: (days) => form.days = days,
        ),
      ],
      PeriodKind.betweenDates => [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: DayButton(
                label: texts.from,
                day: days.format(form.firstDay),
                onPressed: () => _pick(
                  context,
                  form.firstDay,
                  (day) => form.firstDay = day,
                ),
              ),
            ),
            Expanded(
              child: DayButton(
                label: texts.until,
                day: days.format(form.lastDay),
                onPressed: () =>
                    _pick(context, form.lastDay, (day) => form.lastDay = day),
              ),
            ),
          ],
        ),
      ],
      PeriodKind.allTime => [Text(texts.periodAllTimeHint)],
    };
  }
}
