import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/choice_carousel.dart';
import 'goal_form_view_model.dart';

/// The form that adds a goal: its name and target, whether it is reached
/// by saving or by spending, and the day it should be reached by.
class GoalFormScreen extends StatefulWidget {
  const GoalFormScreen({super.key, required this.viewModel});

  final GoalFormViewModel viewModel;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  GoalFormViewModel get _form => widget.viewModel;

  Future<void> _save() async {
    await _form.save();
    if (mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _pickDeadline() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _form.deadline ?? _form.suggestedDeadline,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (day != null) _form.deadline = day;
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(texts.newGoal),
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
                  decoration: InputDecoration(labelText: texts.goalName),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (name) => _form.name = name,
                ),
                TextFormField(
                  initialValue: _form.target,
                  decoration: InputDecoration(
                    labelText: texts.goalTarget,
                    suffixText: MoneyFormatter(
                      Localizations.localeOf(context).toString(),
                    ).symbolOf(_form.currency),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (target) => _form.target = target,
                ),
                Text(
                  texts.goalKind,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ChoiceCarousel<GoalKind>(
                  choices: GoalKind.values,
                  selected: _form.kind,
                  labelOf: (kind) => switch (kind) {
                    GoalKind.saving => texts.goalKindSaving,
                    GoalKind.spending => texts.goalKindSpending,
                  },
                  onSelected: (kind) => _form.kind = kind,
                ),
                Text(
                  texts.deadline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _deadline(context, texts),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The day the goal should be reached by, which can be set, changed and
  /// taken away.
  Widget _deadline(BuildContext context, AppLocalizations texts) {
    final deadline = _form.deadline;
    final days = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickDeadline,
            icon: const Icon(Icons.event),
            label: Text(
              deadline == null ? texts.noDeadline : days.format(deadline),
            ),
          ),
        ),
        if (deadline != null)
          IconButton(
            onPressed: () => _form.deadline = null,
            tooltip: texts.removeDeadline,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
