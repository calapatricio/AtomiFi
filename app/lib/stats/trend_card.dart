import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/line_chart.dart';

/// How an amount built up over time: a line that goes from the first day
/// to the last, with the total it reached.
class TrendCard extends StatelessWidget {
  const TrendCard({super.key, required this.trend, required this.color});

  /// The total so far on each day, earliest first. It is not empty.
  final List<TrendPoint> trend;
  final Color color;

  static const _chartHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final days = DateFormat.MMMd(locale);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    texts.statsOverTime,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  MoneyFormatter(locale).format(trend.last.total),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(
              height: _chartHeight,
              child: LineChart(
                color: color,
                points: [
                  for (final point in trend)
                    LinePoint(
                      point.day.millisecondsSinceEpoch.toDouble(),
                      point.total.minorUnits.toDouble(),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days.format(trend.first.day),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  days.format(trend.last.day),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
