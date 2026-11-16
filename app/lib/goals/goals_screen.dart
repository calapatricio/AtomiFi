import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/appearance_avatar.dart';
import 'goals_view_model.dart';

/// Lists the goals with how far each has come and what is left to reach it.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({
    super.key,
    required this.viewModel,
    required this.openForm,
  });

  final GoalsViewModel viewModel;

  /// Opens the form for a new goal, or to edit [existing], and completes
  /// when the user leaves it.
  final Future<void> Function(BuildContext context, {Goal? existing}) openForm;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  GoalsViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _add() => _open();

  Future<void> _open({Goal? existing}) async {
    await widget.openForm(context, existing: existing);
    await _viewModel.load();
  }

  Future<void> _remove(Goal goal) async {
    final texts = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(texts.deleteGoalTitle(goal.name)),
        content: Text(texts.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(texts.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(texts.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await _viewModel.remove(goal);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.goalsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: texts.addGoal,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _viewModel.progress.isEmpty
            ? Center(child: Text(texts.noGoals))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final progress in _viewModel.progress)
                    _GoalCard(
                      progress: progress,
                      onEdit: () => _open(existing: progress.goal),
                      onRemove: () => _remove(progress.goal),
                    ),
                ],
              ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.progress,
    required this.onEdit,
    required this.onRemove,
  });

  final GoalProgress progress;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final money = MoneyFormatter(locale);
    final goal = progress.goal;
    final deadline = goal.deadline;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                spacing: 12,
                children: [
                  AppearanceAvatar(
                    appearance: goal.appearance,
                    name: goal.name,
                  ),
                  Expanded(
                    child: Text(goal.name, style: theme.textTheme.titleMedium),
                  ),
                  PopupMenuButton<VoidCallback>(
                    onSelected: (run) => run(),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: onRemove, child: Text(texts.delete)),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: LinearProgressIndicator(
                  value: (progress.reached.minorUnits / goal.target.minorUnits)
                      .clamp(0, 1),
                ),
              ),
              Text(
                texts.goalReachedOfTarget(
                  money.format(progress.reached),
                  money.format(goal.target),
                ),
              ),
              Text(
                progress.isReached
                    ? texts.goalReached
                    : texts.goalToGo(money.format(progress.remaining)),
              ),
              if (deadline != null)
                Text(
                  texts.goalBy(DateFormat.yMMMd(locale).format(deadline)),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
