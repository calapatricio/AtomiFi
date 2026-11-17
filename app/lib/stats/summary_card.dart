import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import 'side_colors.dart';

/// The figures of a period at a glance: what came in, what went out and
/// what is left.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final PeriodStats summary;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: texts.statsIncome,
                    amount: money.format(summary.income),
                    icon: Icons.arrow_upward,
                    color: colorOfSide(CategorySide.income),
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: texts.statsExpenses,
                    amount: money.format(summary.expenses),
                    icon: Icons.arrow_downward,
                    color: colorOfSide(CategorySide.expense),
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: texts.statsBalance,
                    amount: money.format(summary.balance),
                  ),
                ),
              ],
            ),
            if (!summary.corrections.isZero)
              Text(
                texts.statsCorrections(money.format(summary.corrections)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// One amount under what it is, with an optional icon in its color.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amount,
    this.icon,
    this.color,
  });

  final String label;
  final String amount;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            if (icon != null) Icon(icon, size: 16, color: color),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
