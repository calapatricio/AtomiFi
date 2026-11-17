import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../widgets/choice_carousel.dart';
import 'categories_card.dart';
import 'entry_tile.dart';
import 'period_bar.dart';
import 'period_sheet.dart';
import 'side_colors.dart';
import 'stats_view_model.dart';
import 'summary_card.dart';
import 'trend_card.dart';

/// Shows what I spent and earned over a period: the totals, how they are
/// spread over the categories, how they built up day by day and the
/// transactions behind them.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.viewModel,
    required this.openTransaction,
  });

  final StatsViewModel viewModel;

  /// Opens a transaction to look at it or change it, and completes when
  /// the user comes back.
  final Future<void> Function(BuildContext context, Transaction transaction)
  openTransaction;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsViewModel get _stats => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _stats.load();
  }

  Future<void> _choosePeriod() async {
    final period = await showPeriodSheet(context, form: _stats.periodForm());
    if (period != null) _stats.period = period;
  }

  Future<void> _open(Transaction transaction) async {
    await widget.openTransaction(context, transaction);
    await _stats.load();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.statsTitle)),
      body: ListenableBuilder(
        listenable: _stats,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(child: _figures(texts)),
            ),
            SliverList.builder(
              itemCount: _stats.entries.length,
              itemBuilder: (context, index) {
                final entry = _stats.entries[index];
                return EntryTile(
                  entry: entry,
                  onTap: () => _open(entry.transaction),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Everything above the list of transactions.
  Widget _figures(AppLocalizations texts) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      PeriodBar(
        period: _stats.period,
        range: _stats.range,
        onChoose: _choosePeriod,
        onPrevious: _stats.canStep ? _stats.showPrevious : null,
        onNext: _stats.canStep ? _stats.showNext : null,
      ),
      SummaryCard(summary: _stats.summary),
      ChoiceCarousel<CategorySide>(
        choices: const [CategorySide.expense, CategorySide.income],
        selected: _stats.side,
        labelOf: (side) => side == CategorySide.income
            ? texts.statsIncome
            : texts.statsExpenses,
        colorOf: colorOfSide,
        onSelected: (side) => _stats.side = side,
      ),
      CategoriesCard(
        amounts: _stats.amounts,
        total: _stats.total,
        selected: _stats.selected,
        onSelect: _stats.select,
      ),
      if (_stats.trend.isNotEmpty) TrendCard(trend: _stats.trend),
      if (_stats.entries.isNotEmpty)
        Text(
          texts.transactionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
    ],
  );
}
