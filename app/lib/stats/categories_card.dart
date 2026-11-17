import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/appearance_avatar.dart';
import '../widgets/donut_chart.dart';

/// How an amount is spread over categories: a ring with a part per
/// category and, under it, each category with its amount. The selected
/// category unfolds its subcategories under itself.
class CategoriesCard extends StatelessWidget {
  const CategoriesCard({
    super.key,
    required this.amounts,
    required this.total,
    required this.selected,
    required this.onSelect,
  });

  /// The categories to show, the largest first.
  final List<CategoryAmount> amounts;

  /// What [amounts] add up to.
  final Money total;

  /// The category that is selected, if any.
  final CategoryAmount? selected;

  /// Called with the category that is tapped, in the ring or under it.
  final ValueChanged<CategoryAmount> onSelect;

  static const _indentOfParts = 24.0;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(texts.statsByCategory, style: theme.textTheme.titleMedium),
            if (amounts.isEmpty)
              Text(texts.statsNothing)
            else ...[
              Center(
                child: SizedBox.square(
                  dimension: 200,
                  child: DonutChart(
                    segments: [
                      for (final (index, amount) in amounts.indexed)
                        DonutSegment(
                          fraction: amount.fraction,
                          color: _colorOf(amount, index),
                        ),
                    ],
                    onSegmentTap: (index) => onSelect(amounts[index]),
                    child: Text(
                      money.format(total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              for (final (index, amount) in amounts.indexed)
                ..._rowsOf(amount, _colorOf(amount, index)),
            ],
          ],
        ),
      ),
    );
  }

  /// The row of a category and, when it is the selected one, the rows of
  /// its subcategories under it.
  List<Widget> _rowsOf(CategoryAmount amount, Color color) {
    final isSelected = amount.category.id == selected?.category.id;
    return [
      _AmountRow(
        amount: amount,
        color: color,
        isSelected: isSelected,
        onTap: () => onSelect(amount),
      ),
      if (isSelected)
        for (final part in amount.parts)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _indentOfParts),
            child: _AmountRow(amount: part, color: color),
          ),
    ];
  }

  /// The color of a category, or one of a fixed set when it has none.
  static Color _colorOf(CategoryAmount amount, int index) {
    final color = amount.category.appearance.color;
    return color == null
        ? Colors.primaries[index % Colors.primaries.length]
        : Color(color);
  }
}

/// A category with the part it is of the whole and its amount.
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.amount,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  final CategoryAmount amount;

  /// The color of its part of the ring.
  final Color color;
  final bool isSelected;

  /// Selects the category. Nothing when it cannot be selected.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final category = amount.category;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: isSelected,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          AppearanceAvatar(
            appearance: category.appearance,
            name: category.name,
          ),
        ],
      ),
      title: Text(category.name),
      subtitle: Text(
        NumberFormat.percentPattern(locale).format(amount.fraction),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            MoneyFormatter(locale).format(amount.amount),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (amount.parts.isNotEmpty)
            Icon(isSelected ? Icons.expand_less : Icons.expand_more),
        ],
      ),
      onTap: onTap,
    );
  }
}
