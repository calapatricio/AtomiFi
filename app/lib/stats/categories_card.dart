import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/appearance_avatar.dart';
import '../widgets/donut_chart.dart';

/// How an amount is spread over categories: a ring with a part per
/// category and, under it, each category with its amount. Tapping a
/// category that has subcategories looks into it.
class CategoriesCard extends StatelessWidget {
  const CategoriesCard({
    super.key,
    required this.amounts,
    required this.total,
    required this.openCategory,
    required this.onOpen,
    required this.onClose,
  });

  /// The categories to show, the largest first.
  final List<CategoryAmount> amounts;

  /// What [amounts] add up to.
  final Money total;

  /// The category whose parts are shown, if one is being looked into.
  final CategoryAmount? openCategory;
  final ValueChanged<CategoryAmount> onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    final openCategory = this.openCategory;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
                if (openCategory != null)
                  IconButton(
                    onPressed: onClose,
                    tooltip: texts.allCategories,
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    openCategory?.category.name ?? texts.statsByCategory,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
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
                    onSegmentTap: (index) => onOpen(amounts[index]),
                    child: Text(
                      money.format(total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              for (final (index, amount) in amounts.indexed)
                _AmountRow(
                  amount: amount,
                  color: _colorOf(amount, index),
                  onTap: amount.parts.isEmpty ? null : () => onOpen(amount),
                ),
            ],
          ],
        ),
      ),
    );
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
    required this.onTap,
  });

  final CategoryAmount amount;

  /// The color of its part of the ring.
  final Color color;

  /// Looks into the category. Nothing when there is nothing to look into.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final category = amount.category;
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
          AppearanceAvatar(appearance: category.appearance, name: category.name),
        ],
      ),
      title: Text(category.name),
      subtitle: Text(NumberFormat.percentPattern(locale).format(amount.fraction)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            MoneyFormatter(locale).format(amount.amount),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
