import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Says which period the statistics show and lets the user choose another,
/// or go to the one before or after when there is one.
class PeriodBar extends StatelessWidget {
  const PeriodBar({
    super.key,
    required this.period,
    required this.range,
    required this.onChoose,
    this.onPrevious,
    this.onNext,
  });

  final StatsPeriod period;

  /// The dates that [period] covers now.
  final DateRange range;
  final VoidCallback onChoose;

  /// Goes to the period before. Nothing when there is none.
  final VoidCallback? onPrevious;

  /// Goes to the period after. Nothing when there is none.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Row(
      children: [
        if (onPrevious != null)
          IconButton(
            onPressed: onPrevious,
            tooltip: texts.previousPeriod,
            icon: const Icon(Icons.chevron_left),
          ),
        Expanded(
          child: TextButton.icon(
            onPressed: onChoose,
            icon: const Icon(Icons.calendar_month),
            label: Text(_describe(context, texts)),
          ),
        ),
        if (onNext != null)
          IconButton(
            onPressed: onNext,
            tooltip: texts.nextPeriod,
            icon: const Icon(Icons.chevron_right),
          ),
      ],
    );
  }

  String _describe(BuildContext context, AppLocalizations texts) =>
      switch (period) {
        AllTime() => texts.periodAllTime,
        LastDays(:final days) => texts.lastDays(days),
        BetweenDates() || RepeatingPeriod() => _spanOf(context, texts),
      };

  /// The first and the last day of [range], such as
  /// `Nov 1, 2026 – Nov 30, 2026`.
  String _spanOf(BuildContext context, AppLocalizations texts) {
    final days = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final end = range.end;
    final lastDay = DateTime(end.year, end.month, end.day - 1);
    return texts.dateSpan(days.format(range.start), days.format(lastDay));
  }
}
