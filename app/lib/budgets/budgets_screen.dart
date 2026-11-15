import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import 'budgets_view_model.dart';

/// Lists the budgets with how much of each is spent and how much is left.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({
    super.key,
    required this.viewModel,
    required this.openForm,
  });

  final BudgetsViewModel viewModel;

  /// Opens the form for a new budget and completes when the user leaves it.
  final Future<void> Function(BuildContext context) openForm;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  BudgetsViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _add() async {
    await widget.openForm(context);
    await _viewModel.load();
  }

  Future<void> _remove(Budget budget) async {
    final texts = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(texts.deleteBudgetTitle(budget.name)),
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
    if (confirmed == true) await _viewModel.remove(budget);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.budgetsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: texts.addBudget,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _viewModel.progress.isEmpty
            ? Center(child: Text(texts.noBudgets))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final progress in _viewModel.progress)
                    _BudgetCard(
                      progress: progress,
                      onRemove: () => _remove(progress.budget),
                    ),
                ],
              ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress, required this.onRemove});

  final BudgetProgress progress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    final limit = progress.budget.limit;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.budget.name,
                    style: theme.textTheme.titleMedium,
                  ),
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
                value: (progress.spent.minorUnits / limit.minorUnits).clamp(
                  0,
                  1,
                ),
                color: progress.isOverspent ? theme.colorScheme.error : null,
              ),
            ),
            Text(
              texts.budgetSpentOfLimit(
                money.format(progress.spent),
                money.format(limit),
              ),
            ),
            Text(
              progress.isOverspent
                  ? texts.budgetOver(money.format(progress.remaining.abs()))
                  : texts.budgetLeft(money.format(progress.remaining)),
              style: progress.isOverspent
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            Text(_spanOf(context, texts), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// The first and the last day of the period, such as `Nov 1 – Nov 30`.
  String _spanOf(BuildContext context, AppLocalizations texts) {
    final days = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final end = progress.range.end;
    final lastDay = DateTime(end.year, end.month, end.day - 1);
    return texts.dateSpan(
      days.format(progress.range.start),
      days.format(lastDay),
    );
  }
}
