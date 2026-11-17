import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../money_formatter.dart';
import 'side_colors.dart';

/// A transaction that counts in the statistics: its name, the day it
/// counts on and what it counts for.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, required this.onTap});

  final StatsEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final side = entry.amount.isNegative
        ? CategorySide.expense
        : CategorySide.income;
    return ListTile(
      title: Text(entry.transaction.name),
      subtitle: Text(DateFormat.yMMMd(locale).format(entry.date)),
      trailing: Text(
        MoneyFormatter(locale).format(entry.amount),
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colorOfSide(side)),
      ),
      onTap: onTap,
    );
  }
}
