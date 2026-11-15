import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/choice_carousel.dart';
import 'budget_form_view_model.dart';

/// The form that adds a budget: its name and limit, how often it starts
/// over and what it counts.
class BudgetFormScreen extends StatefulWidget {
  const BudgetFormScreen({super.key, required this.viewModel});

  final BudgetFormViewModel viewModel;

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  BudgetFormViewModel get _form => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _form.load();
  }

  Future<void> _save() async {
    await _form.save();
    if (mounted) await Navigator.of(context).maybePop();
  }

  Future<DateTime?> _pickDay(DateTime current) => showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  Future<void> _pickStart() async {
    final day = await _pickDay(_form.start);
    if (day != null) _form.start = day;
  }

  Future<void> _pickEnd() async {
    final day = await _pickDay(_form.end);
    if (day != null) _form.end = day;
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(texts.newBudget),
          actions: [
            TextButton(
              onPressed: _form.canSave ? _save : null,
              child: Text(texts.save),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                TextFormField(
                  initialValue: _form.name,
                  decoration: InputDecoration(labelText: texts.budgetName),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (name) => _form.name = name,
                ),
                TextFormField(
                  initialValue: _form.limit,
                  decoration: InputDecoration(
                    labelText: texts.budgetLimit,
                    suffixText: MoneyFormatter(
                      Localizations.localeOf(context).toString(),
                    ).symbolOf(_form.currency),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (limit) => _form.limit = limit,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(texts.repeats),
                  value: _form.repeats,
                  onChanged: (repeats) => _form.repeats = repeats,
                ),
                if (_form.repeats) _rhythm(texts),
                _days(context, texts),
                Text(
                  texts.covers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _coverage(texts),
                if (_form.coverage == BudgetCoverage.categories)
                  _categories(),
                if (_form.coverage == BudgetCoverage.chosenItems)
                  Text(texts.coversChosenItemsHint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// How often the budget starts over: every so many days, weeks and so on.
  Widget _rhythm(AppLocalizations texts) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      SizedBox(
        width: 96,
        child: TextFormField(
          initialValue: _form.every,
          decoration: InputDecoration(labelText: texts.every),
          keyboardType: TextInputType.number,
          onChanged: (every) => _form.every = every,
        ),
      ),
      Expanded(
        child: DropdownMenu<RecurrenceUnit>(
          expandedInsets: EdgeInsets.zero,
          initialSelection: _form.unit,
          dropdownMenuEntries: [
            for (final unit in RecurrenceUnit.values)
              DropdownMenuEntry(value: unit, label: _nameOf(unit, texts)),
          ],
          onSelected: (unit) {
            if (unit != null) _form.unit = unit;
          },
        ),
      ),
    ],
  );

  /// The day a period starts and, when the budget does not repeat, the day
  /// it ends.
  Widget _days(BuildContext context, AppLocalizations texts) {
    final days = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: _DayButton(
            label: _form.repeats ? texts.startingOn : texts.from,
            day: days.format(_form.start),
            onPressed: _pickStart,
          ),
        ),
        if (!_form.repeats)
          Expanded(
            child: _DayButton(
              label: texts.until,
              day: days.format(_form.end),
              onPressed: _pickEnd,
            ),
          ),
      ],
    );
  }

  Widget _coverage(AppLocalizations texts) => ChoiceCarousel<BudgetCoverage>(
    choices: BudgetCoverage.values,
    selected: _form.coverage,
    labelOf: (coverage) => switch (coverage) {
      BudgetCoverage.allSpending => texts.coversAllSpending,
      BudgetCoverage.categories => texts.coversCategories,
      BudgetCoverage.chosenItems => texts.coversChosenItems,
    },
    onSelected: (coverage) => _form.coverage = coverage,
  );

  Widget _categories() => Wrap(
    spacing: 8,
    children: [
      for (final category in _form.mainCategories)
        FilterChip(
          label: Text(category.name),
          selected: _form.isCovered(category.id),
          onSelected: (_) => _form.toggleCategory(category.id),
        ),
    ],
  );

  static String _nameOf(RecurrenceUnit unit, AppLocalizations texts) =>
      switch (unit) {
        RecurrenceUnit.day => texts.unitDays,
        RecurrenceUnit.week => texts.unitWeeks,
        RecurrenceUnit.month => texts.unitMonths,
        RecurrenceUnit.year => texts.unitYears,
      };
}

/// A button that shows a day under what it is the day of, and lets it be
/// changed.
class _DayButton extends StatelessWidget {
  const _DayButton({
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
