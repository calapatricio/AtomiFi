import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../widgets/choice_carousel.dart';
import 'categories_card.dart';
import 'period_bar.dart';
import 'period_sheet.dart';
import 'side_colors.dart';
import 'stats_view_model.dart';
import 'summary_card.dart';
import 'trend_card.dart';

/// Shows what I spent and earned over a period: the totals, how they are
/// spread over the categories and how they built up day by day.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.viewModel});

  final StatsViewModel viewModel;

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

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.statsTitle)),
      body: ListenableBuilder(
        listenable: _stats,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
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
                openCategory: _stats.openCategory,
                onOpen: _stats.open,
                onClose: _stats.close,
              ),
              if (_stats.trend.isNotEmpty)
                TrendCard(trend: _stats.trend, color: colorOfSide(_stats.side)),
            ],
          ),
        ),
      ),
    );
  }
}
