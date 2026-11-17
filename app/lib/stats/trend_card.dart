import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/line_chart.dart';

/// How an amount built up over time: a line from the first day to the
/// last. It tells the total it reached, or the total on the day that is
/// touched.
class TrendCard extends StatefulWidget {
  const TrendCard({super.key, required this.trend});

  /// The total so far on each day, earliest first. It is not empty.
  final List<TrendPoint> trend;

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  static const _chartHeight = 160.0;

  /// The position in the trend of the day that was touched, if any.
  int? _touched;

  List<TrendPoint> get _trend => widget.trend;

  @override
  void didUpdateWidget(TrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trend != _trend) _touched = null;
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final shortDays = DateFormat.MMMd(locale);
    final touched = _touched;
    final shown = touched == null ? _trend.last : _trend[touched];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(texts.statsOverTime, style: theme.textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Text(
                    touched == null
                        ? texts.statsTotal
                        : DateFormat.yMMMd(locale).format(shown.day),
                  ),
                ),
                Text(
                  MoneyFormatter(locale).format(shown.total),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(
              height: _chartHeight,
              child: LineChart(
                color: theme.colorScheme.primary,
                selected: touched,
                onSelected: (index) => setState(() => _touched = index),
                points: [
                  for (final point in _trend)
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
                  shortDays.format(_trend.first.day),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  shortDays.format(_trend.last.day),
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
